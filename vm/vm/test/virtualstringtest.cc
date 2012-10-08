#include <tuple>
#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

static const unsigned char byteStringContent[] = "\x70\x80\x90";

std::string intToString(nativeint value) {
  std::stringstream stream;
  stream << value;
  return stream.str();
}

class VirtualStringTest : public MozartTest {
protected:
  UnstableNode testNodes[30];
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

    testNodes[17] = Boolean::build(vm, true);
    testNodes[18] = Boolean::build(vm, false);

    testNodes[19] = Unit::build(vm);

    testNodes[20] = String::build(vm, MOZART_STR("f-o"));
    testNodes[21] = String::build(vm, MOZART_STR("nil"));
    testNodes[22] = String::build(vm, MOZART_STR("#"));
    testNodes[23] = String::build(vm, MOZART_STR("\U0010ffff\U0010ffff"));

    testNodes[24] = buildCons(vm, 0x40,
                              buildCons(vm, 0x60, vm->coreatoms.nil));

    testNodes[25] = buildTuple(vm, vm->coreatoms.sharp, 123, 456);
    testNodes[26] = buildTuple(vm, vm->coreatoms.sharp,
                               MOZART_STR("f-o"),
                               MOZART_STR("nil"),
                               6);
    testNodes[27] = buildTuple(vm, vm->coreatoms.sharp,
                               String::build(vm, MOZART_STR("\U00012345")),
                               -12345,
                               String::build(vm, MOZART_STR("-12345")),
                               buildTuple(vm, vm->coreatoms.sharp, -1, -2, -3),
                               -4,
                               -5);

    testNodes[28] = SmallInt::build(vm, std::numeric_limits<nativeint>::min());
    testNodes[29] = ByteString::build(vm, byteStringContent);

    auto s = intToString(std::numeric_limits<nativeint>::min());
    std::copy(s.cbegin(), s.cend(), std::back_inserter(minStr));
  }

  virtual void TearDown() {
  }
};

TEST_F(VirtualStringTest, IsVirtualString) {
  for (auto&& node : testNodes) {
    EXPECT_TRUE(VirtualString(node).isVirtualString(vm));
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
    MOZART_STR("true"), MOZART_STR("false"), MOZART_STR("unit"),
    MOZART_STR("f-o"), MOZART_STR("nil"), MOZART_STR("#"),
    MOZART_STR("\U0010ffff\U0010ffff"), MOZART_STR("\u0040\u0060"),
    MOZART_STR("123456"), MOZART_STR("f-o6"),
    MOZART_STR("\U00012345-12345-12345-1-2-3-4-5"),
    minStr,
    MOZART_STR("\u0070\u0080\u0090"),
  };

  size_t i = 0;
  for (auto&& node : testNodes) {
    std::basic_ostringstream<nchar> stringStream;
    VirtualString(node).toString(vm, stringStream);
    EXPECT_EQ(results[i], stringStream.str());
    ++ i;
  }
}

TEST_F(VirtualStringTest, Length) {
  nativeint results[] = {
    1, 1, 2, 8, 9,
    5, 6, 7, 8, 8, 9, 10, 3,
    3, 0, 0, 2,
    4, 5,
    4,
    3, 3, 1, 2,
    2,
    6, 4, 23,
    (nativeint) minStr.length(),
    3,
  };

  size_t i = 0;
  for (auto&& node : testNodes) {
    EXPECT_EQ(results[i], VirtualString(node).vsLength(vm));
    ++ i;
  }
}

TEST_F(VirtualStringTest, IsNotVirtualString) {
  UnstableNode nodes[] = {
    OptName::build(vm),
    buildCons(vm, 0xd800, buildCons(vm, 0xdc00, vm->coreatoms.nil)),
    buildCons(vm, 0x110000, vm->coreatoms.nil),
    buildCons(vm, String::build(vm, MOZART_STR("foo")), vm->coreatoms.nil),
    buildCons(vm, 0x40, vm->coreatoms.error),
    buildTuple(vm, vm->coreatoms.error, 2, 2),
    buildTuple(vm, vm->coreatoms.sharp, 10, OptName::build(vm)),
    buildCons(vm, 0x40, buildCons(vm, 0x60000, vm->coreatoms.nil)),
    buildCons(vm, 0x40, String::build(vm, MOZART_STR("60000"))),
  };

  for (auto& node : nodes) {
    EXPECT_FALSE(VirtualString(node).isVirtualString(vm));
  }
}
