#include <tuple>
#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

std::string intToString(nativeint value) {
  std::stringstream stream;
  stream << value;
  return stream.str();
}

class VirtualStringTest : public MozartTest {
protected:
  UnstableNode testNodes[26];
  std::basic_string<nchar> minStr;

  virtual void SetUp() {
    testNodes[0] = SmallInt::build(vm, 0);
    testNodes[1] = SmallInt::build(vm, 4);
    testNodes[2] = SmallInt::build(vm, -4);
    testNodes[3] = SmallInt::build(vm, 12300000);
    testNodes[4] = SmallInt::build(vm, -12300000);

    testNodes[5] = Float::build(vm, 3.125);
    testNodes[6] = Float::build(vm, -3.125);
    testNodes[7] = Float::build(vm, 9.0e125);
    testNodes[8] = Float::build(vm, -9.0e125);
    testNodes[9] = Float::build(vm, 9.0e-125);
    testNodes[10] = Float::build(vm, -9.0e-125);
    testNodes[11] = Float::build(vm, 9.5678e125);
    testNodes[12] = Float::build(vm, 9.0);

    testNodes[13] = Atom::build(vm, MOZART_STR("f-o"));
    testNodes[14] = Atom::build(vm, MOZART_STR("nil"));
    testNodes[15] = Atom::build(vm, MOZART_STR("#"));
    testNodes[16] = Atom::build(vm, MOZART_STR("\U0010ffff\U0010ffff"));

    testNodes[17] = String::build(vm, MOZART_STR("f-o"));
    testNodes[18] = String::build(vm, MOZART_STR("nil"));
    testNodes[19] = String::build(vm, MOZART_STR("#"));
    testNodes[20] = String::build(vm, MOZART_STR("\U0010ffff\U0010ffff"));

    testNodes[21] = buildList(vm, 0x40, 0x60);

    testNodes[22] = buildSharp(vm, 123, 456);
    testNodes[23] = buildSharp(vm,
                               MOZART_STR("f-o"),
                               MOZART_STR("nil"),
                               6);
    testNodes[24] = buildSharp(vm,
                               String::build(vm, MOZART_STR("\U00012345")),
                               -12345,
                               String::build(vm, MOZART_STR("-12345")),
                               buildSharp(vm, -1, -2, -3),
                               -4,
                               -5);

    testNodes[25] = SmallInt::build(vm, std::numeric_limits<nativeint>::min());

    auto s = intToString(std::numeric_limits<nativeint>::min());
    std::copy(s.cbegin(), s.cend(), std::back_inserter(minStr));
  }

  virtual void TearDown() {
  }
};

TEST_F(VirtualStringTest, IsVirtualString) {
  for (auto&& node : testNodes) {
    EXPECT_TRUE(ozIsVirtualString(vm, node));
  }
}

TEST_F(VirtualStringTest, ToString) {
  std::basic_string<nchar> results[] = {
    MOZART_STR("0"), MOZART_STR("4"), MOZART_STR("-4"), MOZART_STR("12300000"),
    MOZART_STR("-12300000"), MOZART_STR("3.125"), MOZART_STR("-3.125"),
    MOZART_STR("9.0e125"), MOZART_STR("-9.0e125"), MOZART_STR("9.0e-125"),
    MOZART_STR("-9.0e-125"), MOZART_STR("9.5678e125"), MOZART_STR("9.0"),
    MOZART_STR("f-o"), MOZART_STR(""), MOZART_STR(""),
    MOZART_STR("\U0010ffff\U0010ffff"),
    MOZART_STR("f-o"), MOZART_STR("nil"), MOZART_STR("#"),
    MOZART_STR("\U0010ffff\U0010ffff"), MOZART_STR("\u0040\u0060"),
    MOZART_STR("123456"), MOZART_STR("f-o6"),
    MOZART_STR("\U00012345-12345-12345-1-2-3-4-5"),
    minStr,
  };

  size_t i = 0;
  for (auto&& node : testNodes) {
    size_t bufSize = ozVSLengthForBuffer(vm, node);
    {
      std::basic_string<nchar> str;
      ozVSGet(vm, node, bufSize, str);
      EXPECT_EQ(results[i], str);
    }
    ++ i;
  }
}

TEST_F(VirtualStringTest, Length) {
  size_t results[] = {
    1, 1, 2, 8, 9,
    5, 6, 7, 8, 8, 9, 10, 3,
    3, 0, 0, 2,
    3, 3, 1, 2,
    2,
    6, 4, 23,
    minStr.length(),
  };

  size_t i = 0;
  for (auto&& node : testNodes) {
    EXPECT_EQ(results[i], ozVSLength(vm, node));
    ++ i;
  }
}

TEST_F(VirtualStringTest, IsNotVirtualString) {
  UnstableNode nodes[] = {
    OptName::build(vm),
    buildList(vm, 0xd800, 0xdc00),
    buildList(vm, 0x110000),
    buildList(vm, String::build(vm, MOZART_STR("foo"))),
    buildCons(vm, 0x40, vm->coreatoms.error),
    buildTuple(vm, vm->coreatoms.error, 2, 2),
    buildSharp(vm, 10, OptName::build(vm)),
    buildCons(vm, 0x40, String::build(vm, MOZART_STR("60000"))),
    build(vm, true),
    build(vm, unit),
    ByteString::build(vm, newLString(vm, ustr("A"), 1)),
  };

  for (auto& node : nodes) {
    EXPECT_FALSE(ozIsVirtualString(vm, node));
  }
}
