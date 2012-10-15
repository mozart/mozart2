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

#ifndef __BOOSTENV_DECL_H
#define __BOOSTENV_DECL_H

#include <mozart.hh>

#include <ctime>
#include <cstdio>
#include <cerrno>
#include <forward_list>

#include <boost/thread.hpp>

#include <boost/uuid/uuid.hpp>
#include <boost/uuid/random_generator.hpp>

#include <boost/asio.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/bind.hpp>

namespace mozart { namespace boostenv {

//////////////////
// BoostBasedVM //
//////////////////

class BoostBasedVM: public VirtualMachineEnvironment {
public:
  BoostBasedVM();

  static BoostBasedVM& forVM(VM vm) {
    return static_cast<BoostBasedVM&>(vm->getEnvironment());
  }

// Configuration

public:
  void setApplicationURL(char const* url);

  void setApplicationArgs(int argc, char const* const* argv);

// Run and preemption

public:
  void run();
private:
  void onPreemptionTimerExpire(const boost::system::error_code& error);

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
  UUID genUUID();
private:
  inline
  static std::uint64_t bytes2uint64(const std::uint8_t* bytes);

// Management of nodes used by asynchronous operations for feedback

public:
  inline
  ProtectedNode allocAsyncIONode(StableNode* node);

  inline
  void releaseAsyncIONode(const ProtectedNode& node);

  inline
  ProtectedNode createAsyncIOFeedbackNode(UnstableNode& readOnly);

  template <class LT, class... Args>
  inline
  void bindAndReleaseAsyncIOFeedbackNode(const ProtectedNode& ref,
                                         LT&& label, Args&&... args);

  template <class LT, class... Args>
  inline
  void raiseAndReleaseAsyncIOFeedbackNode(const ProtectedNode& ref,
                                          LT&& label, Args&&... args);

// Notification from asynchronous work

public:
  inline
  void postVMEvent(std::function<void()> callback);

// Internal file descriptors management

public:
  inline
  nativeint registerFile(std::FILE* file);

  inline
  void unregisterFile(nativeint fd);

  inline
  std::FILE* getFile(nativeint fd);

  inline
  std::FILE* getFile(RichNode fd);

// Reference to the virtual machine
private:
  VirtualMachine virtualMachine;
public:
  const VM vm;

// Number of asynchronous IO nodes - used for termination detection
private:
  size_t _asyncIONodeCount;

// Random number generation
public:
  typedef boost::random::mt19937 random_generator_t;
  random_generator_t random_generator;
private:
  boost::uuids::random_generator uuidGenerator;

// ASIO service
public:
  boost::asio::io_service io_service;

// Synchronization condition variable telling there is work to do in the VM
private:
  boost::condition_variable _conditionWorkToDoInVM;
  boost::mutex _conditionWorkToDoInVMMutex;

// Preemption and alarms
private:
  boost::asio::deadline_timer preemptionTimer;
  boost::asio::deadline_timer alarmTimer;

// IO-driven events that must work with the VM store
private:
  std::queue<std::function<void()> > _vmEventsCallbacks;

// File I/O
private:
  std::map<nativeint, std::FILE*> openedFiles;
public:
  nativeint fdStdin;
  nativeint fdStdout;
  nativeint fdStderr;
};

///////////////
// Utilities //
///////////////

inline
void ozStringToBuffer(VM vm, RichNode value, size_t size, char* buffer);

inline
void ozStringToBuffer(VM vm, RichNode value, std::vector<char>& buffer);

inline
std::string ozStringToStdString(VM vm, RichNode value);

inline
UnstableNode stdStringToOzString(VM vm, const std::string& value);

inline
std::unique_ptr<nchar[]> systemStrToMozartStr(const char* str);

inline
std::unique_ptr<nchar[]> systemStrToMozartStr(const std::string& str);

inline
void MOZART_NORETURN raiseOSError(VM vm, int errnum);

inline
void MOZART_NORETURN raiseLastOSError(VM vm);

inline
void MOZART_NORETURN raiseSystemError(VM vm,
                                      const boost::system::system_error& error);

} }

#endif // __BOOSTENV_DECL_H
