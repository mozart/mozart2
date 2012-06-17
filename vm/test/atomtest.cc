#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"
#include <string>

using namespace mozart;

class AtomTest : public MozartTest {};

static const nchar* testVector[] = {
    NSTR("#"), NSTR("|"), NSTR("##"), NSTR("o_O"), NSTR("unit"),
    NSTR("###"), NSTR("unittest"), NSTR("o"), NSTR("\u0123"),
    NSTR("\u0123\u4567"), NSTR("\U00012345"), NSTR("o_O"),
    NSTR("\U00012346")
};

TEST_F(AtomTest, Build) {
    for (const nchar* s : testVector) {
        UnstableNode node;
        node.make<Atom>(vm, s);
        EXPECT_EQ_ATOM(s, node);
    }
}

TEST_F(AtomTest, EqualsAndCompare) {
    for (const nchar* p : testVector) {
        UnstableNode pNode;
        pNode.make<Atom>(vm, p);

        for (const nchar* q : testVector) {
            UnstableNode qNode;
            qNode.make<Atom>(vm, q);

            int compareResult = compareByCodePoint(p, q);
            int pqCompareResult, qpCompareResult;
            EXPECT_PROCEED(Comparable(pNode).compare(vm, qNode, pqCompareResult));
            EXPECT_PROCEED(Comparable(qNode).compare(vm, pNode, qpCompareResult));
            EXPECT_EQ(compareResult>0, pqCompareResult>0);
            EXPECT_EQ(compareResult==0, pqCompareResult==0);
            EXPECT_EQ(compareResult<0, pqCompareResult<0);
            EXPECT_EQ(compareResult>0, qpCompareResult<0);
            EXPECT_EQ(compareResult==0, qpCompareResult==0);
            EXPECT_EQ(compareResult<0, qpCompareResult>0);

            EXPECT_EQ(compareResult==0, ValueEquatable(pNode).equals(vm, qNode));
            EXPECT_EQ(compareResult==0, ValueEquatable(qNode).equals(vm, pNode));
        }
    }
}

TEST_F(AtomTest, SomeCoreAtoms) {
    UnstableNode sharpNodeA = Atom::build(vm, NSTR("#"));
    UnstableNode sharpNodeB = Atom::build(vm, vm->coreatoms.sharp);
    EXPECT_TRUE(ValueEquatable(sharpNodeA).equals(vm, sharpNodeB));
}

