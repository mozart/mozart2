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

BoostBasedVM::BoostBasedVM(size_t maxMemory):
  virtualMachine(*this, maxMemory), vm(&virtualMachine),
  _asyncIONodeCount(0),
  uuidGenerator(random_generator),
  preemptionTimer(io_service), alarmTimer(io_service) {

  builtins::biref::registerBuiltinModOS(vm);

  // Initialize the pseudo random number generator with a really random seed
  boost::random::random_device generator;
  random_generator.seed(generator);

  // Set up a default boot loader
  setBootLoader(&defaultBootLoader);
}

void BoostBasedVM::setApplicationURL(char const* url) {
  // TODO Check that url is a valid UTF-8 string?
  vm->getPropertyRegistry().put(vm, "application.url", url);
}

void BoostBasedVM::setApplicationArgs(int argc, char const* const* argv) {
  // TODO Check that argv[i] are valid UTF-8 strings?
  OzListBuilder args(vm);
  for (int i = 0; i < argc; i++) {
    args.push_back(vm, argv[i]);
  }

  vm->getPropertyRegistry().put(vm, "application.args", args.get(vm));
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
