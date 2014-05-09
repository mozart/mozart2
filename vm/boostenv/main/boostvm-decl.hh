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

#ifndef MOZART_BOOSTVM_DECL_H
#define MOZART_BOOSTVM_DECL_H

#include <mozart.hh>

#include <atomic>
#include <mutex>

#include <boost/thread.hpp>

#include <boost/uuid/uuid.hpp>
#include <boost/uuid/random_generator.hpp>

#include <boost/asio.hpp>

namespace mozart { namespace boostenv {

class BoostEnvironment;

/////////////
// BoostVM //
/////////////

class BoostVM : VirtualMachine {
public:
  BoostVM(BoostEnvironment& environment,
          VMIdentifier identifier,
          VirtualMachineOptions options,
          const std::string& app, bool isURL);

  static BoostVM& forVM(VM vm) {
    return *static_cast<BoostVM*>(vm);
  }

// Run and preemption
public:
  void run();
private:
  void start(std::string app, bool isURL);
  void onPreemptionTimerExpire(const boost::system::error_code& error);

// UUID generation
public:
  UUID genUUID();
private:
  static std::uint64_t bytes2uint64(const std::uint8_t* bytes);

// VM Port
public:
  bool streamAsked();

  bool portClosed();

  void getStream(UnstableNode &stream);

  void closeStream();

  void sendOnVMPort(VMIdentifier to, RichNode value);

  void receiveOnVMStream(UnstableNode value);

  void receiveOnVMStream(std::vector<unsigned char>* buffer);

// Termination
public:
  void requestTermination();

  void addMonitor(VMIdentifier monitor);

private:
  void tellMonitors();

  void terminate();

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

// GC
public:
  void gCollect(GC gc) {
    gc->copyStableRef(_headOfStream, _headOfStream);
    gc->copyStableRef(_stream, _stream);
  }

public:
  VM vm;
  BoostEnvironment& env;
  VMIdentifier identifier;

// Random number and UUID generation
public:
  typedef boost::random::mt19937 random_generator_t;
  random_generator_t random_generator;
private:
  boost::uuids::random_generator uuidGenerator;

// VM stream
private:
  StableNode* _headOfStream;
  StableNode* _stream;
  std::atomic_bool _portClosed;

// Number of asynchronous IO nodes - used for termination detection
private:
  size_t _asyncIONodeCount;

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

// Monitors
private:
  std::vector<VMIdentifier> _monitors;
  std::mutex _monitorsMutex;

// Running thread management
private:
  bool _terminationRequested;
  boost::asio::io_service::work* _work;
};

} }

#endif // MOZART_BOOSTVM_DECL_H
