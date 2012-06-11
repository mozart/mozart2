#include <tuple>
#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class StringTest : public MozartTest {};

static const nchar* stringTestVector[] = {
    NSTR("#"), NSTR("|"), NSTR("##"), NSTR("o_O"), NSTR("unit"),
    NSTR("###"), NSTR("unittest"), NSTR("o"), NSTR("\u0123"),
    NSTR("\u0123\u4567"), NSTR("\U00012345"), NSTR("\U00012346"), NSTR(""),
};



TEST_F(StringTest, Build) {
    for (const nchar* s : stringTestVector) {
        UnstableNode node;
        node.make<String>(vm, s);
        EXPECT_EQ_STRING(s, node);
    }
}

TEST_F(StringTest, IsString) {
    UnstableNode node1 = String::build(vm, NSTR("foo"));
    bool isString;
    if (EXPECT_PROCEED(StringLike(node1).isString(vm, isString))) {
        EXPECT_TRUE(isString);
    }

    UnstableNode node2 = Atom::build(vm, NSTR("foo"));
    if (EXPECT_PROCEED(StringLike(node2).isString(vm, isString))) {
        EXPECT_FALSE(isString);
    }
}

TEST_F(StringTest, IsRecord) {
    for (const nchar* s : stringTestVector) {
        UnstableNode node;
        node.make<String>(vm, s);
        bool res;
        if (EXPECT_PROCEED(RecordLike(node).isRecord(vm, res))) {
            EXPECT_TRUE(res);
        }
        if (EXPECT_PROCEED(RecordLike(node).isTuple(vm, res))) {
            EXPECT_TRUE(res);
        }
    }
}

TEST_F(StringTest, ToAtom) {
    for (const nchar* s : stringTestVector) {
        UnstableNode stringNode = String::build(vm, s);
        UnstableNode atomNode;
        if (EXPECT_PROCEED(StringLike(stringNode).toAtom(vm, atomNode))) {
            EXPECT_EQ_ATOM(s, atomNode);
        }
    }
}

TEST_F(StringTest, Equals) {
    for (const nchar* s : stringTestVector) {
        UnstableNode sNode = String::build(vm, s);
        for (const nchar* t : stringTestVector) {
            UnstableNode tNode = String::build(vm, t);

            LString<nchar> tCopy (vm, t);
            UnstableNode tNodeCopy = String::build(vm, tCopy);

            bool stEquals = (s == t);

            EXPECT_EQ(stEquals, ValueEquatable(sNode).equals(vm, tNode));
            EXPECT_EQ(stEquals, ValueEquatable(tNode).equals(vm, sNode));
            EXPECT_EQ(stEquals, ValueEquatable(sNode).equals(vm, tNodeCopy));
            EXPECT_EQ(stEquals, ValueEquatable(tNodeCopy).equals(vm, sNode));
            EXPECT_TRUE(ValueEquatable(tNodeCopy).equals(vm, tNode));
            EXPECT_TRUE(ValueEquatable(tNode).equals(vm, tNodeCopy));

            tCopy.free(vm);
        }
    }
}

TEST_F(StringTest, Dottable) {
    static const std::tuple<const nchar*, char32_t, const nchar*> testVector[] = {
        std::make_tuple(NSTR("foo"), U'f', NSTR("oo")),
        std::make_tuple(NSTR("\U00010000x"), U'\U00010000', NSTR("x")),
        std::make_tuple(NSTR("p"), 'p', NSTR("")),
        std::make_tuple(NSTR("\U00010000"), U'\U00010000', NSTR("")),
    };

    UnstableNode one = SmallInt::build(vm, 1);
    UnstableNode two = SmallInt::build(vm, 2);
    UnstableNode oneAtom = Atom::build(vm, NSTR("1"));
    bool hasHead, hasTail;

    UnstableNode nil = String::build(vm, NSTR(""));
    UnstableNode dummy;

    if (EXPECT_PROCEED(Dottable(nil).hasFeature(vm, one, hasHead))) {
        EXPECT_FALSE(hasHead);
    }
    if (EXPECT_PROCEED(Dottable(nil).hasFeature(vm, two, hasTail))) {
        EXPECT_FALSE(hasTail);
    }
    if (EXPECT_PROCEED(Dottable(nil).hasFeature(vm, oneAtom, hasTail))) {
        EXPECT_FALSE(hasTail);
    }
    EXPECT_RAISE(NSTR("illegalFieldSelection"), Dottable(nil).dot(vm, one, dummy));
    EXPECT_RAISE(NSTR("illegalFieldSelection"), Dottable(nil).dot(vm, oneAtom, dummy));

    for (auto& tup : testVector) {
        UnstableNode s = String::build(vm, std::get<0>(tup));
        UnstableNode head, tail;

        if (EXPECT_PROCEED(Dottable(s).hasFeature(vm, one, hasHead))) {
            EXPECT_TRUE(hasHead);
        }
        if (EXPECT_PROCEED(Dottable(s).hasFeature(vm, two, hasTail))) {
            EXPECT_TRUE(hasTail);
        }

        if (EXPECT_PROCEED(Dottable(s).dot(vm, one, head))) {
            EXPECT_EQ_INT(std::get<1>(tup), head);
        }
        if (EXPECT_PROCEED(Dottable(s).dot(vm, two, tail))) {
            EXPECT_EQ_STRING(std::get<2>(tup), tail);
        }

        if (EXPECT_PROCEED(Dottable(s).hasFeature(vm, oneAtom, hasHead))) {
            EXPECT_FALSE(hasHead);
        }
        EXPECT_RAISE(NSTR("illegalFieldSelection"), Dottable(s).dot(vm, oneAtom, dummy));
    }
}

TEST_F(StringTest, RecordLike_normal) {
    UnstableNode s = String::build(vm, NSTR("foo"));

    UnstableNode label;
    size_t width;
    if (EXPECT_PROCEED(RecordLike(s).label(vm, label))) {
        EXPECT_EQ_ATOM(NSTR("|"), label);
    }
    if (EXPECT_PROCEED(RecordLike(s).width(vm, width))) {
        EXPECT_EQ(2u, width);
    }
}

TEST_F(StringTest, RecordLike_empty) {
    UnstableNode s = String::build(vm, NSTR(""));

    UnstableNode label;
    size_t width;
    if (EXPECT_PROCEED(RecordLike(s).label(vm, label))) {
        EXPECT_EQ_ATOM(NSTR("nil"), label);
    }
    if (EXPECT_PROCEED(RecordLike(s).width(vm, width))) {
        EXPECT_EQ(0u, width);
    }
}

