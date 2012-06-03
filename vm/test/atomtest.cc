#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"
#include <string>

using namespace mozart;

static inline bool nstreq(const nchar* a, const nchar* b) noexcept {
    size_t aLength = std::char_traits<nchar>::length(a);
    size_t bLength = std::char_traits<nchar>::length(b);
    if (aLength != bLength) return false;
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
    AtomTest() : virtualMachine(makeTestEnvironment()), vm(&virtualMachine) {}

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

    VirtualMachine virtualMachine;
    VM vm;
};

static const nchar* testVector[] = {
    NSTR("#"), NSTR("|"), NSTR("##"), NSTR("o_O"), NSTR("unit"),
    NSTR("###"), NSTR("unittest"), NSTR("o"), NSTR("\u0123"),
    NSTR("\u0123\u4567"), NSTR("\U00012345"), NSTR("o_O"),
    NSTR("\U00012346")
};

TEST_F(AtomTest, Sanity) {
    // Theis is to ensure nstreq & nstrcmp are implemented correctly.
    EXPECT_TRUE(nstreq(NSTR("foo"), NSTR("foo")));
    EXPECT_TRUE(nstreq(NSTR(""), NSTR("")));
    EXPECT_FALSE(nstreq(NSTR(""), NSTR("foo")));
    EXPECT_FALSE(nstreq(NSTR("1"), NSTR("123")));

    EXPECT_EQ(0, nstrcmp(NSTR("foo"), NSTR("foo")));
    EXPECT_EQ(0, nstrcmp(NSTR(""), NSTR("")));

    EXPECT_GT(nstrcmp(NSTR("foo"), NSTR("")), 0);
    EXPECT_GT(nstrcmp(NSTR("123"), NSTR("1")), 0);
    EXPECT_GT(nstrcmp(NSTR("bar"), NSTR("abc")), 0);
    EXPECT_GT(nstrcmp(NSTR("\u2234"), NSTR("2234")), 0);

    EXPECT_LT(nstrcmp(NSTR(""), NSTR("foo")), 0);
    EXPECT_LT(nstrcmp(NSTR("1"), NSTR("123")), 0);
    EXPECT_LT(nstrcmp(NSTR("abc"), NSTR("bar")), 0);
    EXPECT_LT(nstrcmp(NSTR("2234"), NSTR("\u2234")), 0);
}

TEST_F(AtomTest, Build) {
    for (const nchar* s : testVector) {
        UnstableNode node;
        node.make<Atom>(vm, s);
        EXPECT_EQ_ATOM(s, node);
    }
}

TEST_F(AtomTest, Equals) {
    for (const nchar* p : testVector) {
        UnstableNode pNode;
        pNode.make<Atom>(vm, p);

        for (const nchar* q : testVector) {
            UnstableNode qNode;
            qNode.make<Atom>(vm, q);

            bool areEqual = nstreq(p, q);
            EXPECT_EQ(areEqual, ValueEquatable(pNode).equals(vm, qNode));
            EXPECT_EQ(areEqual, ValueEquatable(qNode).equals(vm, pNode));
        }
    }
}

TEST_F(AtomTest, Compare) {
    for (const nchar* p : testVector) {
        UnstableNode pNode;
        pNode.make<Atom>(vm, p);

        for (const nchar* q : testVector) {
            UnstableNode qNode;
            qNode.make<Atom>(vm, q);

            int compareResult = nstrcmp(p, q);
            int pqCompareResult, qpCompareResult;
            EXPECT_TRUE(Comparable(pNode).compare(vm, qNode, pqCompareResult).isProceed());
            EXPECT_TRUE(Comparable(qNode).compare(vm, pNode, qpCompareResult).isProceed());
            EXPECT_EQ(compareResult>0, pqCompareResult>0);
            EXPECT_EQ(compareResult==0, pqCompareResult==0);
            EXPECT_EQ(compareResult<0, pqCompareResult<0);
            EXPECT_EQ(compareResult>0, qpCompareResult<0);
            EXPECT_EQ(compareResult==0, qpCompareResult==0);
            EXPECT_EQ(compareResult<0, qpCompareResult>0);
        }
    }
}

TEST_F(AtomTest, SomeCoreAtoms) {
    UnstableNode sharpNodeA = Atom::build(vm, NSTR("#"));
    UnstableNode sharpNodeB = Atom::build(vm, vm->coreatoms.sharp);
    EXPECT_TRUE(ValueEquatable(sharpNodeA).equals(vm, sharpNodeB));
}

