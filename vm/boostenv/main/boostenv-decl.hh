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

#ifndef MOZART_BOOSTENV_DECL_H
#define MOZART_BOOSTENV_DECL_H

#include <mozart.hh>

#include <ctime>
#include <cstdio>
#include <cerrno>
#include <forward_list>
#include <mutex>

#include <boost/thread.hpp>

#include <boost/asio.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>

#include "boostvm-decl.hh"
#include "boostenvbigint-decl.hh"

namespace mozart { namespace boostenv {

//////////////////////
// BoostEnvironment //
//////////////////////

class BoostEnvironment: public VirtualMachineEnvironment {
private:
  using BootLoader = std::function<bool(VM vm, const std::string& url,
                                        UnstableNode& result)>;
  using VMStarter = std::function<bool(VM vm, std::unique_ptr<std::string> app, bool isURL)>;

  static const VMIdentifier InitialVMIdentifier = 1;

public:
  static BoostEnvironment& forVM(VM vm) {
    return static_cast<BoostEnvironment&>(vm->getEnvironment());
  }

public:
  inline
  BoostEnvironment(const VMStarter& vmStarter);

// VM Management

public:
  inline
  VMIdentifier addVM(VMIdentifier parent,
                     std::unique_ptr<std::string>&& app, bool isURL,
                     VirtualMachineOptions options);

  VMIdentifier addInitialVM(const std::string& appURL,
                            VirtualMachineOptions options) {
    std::unique_ptr<std::string> app(new std::string(appURL));
    return addVM(InitialVMIdentifier, std::move(app), true, options);
  }

  inline
  VMIdentifier checkValidIdentifier(VM vm, RichNode identifier);

  inline
  bool findVM(VMIdentifier identifier,
              std::function<void(BoostVM& boostVM)> onSuccess);

  inline
  UnstableNode listVMs(VM vm);

  void killVM(VM vm, nativeint exitCode, const std::string& reason) {
    killVM(BoostVM::forVM(vm).identifier, exitCode, reason);
  }

  inline
  void killVM(VMIdentifier identifier, nativeint exitCode,
              const std::string& reason);

  inline
  void removeTerminatedVM(VMIdentifier identifier, nativeint exitCode,
                          boost::asio::io_service::work* work);

// Configuration

public:
  const BootLoader& getBootLoader() {
    return _bootLoader;
  }

  void setBootLoader(const BootLoader& loader) {
    _bootLoader = loader;
  }

// Run and preemption

public:
  inline
  int runIO();

// Time

  static std::int64_t getReferenceTime() {
    return ptimeToReferenceTime(
      boost::posix_time::microsec_clock::universal_time());
  }

  static boost::posix_time::ptime referenceTimeToPTime(std::int64_t time) {
    return epoch() + boost::posix_time::millisec(time);
  }

  static std::int64_t ptimeToReferenceTime(boost::posix_time::ptime time) {
    return (time - epoch()).total_milliseconds();
  }

  static boost::posix_time::ptime epoch() {
    using namespace boost::gregorian;
    return boost::posix_time::ptime(date(1970, Jan, 1));
  }

// UUID generation

public:
  UUID genUUID(VM vm) {
    return BoostVM::forVM(vm).genUUID();
  }

// BigInt

public:
  std::shared_ptr<BigIntImplem> newBigIntImplem(VM vm, nativeint value) {
    return BoostBigInt::make_shared_ptr(value);
  }

  std::shared_ptr<BigIntImplem> newBigIntImplem(VM vm, double value) {
    return BoostBigInt::make_shared_ptr(value);
  }

  std::shared_ptr<BigIntImplem> newBigIntImplem(VM vm, const std::string& value) {
    return BoostBigInt::make_shared_ptr(value);
  }

// VM Port

public:
  inline
  void sendOnVMPort(VM from, VMIdentifier to, RichNode value);

// GC

public:
  inline
  void withSecondMemoryManager(const std::function<void(MemoryManager&)>& doGC);

  void gCollect(GC gc) {
    BoostVM::forVM(gc->vm).gCollect(gc);
  }

// Unsafe process-wide operations

public:
  inline
  void withProtectedEnvironmentVariables(const std::function<void()>& operation);

// VMs
private:
  std::forward_list<BoostVM> _vms;
  std::mutex _vmsMutex;
  std::atomic_int _nextVMIdentifier;
  std::atomic_int _exitCode;
  std::mutex _gcMutex;

// Bootstrap
private:
  BootLoader _bootLoader;
public:
  VMStarter vmStarter;

// Unsafe process-wide operations
private:
  std::mutex _environmentVariablesMutex;

// ASIO service
public:
  boost::asio::io_service io_service;
};

///////////////
// Utilities //
///////////////

template <typename T>
inline
void MOZART_NORETURN raiseOSError(VM vm, const char* function,
                                  nativeint errnum, T&& message);

inline
void MOZART_NORETURN raiseOSError(VM vm, const char* function, int errnum);

inline
void MOZART_NORETURN raiseLastOSError(VM vm, const char* function);

inline
void MOZART_NORETURN raiseOSError(VM vm, const char* function,
                                  boost::system::error_code& ec);

inline
void MOZART_NORETURN raiseOSError(VM vm, const char* function,
                                  const boost::system::system_error& error);

} }

#endif // MOZART_BOOSTENV_DECL_H
