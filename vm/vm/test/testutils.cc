#include "testutils.hh"

#include <cstdlib>
#include <ctime>

namespace {
  struct TestEnvData {
    TestEnvData(): testPreemptionCount(3) {}

    int testPreemptionCount;
  };

  bool testTestPreemption(void* _data) {
    TestEnvData* data = static_cast<TestEnvData*>(_data);

    if (--data->testPreemptionCount == 0) {
      data->testPreemptionCount = 3;
      return true;
    } else {
      return false;
    }
  }

  inline
  std::uint64_t rand8() {
    return std::rand() % 0x100;
  }

  inline
  std::uint64_t rand16() {
    return (rand8() << 8) + rand8();
  }

  inline
  std::uint64_t rand64() {
    return (rand16() << 48) + (rand16() << 32) + (rand16() << 16) + rand16();
  }

  mozart::UUID testGenUUID(void* _data) {
    std::uint64_t data0 = (rand64() & ~0xf000) | 0x4000;
    std::uint64_t data1 =
      (rand64() & ~((std::uint64_t) 0xf << 60)) | ((std::uint64_t) 0x8 << 60);

    return mozart::UUID(data0, data1);
  }
}

mozart::VirtualMachineEnvironment makeTestEnvironment() {
  std::srand(std::time(nullptr));

  mozart::VirtualMachineEnvironment env;
  env.data = static_cast<void*>(new TestEnvData());
  env.testPreemption = &testTestPreemption;
  env.genUUID = &testGenUUID;

  return env;
}
