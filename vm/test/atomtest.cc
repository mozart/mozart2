#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"
#include <string>

using namespace mozart;

static inline bool nstreq(const nchar* a, const nchar* b) noexcept {
  size_t aLength = std::char_traits<nchar>::length(a);
  size_t bLength = std::char_traits<nchar>::length(b);
  if (aLength != bLength)
    return false;
  return std::char_traits<nchar>::compare(a, b, aLength) == 0;
}

static inline int nstrcmp(const nchar* a, const nchar* b) noexcept {
  size_t aLength = std::char_traits<nchar>::length(a);
  size_t bLength = std::char_traits<nchar>::length(b);
  size_t minLength = std::min(aLength, bLength);
  int compareRes = std::char_traits<nchar>::compare(a, b, minLength);
  if (compareRes == 0) {
    compareRes = aLength < bLength ? -1 : aLength > bLength ? 1 : 0;
  }
  return compareRes;
}

class AtomTest : public ::testing::Test {
protected:
  AtomTest(): environment(makeTestEnvironment()),
    virtualMachine(*environment), vm(&virtualMachine) {}

  virtual void SetUp() {}
  virtual void TearDown() {}

  void EXPECT_EQ_ATOM(const nchar* expected, RichNode actual) {
    EXPECT_EQ(Atom::type(), actual.type());
    if (Atom::type() == actual.type()) {
      size_t expected_length = std::char_traits<nchar>::length(expected);
      const AtomImpl* impl = actual.as<Atom>().value();
      EXPECT_EQ(expected_length, impl->length());
      EXPECT_TRUE(nstreq(expected, impl->contents()));
      // ^ can't use EXPECT_STREQ, as nchar may not be char.
    }
  }

  // The VM
  std::unique_ptr<VirtualMachineEnvironment> environment;
  VirtualMachine virtualMachine;
  VM vm;
};

static const nchar* testVector[] = {
  MOZART_STR("#"), MOZART_STR("|"), MOZART_STR("##"), MOZART_STR("o_O"),
  MOZART_STR("unit"), MOZART_STR("###"), MOZART_STR("unittest"),
  MOZART_STR("o"), MOZART_STR("\u0123"), MOZART_STR("\u0123\u4567"),
  MOZART_STR("\U00012345"), MOZART_STR("o_O"), MOZART_STR("\U00012346")
};

TEST_F(AtomTest, Sanity) {
  // This is to ensure nstreq & nstrcmp are implemented correctly.
  EXPECT_TRUE(nstreq(MOZART_STR("foo"), MOZART_STR("foo")));
  EXPECT_TRUE(nstreq(MOZART_STR(""), MOZART_STR("")));
  EXPECT_FALSE(nstreq(MOZART_STR(""), MOZART_STR("foo")));
  EXPECT_FALSE(nstreq(MOZART_STR("1"), MOZART_STR("123")));

  EXPECT_EQ(0, nstrcmp(MOZART_STR("foo"), MOZART_STR("foo")));
  EXPECT_EQ(0, nstrcmp(MOZART_STR(""), MOZART_STR("")));

  EXPECT_GT(nstrcmp(MOZART_STR("foo"), MOZART_STR("")), 0);
  EXPECT_GT(nstrcmp(MOZART_STR("123"), MOZART_STR("1")), 0);
  EXPECT_GT(nstrcmp(MOZART_STR("bar"), MOZART_STR("abc")), 0);
  EXPECT_GT(nstrcmp(MOZART_STR("\u2234"), MOZART_STR("2234")), 0);

  EXPECT_LT(nstrcmp(MOZART_STR(""), MOZART_STR("foo")), 0);
  EXPECT_LT(nstrcmp(MOZART_STR("1"), MOZART_STR("123")), 0);
  EXPECT_LT(nstrcmp(MOZART_STR("abc"), MOZART_STR("bar")), 0);
  EXPECT_LT(nstrcmp(MOZART_STR("2234"), MOZART_STR("\u2234")), 0);
}

TEST_F(AtomTest, Build) {
  for (const nchar* s : testVector) {
    UnstableNode node = Atom::build(vm, s);
    EXPECT_EQ_ATOM(s, node);
  }
}

TEST_F(AtomTest, Equals) {
  for (const nchar* p : testVector) {
    UnstableNode pNode = Atom::build(vm, p);

    for (const nchar* q : testVector) {
      UnstableNode qNode = Atom::build(vm, q);

      bool areEqual = nstreq(p, q);
      EXPECT_EQ(areEqual, ValueEquatable(pNode).equals(vm, qNode));
      EXPECT_EQ(areEqual, ValueEquatable(qNode).equals(vm, pNode));
    }
  }
}

TEST_F(AtomTest, Compare) {
  for (const nchar* p : testVector) {
    UnstableNode pNode = Atom::build(vm, p);

    for (const nchar* q : testVector) {
      UnstableNode qNode = Atom::build(vm, q);

      int compareResult = nstrcmp(p, q);
      int pqCompareResult, qpCompareResult;
      EXPECT_TRUE(Comparable(pNode).compare(
        vm, qNode, pqCompareResult).isProceed());
      EXPECT_TRUE(Comparable(qNode).compare(
        vm, pNode, qpCompareResult).isProceed());
      EXPECT_EQ(compareResult > 0, pqCompareResult > 0);
      EXPECT_EQ(compareResult == 0, pqCompareResult == 0);
      EXPECT_EQ(compareResult < 0, pqCompareResult < 0);
      EXPECT_EQ(compareResult > 0, qpCompareResult < 0);
      EXPECT_EQ(compareResult == 0, qpCompareResult == 0);
      EXPECT_EQ(compareResult < 0, qpCompareResult > 0);
    }
  }
}

TEST_F(AtomTest, SomeCoreAtoms) {
  UnstableNode sharpNodeA = Atom::build(vm, MOZART_STR("#"));
  UnstableNode sharpNodeB = Atom::build(vm, vm->coreatoms.sharp);
  EXPECT_TRUE(ValueEquatable(sharpNodeA).equals(vm, sharpNodeB));
}
