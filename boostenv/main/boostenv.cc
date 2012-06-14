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

namespace mozart { namespace boostenv {

// Some definitions

namespace builtins {
  const size_t ModOS::MaxBufferSize;
}

//////////////////
// BoostBasedVM //
//////////////////

BoostBasedVM::BoostBasedVM(): virtualMachine(*this), vm(&virtualMachine),
  random_generator(std::time(nullptr)), uuidGenerator(random_generator) {

  fdStdin = registerFile(stdin);
  fdStdout = registerFile(stdout);
  fdStderr = registerFile(stderr);
}

void BoostBasedVM::run() {
  vm->setReferenceTime(getReferenceTime());

  boost::thread preemptionThread(preemptionThreadProc, vm);

  while (true) {
    auto sleepDuration = vm->run();

    if (sleepDuration < 0)
      break;

    boost::this_thread::sleep(boost::posix_time::millisec(sleepDuration));
  }

  preemptionThread.interrupt();
  preemptionThread.join();
}

void BoostBasedVM::preemptionThreadProc(VM vm) {
  while (true) {
    boost::this_thread::sleep(boost::posix_time::millisec(1));
    vm->setReferenceTime(getReferenceTime());
    vm->requestPreempt();
  }
}

std::int64_t BoostBasedVM::getReferenceTime() {
  using namespace boost::posix_time;
  using namespace boost::gregorian;

  auto now = microsec_clock::universal_time();
  auto epoch = ptime(date(1970, Jan, 1));

  auto diff = now - epoch;
  return diff.total_milliseconds();
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
