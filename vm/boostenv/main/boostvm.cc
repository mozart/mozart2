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
#include <boost/bind.hpp>
#include <boost/random/random_device.hpp>

namespace mozart { namespace boostenv {

/////////////
// BoostVM //
/////////////

BoostVM::BoostVM(BoostEnvironment& environment,
                 VMIdentifier identifier,
                 VirtualMachineOptions options,
                 const std::string& app, bool isURL) :
  VirtualMachine(environment, options), vm(this),
  env(environment), identifier(identifier),
  uuidGenerator(random_generator),
  _portClosed(false),
  _asyncIONodeCount(0),
  preemptionTimer(environment.io_service),
  alarmTimer(environment.io_service),
  _terminationRequested(false),
  _terminationReason("normal") {

  // Make sure the IO thread will wait for us
  _work = new boost::asio::io_service::work(environment.io_service);

  builtins::biref::registerBuiltinModOS(vm);
  builtins::biref::registerBuiltinModVM(vm);

  // Initialize the pseudo random number generator with a really random seed
  boost::random::random_device generator;
  random_generator.seed(generator);

  UnstableNode future = ReadOnlyVariable::build(vm);
  _stream = _headOfStream = RichNode(future).getStableRef(vm);

  // Finally start the VM thread, which will initialize and run the VM
  boost::thread thread(&BoostVM::start, this, app, isURL);
  thread.detach();
};

void BoostVM::start(std::string app, bool isURL) {
  try {
    if (!env.vmStarter(vm, app, isURL)) {
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
    preemptionTimer.expires_from_now(boost::posix_time::millisec(1));
    preemptionTimer.async_wait(boost::bind(
      &BoostVM::onPreemptionTimerExpire,
      this, boost::asio::placeholders::error));

    // Run the VM
    auto nextInvokePair = vm->run();
    auto nextInvoke = nextInvokePair.first;

    // Stop the preemption timer
    preemptionTimer.cancel();

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
        _vmEventsCallbacks.front()();
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

void BoostVM::onPreemptionTimerExpire(const boost::system::error_code& error) {
  if (error != boost::asio::error::operation_aborted) {
    // Preemption
    vm->setReferenceTime(env.getReferenceTime());
    vm->requestPreempt();

    // Reschedule
    preemptionTimer.expires_at(
      preemptionTimer.expires_at() + boost::posix_time::millisec(1));
    preemptionTimer.async_wait(boost::bind(
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

bool BoostVM::portClosed() {
  return _portClosed;
}

void BoostVM::getStream(UnstableNode &stream) {
  if (!streamAsked()) {
    // Get the beginning of the stream as if the call was done at VM creation
    stream.copy(vm, *_headOfStream);
    _asyncIONodeCount++; // Wait for the VM stream until closeStream()
    _headOfStream = nullptr;
  } else {
    // Get the tail of the stream
    stream.copy(vm, *_stream);
  }
}

void BoostVM::closeStream() {
  if (!portClosed()) {
    if (streamAsked())
      _asyncIONodeCount--; // We are no more interested in the stream
    UnstableNode nil = buildNil(vm);
    BindableReadOnly(*_stream).bindReadOnly(vm, nil);
    _portClosed = true;
  }
}

void BoostVM::sendOnVMPort(VMIdentifier to, RichNode value) {
  // If the target VM has closed its port or terminated,
  // we do not need to pickle value
  bool portClosed = true;
  env.findVM(to, [&portClosed] (BoostVM& targetVM) {
    portClosed = targetVM.portClosed();
  });
  if (portClosed)
    return;

  UnstableNode picklePack;
  if (!vm->getPropertyRegistry().get(vm, "pickle.pack", picklePack))
    raiseError(vm, "Could not find property pickle.pack");

  UnstableNode vbs;
  ozcalls::ozCall(vm, "mozart::boostenv::BoostVM::sendOnVMPort",
    picklePack, value, ozcalls::out(vbs));

  size_t bufSize = ozVBSLengthForBuffer(vm, vbs);
  // allocates the vector in a neutral zone: the heap
  std::vector<unsigned char> *buffer = new std::vector<unsigned char>();
  ozVBSGet(vm, vbs, bufSize, *buffer);

  bool found = env.findVM(to, [buffer] (BoostVM& targetVM) {
    targetVM.postVMEvent([buffer,&targetVM] () {
      targetVM.receiveOnVMStream(buffer);
    });
  });
  if (!found)
    delete buffer;
}

void BoostVM::receiveOnVMStream(UnstableNode value) {
  if (!portClosed())
    sendToReadOnlyStream(vm, _stream, value);
}

void BoostVM::receiveOnVMStream(std::vector<unsigned char>* buffer) {
  if (portClosed()) {
    delete buffer;
    return;
  }

  std::string str(buffer->begin(), buffer->end());
  std::istringstream input(str);
  UnstableNode unpickled = bootUnpickle(vm, input);
  delete buffer;

  sendToReadOnlyStream(vm, _stream, unpickled);
}

void BoostVM::requestTermination(const std::string& reason) {
  postVMEvent([this,reason] {
    _terminationReason = reason;
    _terminationRequested = true;
  });
}

UnstableNode BoostVM::buildTerminationRecord(VMIdentifier deadVM, std::string reason) {
  return buildRecord(vm,
    buildArity(vm, "terminated", 1, "reason"),
               deadVM, vm->getAtom(reason));
}

void BoostVM::addMonitor(VMIdentifier monitor) {
  boost::lock_guard<std::mutex> lock(_monitorsMutex);
  _monitors.push_back(monitor);
}

void BoostVM::tellMonitors() {
  std::lock_guard<std::mutex> lock(_monitorsMutex);
  VMIdentifier deadVM = this->identifier;
  std::string reason = this->_terminationReason;
  for (VMIdentifier identifier : _monitors) {
    env.findVM(identifier, [=] (BoostVM& monitor) {
      monitor.postVMEvent([&monitor,deadVM,reason] () {
        monitor.receiveOnVMStream(
          monitor.buildTerminationRecord(deadVM, reason));
      });
    });
  }
}

void BoostVM::terminate() {
  // Ensure to stop the timers as we might have quitted run() brutally
  preemptionTimer.cancel();
  alarmTimer.cancel();

  closeStream();
  tellMonitors();

  env.removeTerminatedVM(identifier, _work);
}

} }
