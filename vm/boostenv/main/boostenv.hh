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

namespace {
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

  bool defaultBootLoader(VM vm, const std::string& url, UnstableNode& result) {
    std::string filename = decodedURLToFilename(decodeURL(url));
    std::ifstream input(filename, std::ios::binary);
    if (!input.is_open())
      return false;
    result = bootUnpickle(vm, input);
    return true;
  }
}

BoostEnvironment::BoostEnvironment(const VMStarter& vmStarter,
                                   VirtualMachineOptions options) :
  _nextVMIdentifier(1), _aliveVMs(0),
  _options(options), vmStarter(vmStarter) {
  // Set up a default boot loader
  setBootLoader(&defaultBootLoader);
}

BoostVM& BoostEnvironment::addVM(const std::string& app, bool isURL) {
  std::lock_guard<std::mutex> lock(_vmsMutex);
  vms.emplace_front(*this, _nextVMIdentifier++, _options, app, isURL);
  _aliveVMs++;
  return vms.front();
}

BoostVM& BoostEnvironment::getVM(VM vm, nativeint identifier) {
  {
    std::lock_guard<std::mutex> lock(_vmsMutex);
    for (BoostVM& vm : vms) {
      if (vm.identifier == identifier)
        return vm;
    }
  }
  raiseError(vm, "Invalid VM identifier: ", identifier);
}

UnstableNode BoostEnvironment::listVMs(VM vm) {
  std::lock_guard<std::mutex> lock(_vmsMutex);
  UnstableNode list = buildList(vm);
  for (BoostVM& boostVM : vms) {
    if (boostVM.isRunning())
      list = buildCons(vm, SmallInt::build(vm, boostVM.identifier), list);
  }
  return list;
}

void BoostEnvironment::killVM(VM vm, nativeint exitCode) {
  if (BoostVM::forVM(vm).isRunning()) {
    BoostVM::forVM(vm).requestTermination();
    if (--_aliveVMs == 0) { // killing the last VM
      std::exit(exitCode);
    }
  }
}

void BoostEnvironment::runIO() {
  // This will end when all VMs are done.
  io_service.run();
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
