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
