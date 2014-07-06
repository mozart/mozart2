// Copyright © 2011, Université catholique de Louvain
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// *  Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// *  Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#ifndef MOZART_BOOSTENV_H
#define MOZART_BOOSTENV_H

#include <csignal>
#include <exception>
#include <fstream>

#include "boostenv-decl.hh"

#include "boostvm.hh"
#include "boostenvutils.hh"
#include "boostenvtcp.hh"
#include "boostenvpipe.hh"
#include "boostenvbigint.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

//////////////////////
// BoostEnvironment //
//////////////////////

namespace internal {
  /* TODO It might be worth, someday, to investigate how we can lift this
   * decoding to the Oz level.
   * It should somewhere in Resolve.oz and/or URL.oz.
   * But at the same time, not forgetting that this function implements
   * bootURLLoad (not a hypothetical bootFileLoad)!
   *
   * In fact it is already a duplicate of the logic in OS.oz.
   */

  inline
  char hexDigitToValue(char digit) {
    // Don't care to give meaningful results if the digit is not valid
    if (digit <= '9')
      return digit - '0';
    else if (digit <= 'Z')
      return digit - ('A'-10);
    else
      return digit - ('a'-10);
  }

  inline
  std::string decodeURL(const std::string& encoded) {
    // Fast path when there is nothing to do
    if (encoded.find('%') == std::string::npos)
      return encoded;

    // Relevant reminder: Unicode URLs are UTF-8 encoded then %-escaped

    std::string decoded;
    decoded.reserve(encoded.size());

    for (size_t i = 0; i < encoded.size(); ++i) {
      char c = encoded[i];
      if (c == '%' && (i+2 < encoded.size())) {
        char v1 = hexDigitToValue(encoded[++i]);
        char v2 = hexDigitToValue(encoded[++i]);
        decoded.push_back((v1 << 4) | v2);
      } else {
        decoded.push_back(c);
      }
    }

    return decoded;
  }

  inline
  std::string decodedURLToFilename(const std::string& url) {
    // Not sure this is the right test (why not // ?), but it was so in Mozart 1
    if (url.substr(0, 5) == "file:")
      return url.substr(5);
    else
      return url;
  }

  inline
  bool defaultBootLoader(VM vm, const std::string& url, UnstableNode& result) {
    std::string filename = decodedURLToFilename(decodeURL(url));
    std::ifstream input(filename, std::ios::binary);
    if (!input.is_open())
      return false;
    result = unpickle(vm, input);
    return true;
  }
}

BoostEnvironment::BoostEnvironment(const VMStarter& vmStarter) :
  _nextVMIdentifier(InitialVMIdentifier), _exitCode(0),
  vmStarter(vmStarter) {
  // Set up a default boot loader
  setBootLoader(&internal::defaultBootLoader);

  // Ignore SIGPIPE ourselves since Boost does not always do it
#ifdef SIGPIPE
  std::signal(SIGPIPE, SIG_IGN);
#endif
}

VMIdentifier BoostEnvironment::addVM(VMIdentifier parent,
                                     std::unique_ptr<std::string>&& app, bool isURL,
                                     VirtualMachineOptions options) {
  boost::lock_guard<boost::mutex> lock(_vmsMutex);
  _vms.emplace_front(*this, parent, _nextVMIdentifier++, options, std::move(app), isURL);
  return _vms.front().identifier;
}

VMIdentifier BoostEnvironment::checkValidIdentifier(VM vm, RichNode vmIdentifier) {
  VMIdentifier identifier = getArgument<VMIdentifier>(vm, vmIdentifier);
  if (identifier > 0 && identifier < _nextVMIdentifier) {
    return identifier;
  } else {
    raiseError(vm, buildTuple(vm, "vm", "invalidVMIdent"));
  }
}

/* Calls onSuccess if a VM with the given identifier is found.
   The _vmsMutex is hold during the call, so it is safe to assume that
   the BoostVM will not be terminated during the call.
   Returns whether it found the VM represented by identifier. */
bool BoostEnvironment::findVM(VMIdentifier identifier,
                              std::function<void(BoostVM& boostVM)> onSuccess) {
  boost::lock_guard<boost::mutex> lock(_vmsMutex);
  for (BoostVM& vm : _vms) {
    if (vm.identifier == identifier) {
      onSuccess(vm);
      return true;
    }
  }
  return false;
}

UnstableNode BoostEnvironment::listVMs(VM vm) {
  boost::lock_guard<boost::mutex> lock(_vmsMutex);
  UnstableNode list = buildList(vm);
  for (BoostVM& boostVM : _vms)
    list = buildCons(vm, build(vm, boostVM.identifier), list);
  return list;
}

void BoostEnvironment::killVM(VMIdentifier identifier, nativeint exitCode,
                              const std::string& reason) {
  findVM(identifier, [this, exitCode, reason] (BoostVM& targetVM) {
    targetVM.requestTermination(exitCode, reason);
  });
}

void BoostEnvironment::removeTerminatedVM(VMIdentifier identifier,
                                          nativeint exitCode,
                                          boost::asio::io_service::work* work) {
  {
    boost::lock_guard<boost::mutex> lock(_vmsMutex);

    // Warning: the BoostVM is calling its own destructor with remove_if().
    // We also need VirtualMachine destructor to do its cleanup before dying.
    _vms.remove_if([=] (const BoostVM& vm) {
      return vm.identifier == identifier;
    });
  }

  if (identifier == InitialVMIdentifier) // only the exitCode of the initial VM is considered
    _exitCode = exitCode;

  // Tell the IO thread it does not need to wait anymore for us
  delete work;
  // Here the VM thread ends.
}

void BoostEnvironment::sendOnVMPort(VM from, VMIdentifier to, RichNode value) {
  BoostVM::forVM(from).sendOnVMPort(to, value);
}

int BoostEnvironment::runIO() {
  // This will end when all VMs are done.
  io_service.run();

  return _exitCode;
}

void BoostEnvironment::withSecondMemoryManager(const std::function<void(MemoryManager&)>& doGC) {
  // Disallow concurrent GCs, so only one has access to the second MemoryManager
  // at a time and we have a much lower maximal memory footprint.
  boost::lock_guard<boost::mutex> lock(_gcMutex);
  doGC(_secondMemoryManager);
}

void BoostEnvironment::withProtectedEnvironmentVariables(const std::function<void()>& operation) {
  boost::lock_guard<boost::mutex> lock(_environmentVariablesMutex);
  operation();
}

///////////////
// Utilities //
///////////////

template <typename T>
void raiseOSError(VM vm, const char* function, nativeint errnum, T&& message) {
  raiseSystem(vm, "os", "os", function, errnum, std::forward<T>(message));
}

void raiseOSError(VM vm, const char* function, int errnum) {
  raiseOSError(vm, function, errnum, vm->getAtom(std::strerror(errnum)));
}

void raiseLastOSError(VM vm, const char* function) {
  raiseOSError(vm, function, errno);
}

void raiseOSError(VM vm, const char* function, boost::system::error_code& ec) {
  raiseOSError(vm, function, ec.value(), vm->getAtom(ec.message()));
}

void raiseOSError(VM vm, const char* function,
                  const boost::system::system_error& error) {
  raiseOSError(vm, function, error.code().value(), vm->getAtom(error.what()));
}

} }

#endif

#endif // MOZART_BOOSTENV_H
