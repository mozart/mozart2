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

bool mozart::MozartTest::EXPECT_RAISE(const BaseLString<nchar>& label, OpResult result) const {
    EXPECT_EQ(OpResult::orRaise, result.kind());
    if (OpResult::orRaise != result.kind()) return false;
    UnstableNode excNode = Reference::build(vm, result.getExceptionNode());
    UnstableNode labelNode;
    if (!EXPECT_PROCEED(RecordLike(excNode).label(vm, labelNode))) return false;
    return EXPECT_EQ_ATOM(label, labelNode);
}

namespace mozart { namespace mut {

  template <class C>
  void PrintTo(const BaseLString<C>& input, std::ostream* out) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshift-count-overflow"
    static const nativeint mask = (1 << (8 * sizeof(C))) - 1;
#pragma clang diagnostic pop

    *out << "< ";
    auto oldBase = out->setf(std::ios_base::hex, std::ios_base::basefield);
    for (nativeint c : input) {
      out->width(sizeof(C)*2);
      out->fill('0');
      *out << (c & mask) << " ";
    }
    out->setf(oldBase, std::ios_base::basefield);
    *out << ">";
  }

  template void PrintTo(const BaseLString<unsigned char>& input, std::ostream* out);
  template void PrintTo(const BaseLString<char>& input, std::ostream* out);
  template void PrintTo(const BaseLString<char16_t>& input, std::ostream* out);
  template void PrintTo(const BaseLString<char32_t>& input, std::ostream* out);
}}


