#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"
#include <string>

using namespace mozart;

class AtomTest : public MozartTest {};

static const char* testVector[] = {
  "#", "|", "##", "o_O",
  "unit", "###", "unittest",
  "o", u8"\u0123", u8"\u0123\u4567",
  u8"\U00012345", "o_O", u8"\U00012346"
};

TEST_F(AtomTest, Build) {
  for (const char* s : testVector) {
    UnstableNode node = Atom::build(vm, s);
    EXPECT_EQ_ATOM(makeLString(s), node);
  }
}

TEST_F(AtomTest, Repr) {
  // Regular, non quoted atoms
  EXPECT_REPR_EQ("foo", build(vm, "foo"));
  EXPECT_REPR_EQ("foo_bar", build(vm, "foo_bar"));
  EXPECT_REPR_EQ("fooBar", build(vm, "fooBar"));
  EXPECT_REPR_EQ("foo2", build(vm, "foo2"));
  EXPECT_REPR_EQ("fABd2_sd", build(vm, "fABd2_sd"));
  EXPECT_REPR_EQ("nil", build(vm, "nil"));

  // Empty
  EXPECT_REPR_EQ("''", build(vm, ""));

  // Keywords
  EXPECT_REPR_EQ("'true'", build(vm, "true"));
  EXPECT_REPR_EQ("'unit'", build(vm, "unit"));
  EXPECT_REPR_EQ("'if'", build(vm, "if"));

  // Start with an uppercase
  EXPECT_REPR_EQ("'Bar'", build(vm, "Bar"));

  // Control characters
  EXPECT_REPR_EQ("'\\n'", build(vm, "\n"));
  EXPECT_REPR_EQ("'\\x02'", build(vm, u8"\u0002"));
  EXPECT_REPR_EQ("'\\x1A'", build(vm, u8"\u001A"));
  EXPECT_REPR_EQ("'\\x7F'", build(vm, u8"\u007F"));
  EXPECT_REPR_EQ("'\\x80'", build(vm, u8"\u0080"));
  EXPECT_REPR_EQ("'\\x9A'", build(vm, u8"\u009A"));

  // Non-ASCII but regular Unicode characters.
  EXPECT_REPR_EQ(u8"'\u00A0'", build(vm, u8"\u00A0"));
  EXPECT_REPR_EQ(u8"'\u03C0'", build(vm, u8"\u03C0"));
}

TEST_F(AtomTest, EqualsAndCompare) {
  for (const char* p : testVector) {
    UnstableNode pNode = Atom::build(vm, p);

    for (const char* q : testVector) {
      UnstableNode qNode = Atom::build(vm, q);

      int compareResult = compareByCodePoint(p, q);
      int pqCompareResult, qpCompareResult;
      pqCompareResult = Comparable(pNode).compare(vm, qNode);
      qpCompareResult = Comparable(qNode).compare(vm, pNode);

      EXPECT_EQ(compareResult > 0, pqCompareResult > 0);
      EXPECT_EQ(compareResult == 0, pqCompareResult == 0);
      EXPECT_EQ(compareResult < 0, pqCompareResult < 0);
      EXPECT_EQ(compareResult > 0, qpCompareResult < 0);
      EXPECT_EQ(compareResult == 0, qpCompareResult == 0);
      EXPECT_EQ(compareResult < 0, qpCompareResult > 0);

      EXPECT_EQ(compareResult == 0, ValueEquatable(pNode).equals(vm, qNode));
      EXPECT_EQ(compareResult == 0, ValueEquatable(qNode).equals(vm, pNode));
    }
  }
}

TEST_F(AtomTest, SomeCoreAtoms) {
  UnstableNode sharpNodeA = Atom::build(vm, "#");
  UnstableNode sharpNodeB = Atom::build(vm, vm->coreatoms.sharp);
  EXPECT_TRUE(ValueEquatable(sharpNodeA).equals(vm, sharpNodeB));
}
