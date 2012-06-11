#include "testutils.hh"

#include <cstdlib>
#include <ctime>

namespace {
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

  class TestEnvironment: public mozart::VirtualMachineEnvironment {
  public:
    TestEnvironment(): VirtualMachineEnvironment(true),
      testPreemptionCount(3) {}

    bool testDynamicPreemption() {
      if (--testPreemptionCount == 0) {
        testPreemptionCount = 3;
        return true;
      } else {
        return false;
      }
    }

    mozart::UUID genUUID() {
      std::uint64_t data0 = (rand64() & ~0xf000) | 0x4000;
      std::uint64_t data1 =
        (rand64() & ~((std::uint64_t) 0xf << 60)) | ((std::uint64_t) 0x8 << 60);

      return mozart::UUID(data0, data1);
    }
  private:
    int testPreemptionCount;
  };
}

std::unique_ptr<mozart::VirtualMachineEnvironment> makeTestEnvironment() {
  return std::unique_ptr<TestEnvironment>(new TestEnvironment());
}
