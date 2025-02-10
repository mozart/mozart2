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

#include "boostenv.hh"

#include <exception>
#include <boost/random/random_device.hpp>

#ifdef MOZART_WINDOWS
#  include <windows.h>
#else
#  include <csignal>
#endif

namespace mozart { namespace boostenv {

/////////////
// BoostVM //
/////////////

BoostVM::BoostVM(BoostEnvironment& environment,
                 VMIdentifier parent,
                 VMIdentifier identifier,
                 VirtualMachineOptions options,
                 std::unique_ptr<std::string>&& app, bool isURL) :
  VirtualMachine(environment, options), env(environment),
  vm(this), identifier(identifier),
  uuidGenerator(),
  portClosed(false),
  _asyncIONodeCount(0),
  preemptionTimer(new boost::asio::deadline_timer(environment.io_context)),
  alarmTimer(environment.io_context),
  _terminationRequested(false),
  _terminationStatus(0),
  _terminationReason("normal"),
  // Make sure the IO thread will wait for us
  _work(new boost::asio::io_context::work(environment.io_context)) {

  if (identifier != parent)
    addMonitor(parent);

  builtins::biref::registerBuiltinModOS(vm);
  builtins::biref::registerBuiltinModVM(vm);

  // Initialize the pseudo random number generator with a really random seed
  boost::random::random_device generator;
  random_generator.seed(generator);

  _stream = _headOfStream = new (vm) StableNode(vm, ReadOnlyVariable::build(vm));

  // Finally start the VM thread, which will initialize and run the VM
  // We need to use a raw pointer here as we cannot pass a rvalue reference
  boost::thread thread(&BoostVM::start, this, app.release(), isURL);
  // The thread will ultimately delete the BoostVM and all its members.
  // Therefore, we cannot store the boost::thread instance inside the BoostVM
  // because deleting a not joinable (not finished) instance calls std::terminate().
  // So we let the thread handle live on its own and we need not to call
  // join() as the IO thread and _work are responsible for waiting correctly.
  thread.detach();
};

void BoostVM::start(std::string* app, bool isURL) {
  try {
    if (!env.vmStarter(vm, std::unique_ptr<std::string>(app), isURL)) {
      std::cerr << "Could not start VM." << std::endl;
    }
  } catch (std::bad_alloc& ba) {
    _terminationReason = "outOfMemory";
    std::cerr << "Terminated VM " << identifier << std::endl;
  } catch (std::exception& e) {
    _terminationReason = "abnormal";
    std::cerr << "Terminated VM " << identifier;
    std::cerr << " because a C++ exception was uncaught:" << std::endl;
    std::cerr << e.what() << std::endl;
  }
  terminate();
}

void BoostVM::run() {
  constexpr auto recNeverInvokeAgain = VirtualMachine::recNeverInvokeAgain;
  constexpr auto recInvokeAgainNow   = VirtualMachine::recInvokeAgainNow;
  constexpr auto recInvokeAgainLater = VirtualMachine::recInvokeAgainLater;

  // The main loop that handles all interactions with the VM
  while (true) {
    // Make sure the VM knows the reference time before starting
    vm->setReferenceTime(env.getReferenceTime());

    // Setup the preemption timer
    boost::asio::post(env.io_context, [&](){
        preemptionTimer->expires_from_now(boost::posix_time::millisec(1));
        preemptionTimer->async_wait(boost::bind(
              &BoostVM::onPreemptionTimerExpire,
              this, boost::asio::placeholders::error));
    });

    // Run the VM
    auto nextInvokePair = vm->run();
    auto nextInvoke = nextInvokePair.first;

    // Stop the preemption timer
    boost::asio::post(env.io_context, [&](){
        preemptionTimer->expires_at(boost::posix_time::min_date_time);
    });

    {
      // Acquire the lock that grants me access to
      // _conditionWorkToDoInVM and _vmEventsCallbacks
      boost::unique_lock<boost::mutex> lock(_conditionWorkToDoInVMMutex);

      // Is there anything left to do?
      if (((nextInvoke == recNeverInvokeAgain) &&
          (_asyncIONodeCount == 0) && _vmEventsCallbacks.empty())) {
        // Totally finished, nothing can ever wake me again
        break;
      }

      // Handle asynchronous events coming from I/O, e.g.
      while (!_vmEventsCallbacks.empty()) {
        _vmEventsCallbacks.front()(*this);
        _vmEventsCallbacks.pop();

        if (_terminationRequested)
          return; // Safe point to exit run()

        // That could have created work for the VM
        nextInvoke = recInvokeAgainNow;
      }

      // Unless asked to invoke again now, setup the wait
      if (nextInvoke != recInvokeAgainNow) {
        // Setup the alarm time, if asked by the VM
        if (nextInvoke == recInvokeAgainLater) {
          alarmTimer.expires_at(
            BoostEnvironment::referenceTimeToPTime(nextInvokePair.second));
          alarmTimer.async_wait([this] (const boost::system::error_code& err) {
            if (!err) {
              boost::lock_guard<boost::mutex> lock(_conditionWorkToDoInVMMutex);
              _conditionWorkToDoInVM.notify_all();
            }
          });
        }

        _conditionWorkToDoInVM.wait(lock);
      }
    }

    // Cancel the alarm timer, in case it was not it that woke me
    alarmTimer.cancel();
  }
}

// Called by the *IO thread*
void BoostVM::onPreemptionTimerExpire(const boost::system::error_code& error) {
  if (error == boost::asio::error::operation_aborted) {
    // Timer was cancelled
  } else if (_terminationRequested) {
    // Termination was requested
  } else if (preemptionTimer->expires_at() == boost::posix_time::min_date_time) {
    // Timer was cancelled, but we missed it (race condition in io_context)
  } else {
    // Preemption
    vm->setReferenceTime(env.getReferenceTime());
    vm->requestPreempt();

    // Reschedule
    preemptionTimer->expires_at(
        preemptionTimer->expires_at() + boost::posix_time::millisec(1));
    preemptionTimer->async_wait(boost::bind(
          &BoostVM::onPreemptionTimerExpire,
          this, boost::asio::placeholders::error));
  }
}

UUID BoostVM::genUUID() {
  boost::uuids::uuid uuid = uuidGenerator();

  std::uint64_t data0 = bytes2uint64(uuid.data);
  std::uint64_t data1 = bytes2uint64(uuid.data+8);

  return UUID(data0, data1);
}

std::uint64_t BoostVM::bytes2uint64(const std::uint8_t* bytes) {
  return
    ((std::uint64_t) bytes[0] << 56) + ((std::uint64_t) bytes[1] << 48) +
    ((std::uint64_t) bytes[2] << 40) + ((std::uint64_t) bytes[3] << 32) +
    ((std::uint64_t) bytes[4] << 24) + ((std::uint64_t) bytes[5] << 16) +
    ((std::uint64_t) bytes[6] << 8) + ((std::uint64_t) bytes[7] << 0);
}

bool BoostVM::streamAsked() {
  return _headOfStream == nullptr;
}

UnstableNode BoostVM::getStream() {
  UnstableNode stream;
  if (!streamAsked()) {
    // Get the beginning of the stream as if the call was done at VM creation
    stream.copy(vm, *_headOfStream);
    _asyncIONodeCount++; // Wait for the VM stream until closeStream()
    _headOfStream = nullptr;
  } else {
    // Get the tail of the stream
    stream.copy(vm, *_stream);
  }
  return stream;
}

void BoostVM::closeStream() {
  if (!portClosed) {
    if (streamAsked())
      _asyncIONodeCount--; // We are no more interested in the stream
    UnstableNode nil = buildNil(vm);
    BindableReadOnly(*_stream).bindReadOnly(vm, nil);
    portClosed = true;
  }
}

void BoostVM::sendOnVMPort(VMIdentifier to, RichNode value) {
  // If the target VM has closed its port or terminated,
  // we do not need to pickle value
  bool portClosed = true;
  env.findVM(to, [&portClosed] (BoostVM& targetVM) {
    portClosed = targetVM.portClosed;
  });
  if (portClosed)
    return;

  std::ostringstream out;
  pickle(vm, value, out);
  // allocates the buffer in a neutral zone: the heap
  std::string* buffer = new std::string(out.str());

  bool found = env.postVMEvent(to, [buffer] (BoostVM& targetVM) {
    targetVM.receiveOnVMStream(buffer);
  });
  if (!found)
    delete buffer;
}

void BoostVM::receiveOnVMStream(RichNode value) {
  if (!portClosed)
    sendToReadOnlyStream(vm, _stream, value);
}

void BoostVM::receiveOnVMStream(std::string* buffer) {
  if (portClosed) {
    delete buffer;
    return;
  }

  std::istringstream input(*buffer);
  UnstableNode unpickled = unpickle(vm, input);
  delete buffer;

  sendToReadOnlyStream(vm, _stream, unpickled);
}

void BoostVM::requestTermination(nativeint exitCode, const std::string& reason) {
  _terminationStatus = exitCode;
  _terminationReason = reason;
  _terminationRequested = true;
}

UnstableNode BoostVM::buildTerminationRecord(VMIdentifier deadVM, const std::string& reason) {
  return buildRecord(vm,
    buildArity(vm, "terminated", 1, "reason"),
               deadVM, vm->getAtom(reason));
}

void BoostVM::addMonitor(VMIdentifier monitor) {
  _monitors.push_back(monitor);
}

void BoostVM::addChildProcess(nativeint pid) {
  _childProcesses.push_back(pid);
}

void BoostVM::killChildProcesses() {
  for (auto pid : _childProcesses) {
#ifndef MOZART_WINDOWS
    kill(pid, SIGTERM);
#else
    HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, pid);
    if (hProcess) {
      TerminateProcess(hProcess, 0);
      CloseHandle(hProcess);
    }
#endif
  }
}

void BoostVM::notifyMonitors() {
  VMIdentifier deadVM = this->identifier;
  std::string reason = this->_terminationReason;
  for (VMIdentifier identifier : _monitors) {
    env.postVMEvent(identifier, [deadVM, reason] (BoostVM& monitor) {
      UnstableNode notification = monitor.buildTerminationRecord(deadVM, reason);
      monitor.receiveOnVMStream(notification);
    });
  }
}

void BoostVM::terminate() {
  // Warning: we should only access BoostVM members here and do
  // not interact with the VM as we might have quitted run() brutally.

  // Ensure the timers are stopped
  auto& preemptionTimerCopy = preemptionTimer;
  // We need a copy of preemptionTimer because we cannot capture 'this'.
  // It may be deleted before the execution of the callback.
  // For the same reason, we access the io_context via the timer.
  boost::asio::post(env.io_context, [preemptionTimerCopy]{
      preemptionTimerCopy->expires_at(boost::posix_time::min_date_time);
      // We cannot delete the timer now because the onPreemptionTimerExpire handler
      // may already be in the queue. So add a delete lambda to the queue.
      // The lambda will execute after any leftover handlers on the timer and
      // with the timer stopped.
      boost::asio::post(preemptionTimerCopy->get_executor(), [preemptionTimerCopy] {
          delete preemptionTimerCopy;
      });
  });
  alarmTimer.cancel();

  portClosed = true; // close VM port
  killChildProcesses();
  notifyMonitors();

  env.removeTerminatedVM(identifier, _terminationStatus, _work);
}

} }
