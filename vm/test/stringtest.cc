#include <tuple>
#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class StringTest : public MozartTest {};

static const nchar* stringTestVector[] = {
    MOZART_STR("#"), MOZART_STR("|"), MOZART_STR("##"), MOZART_STR("o_O"), MOZART_STR("unit"),
    MOZART_STR("###"), MOZART_STR("unittest"), MOZART_STR("o"), MOZART_STR("\u0123"),
    MOZART_STR("\u0123\u4567"), MOZART_STR("\U00012345"), MOZART_STR("\U00012346"), MOZART_STR(""),
};



TEST_F(StringTest, Build) {
    for (const nchar* s : stringTestVector) {
        UnstableNode node;
        node.make<String>(vm, newLString(vm, s));
        EXPECT_EQ_STRING(makeLString(s), node);
    }
}

TEST_F(StringTest, IsString) {
    UnstableNode node1 = String::build(vm, MOZART_STR("foo"));
    bool isString;
    if (EXPECT_PROCEED(StringLike(node1).isString(vm, isString))) {
        EXPECT_TRUE(isString);
    }

    UnstableNode node2 = Atom::build(vm, MOZART_STR("foo"));
    if (EXPECT_PROCEED(StringLike(node2).isString(vm, isString))) {
        EXPECT_FALSE(isString);
    }
}

TEST_F(StringTest, IsRecord) {
    for (const nchar* s : stringTestVector) {
        UnstableNode node;
        node.make<String>(vm, newLString(vm, s));
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
        UnstableNode stringNode = String::build(vm, newLString(vm, s));
        UnstableNode atomNode;
        if (EXPECT_PROCEED(StringLike(stringNode).toAtom(vm, atomNode))) {
            EXPECT_EQ_ATOM(makeLString(s), atomNode);
        }
    }
}

TEST_F(StringTest, Equals) {
    for (const nchar* s : stringTestVector) {
        UnstableNode sNode = String::build(vm, newLString(vm, s));
        for (const nchar* t : stringTestVector) {
            UnstableNode tNode = String::build(vm, newLString(vm, t));

            UnstableNode tNodeCopy = String::build(vm, newLString(vm, t));

            bool stEquals = (s == t);

            EXPECT_EQ(stEquals, ValueEquatable(sNode).equals(vm, tNode));
            EXPECT_EQ(stEquals, ValueEquatable(tNode).equals(vm, sNode));
            EXPECT_EQ(stEquals, ValueEquatable(sNode).equals(vm, tNodeCopy));
            EXPECT_EQ(stEquals, ValueEquatable(tNodeCopy).equals(vm, sNode));
            EXPECT_TRUE(ValueEquatable(tNodeCopy).equals(vm, tNode));
            EXPECT_TRUE(ValueEquatable(tNode).equals(vm, tNodeCopy));
        }
    }
}

TEST_F(StringTest, Dottable) {
    static const std::tuple<const nchar*, char32_t, const nchar*> testVector[] = {
        std::make_tuple(MOZART_STR("foo"), U'f', MOZART_STR("oo")),
        std::make_tuple(MOZART_STR("\U00010000x"), U'\U00010000', MOZART_STR("x")),
        std::make_tuple(MOZART_STR("p"), 'p', MOZART_STR("")),
        std::make_tuple(MOZART_STR("\U00010000"), U'\U00010000', MOZART_STR("")),
    };

    UnstableNode one = SmallInt::build(vm, 1);
    UnstableNode two = SmallInt::build(vm, 2);
    UnstableNode oneAtom = Atom::build(vm, MOZART_STR("1"));
    bool hasHead, hasTail;

    UnstableNode nil = String::build(vm, MOZART_STR(""));
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
    EXPECT_RAISE(MOZART_STR("illegalFieldSelection"), Dottable(nil).dot(vm, one, dummy));
    EXPECT_RAISE(MOZART_STR("illegalFieldSelection"), Dottable(nil).dot(vm, oneAtom, dummy));

    for (auto& tup : testVector) {
        UnstableNode s = String::build(vm, newLString(vm, std::get<0>(tup)));
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
            EXPECT_EQ_STRING(makeLString(std::get<2>(tup)), tail);
        }

        if (EXPECT_PROCEED(Dottable(s).hasFeature(vm, oneAtom, hasHead))) {
            EXPECT_FALSE(hasHead);
        }
        EXPECT_RAISE(MOZART_STR("illegalFieldSelection"), Dottable(s).dot(vm, oneAtom, dummy));
    }
}

TEST_F(StringTest, RecordLike_normal) {
    UnstableNode s = String::build(vm, MOZART_STR("foo"));

    UnstableNode label;
    size_t width;
    if (EXPECT_PROCEED(RecordLike(s).label(vm, label))) {
        EXPECT_EQ_ATOM(MOZART_STR("|"), label);
    }
    if (EXPECT_PROCEED(RecordLike(s).width(vm, width))) {
        EXPECT_EQ(2u, width);
    }
}

TEST_F(StringTest, RecordLike_empty) {
    UnstableNode s = String::build(vm, MOZART_STR(""));

    UnstableNode label;
    size_t width;
    if (EXPECT_PROCEED(RecordLike(s).label(vm, label))) {
        EXPECT_EQ_ATOM(MOZART_STR("nil"), label);
    }
    if (EXPECT_PROCEED(RecordLike(s).width(vm, width))) {
        EXPECT_EQ(0u, width);
    }
}

