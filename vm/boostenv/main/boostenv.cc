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

#include <fstream>
#include <boost/random/random_device.hpp>

namespace mozart { namespace boostenv {

//////////////////
// BoostBasedVM //
//////////////////

BoostBasedVM::BoostBasedVM(): virtualMachine(*this), vm(&virtualMachine),
  _asyncIONodeCount(0),
  uuidGenerator(random_generator),
  preemptionTimer(io_service), alarmTimer(io_service) {

  builtins::biref::registerBuiltinModOS(vm);

  // Initialize the pseudo random number generator with a really random seed
  boost::random::random_device generator;
  random_generator.seed(generator);

  // Set up a default boot loader
  setBootLoader(
    [] (VM vm, const std::string& url, UnstableNode& result) -> bool {
      std::ifstream input(url, std::ios::binary);
      if (!input.is_open())
        return false;
      result = bootUnpickle(vm, input);
      return true;
    }
  );
}

void BoostBasedVM::setApplicationURL(char const* url) {
  VM vm = this->vm;

  auto property = build(vm, MOZART_STR("application.url"));

  auto decodedURL = toUTF<nchar>(makeLString(url));
  auto ozURL = build(vm, vm->getAtom(decodedURL.length, decodedURL.string));

  vm->getPropertyRegistry().put(vm, property, ozURL);
}

void BoostBasedVM::setApplicationArgs(int argc, char const* const* argv) {
  VM vm = this->vm;
  OzListBuilder args(vm);

  for (int i = 0; i < argc; i++) {
    auto decodedArg = toUTF<nchar>(makeLString(argv[i]));
    args.push_back(vm, vm->getAtom(decodedArg.length, decodedArg.string));
  }

  auto property = build(vm, MOZART_STR("application.args"));
  auto ozArgs = args.get(vm);

  vm->getPropertyRegistry().put(vm, property, ozArgs);
}

void BoostBasedVM::run() {
  constexpr auto recNeverInvokeAgain = VirtualMachine::recNeverInvokeAgain;
  constexpr auto recInvokeAgainNow   = VirtualMachine::recInvokeAgainNow;
  constexpr auto recInvokeAgainLater = VirtualMachine::recInvokeAgainLater;

  // Prevent the ASIO run thread from exiting by giving it some "work" to do
  auto work = new boost::asio::io_service::work(io_service);

  // Now start the ASIO run thread
  boost::thread asioRunThread(boost::bind(
    &boost::asio::io_service::run, &io_service));

  // The main loop that handles all interactions with the VM
  while (true) {
    // Make sure the VM knows the reference time before starting
    vm->setReferenceTime(getReferenceTime());

    // Setup the preemption timer
    preemptionTimer.expires_from_now(boost::posix_time::millisec(1));
    preemptionTimer.async_wait(boost::bind(
      &BoostBasedVM::onPreemptionTimerExpire,
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
      if ((nextInvoke == recNeverInvokeAgain) &&
          (_asyncIONodeCount == 0) && _vmEventsCallbacks.empty()) {
        // Totally finished, nothing can ever wake me again
        break;
      }

      // Handle asynchronous events coming from I/O, e.g.
      while (!_vmEventsCallbacks.empty()) {
        _vmEventsCallbacks.front()();
        _vmEventsCallbacks.pop();

        // That could have created work for the VM
        nextInvoke = recInvokeAgainNow;
      }

      // Unless asked to invoke again now, setup the wait
      if (nextInvoke != recInvokeAgainNow) {
        // Setup the alarm time, if asked by the VM
        if (nextInvoke == recInvokeAgainLater) {
          alarmTimer.expires_at(referenceTimeToPTime(nextInvokePair.second));
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

  // Tear down
  delete work;
  asioRunThread.join();

  // Get ready for a later call to run()
  io_service.reset();
}

void BoostBasedVM::onPreemptionTimerExpire(
  const boost::system::error_code& error) {

  if (error != boost::asio::error::operation_aborted) {
    // Preemption
    vm->setReferenceTime(getReferenceTime());
    vm->requestPreempt();

    // Reschedule
    preemptionTimer.expires_at(
      preemptionTimer.expires_at() + boost::posix_time::millisec(1));
    preemptionTimer.async_wait(boost::bind(
      &BoostBasedVM::onPreemptionTimerExpire,
      this, boost::asio::placeholders::error));
  }
}

UUID BoostBasedVM::genUUID() {
  boost::uuids::uuid uuid = uuidGenerator();

  std::uint64_t data0 = bytes2uint64(uuid.data);
  std::uint64_t data1 = bytes2uint64(uuid.data+8);

  return UUID(data0, data1);
}

std::uint64_t BoostBasedVM::bytes2uint64(const std::uint8_t* bytes) {
  return
    ((std::uint64_t) bytes[0] << 56) + ((std::uint64_t) bytes[1] << 48) +
    ((std::uint64_t) bytes[2] << 40) + ((std::uint64_t) bytes[3] << 32) +
    ((std::uint64_t) bytes[4] << 24) + ((std::uint64_t) bytes[5] << 16) +
    ((std::uint64_t) bytes[6] << 8) + ((std::uint64_t) bytes[7] << 0);
}

} }
