#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"
#include <string>

using namespace mozart;

class AtomTest : public MozartTest {};

static const nchar* testVector[] = {
  MOZART_STR("#"), MOZART_STR("|"), MOZART_STR("##"), MOZART_STR("o_O"),
  MOZART_STR("unit"), MOZART_STR("###"), MOZART_STR("unittest"),
  MOZART_STR("o"), MOZART_STR("\u0123"), MOZART_STR("\u0123\u4567"),
  MOZART_STR("\U00012345"), MOZART_STR("o_O"), MOZART_STR("\U00012346")
};

TEST_F(AtomTest, Build) {
  for (const nchar* s : testVector) {
    UnstableNode node = Atom::build(vm, s);
    EXPECT_EQ_ATOM(s, node);
  }
}

TEST_F(AtomTest, EqualsAndCompare) {
  for (const nchar* p : testVector) {
    UnstableNode pNode = Atom::build(vm, p);

    for (const nchar* q : testVector) {
      UnstableNode qNode = Atom::build(vm, q);

      int compareResult = compareByCodePoint(p, q);
      int pqCompareResult, qpCompareResult;
      EXPECT_PROCEED(Comparable(pNode).compare(vm, qNode, pqCompareResult));
      EXPECT_PROCEED(Comparable(qNode).compare(vm, pNode, qpCompareResult));

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
  UnstableNode sharpNodeA = Atom::build(vm, MOZART_STR("#"));
  UnstableNode sharpNodeB = Atom::build(vm, vm->coreatoms.sharp);
  EXPECT_TRUE(ValueEquatable(sharpNodeA).equals(vm, sharpNodeB));
}
