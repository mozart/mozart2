#include <tuple>
#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class StringTest : public MozartTest {};

static constexpr const nchar* stringTestVector[] = {
    NSTR("#"), NSTR("|"), NSTR("##"), NSTR("o_O"), NSTR("unit"),
    NSTR("###"), NSTR("unittest"), NSTR("o"), NSTR("\u0123"),
    NSTR("\u0123\u4567"), NSTR("\U00012345"), NSTR("\U00012346"), NSTR(""),
};



TEST_F(StringTest, Build) {
    for (const nchar* s : stringTestVector) {
        UnstableNode node = buildString(vm, s);
        EXPECT_EQ_STRING(s, node);
    }
}

TEST_F(StringTest, IsString) {
    UnstableNode node1 = Cons::build(vm, NSTR("foo"));
    bool isString;
    if (EXPECT_PROCEED(StringLike(node1).isString(vm, isString))) {
        EXPECT_TRUE(isString);
    }

    UnstableNode node2 = Atom::build(vm, NSTR("foo"));
    if (EXPECT_PROCEED(StringLike(node2).isString(vm, isString))) {
        EXPECT_FALSE(isString);
    }

    UnstableNode node3 = Atom::build(vm, vm->coreatoms.nil);
    if (EXPECT_PROCEED(StringLike(node3).isString(vm, isString))) {
        EXPECT_TRUE(isString);
    }
}

TEST_F(StringTest, IsString_Cons) {
    UnstableNode node1 = buildCons(vm, 1, 2);
    bool isString;
    if (EXPECT_PROCEED(StringLike(node1).isString(vm, isString))) {
        EXPECT_FALSE(isString);
    }

    UnstableNode node2 = buildCons(vm, 1, vm->coreatoms.nil);
    if (EXPECT_PROCEED(StringLike(node2).isString(vm, isString))) {
        EXPECT_TRUE(isString);
    }

    UnstableNode node3 = buildCons(vm, 1, buildCons(vm, 4, vm->coreatoms.nil));
    if (EXPECT_PROCEED(StringLike(node3).isString(vm, isString))) {
        EXPECT_TRUE(isString);
    }

    UnstableNode node4 = buildCons(vm, 1.0, buildCons(vm, 4, vm->coreatoms.nil));
    if (EXPECT_PROCEED(StringLike(node4).isString(vm, isString))) {
        EXPECT_FALSE(isString);
    }
}


TEST_F(StringTest, IsRecord) {
    for (const nchar* s : stringTestVector) {
        UnstableNode node = buildString(vm, s);
        bool res;
        if (EXPECT_PROCEED(RecordLike(node).isRecord(vm, res))) {
            EXPECT_TRUE(res);
        }
        if (EXPECT_PROCEED(RecordLike(node).isTuple(vm, res))) {
            EXPECT_TRUE(res);
        }
    }
}

TEST_F(StringTest, UnsafeGetString) {
    for (const nchar* s : stringTestVector) {
        UnstableNode stringNode = buildString(vm, s);
        LString<nchar> t;
        if (EXPECT_PROCEED(StringLike(stringNode).unsafeGetString(vm, t))) {
            EXPECT_EQ(LString<nchar>(s), t);
        }
    }
}

TEST_F(StringTest, NotEquals) {
    UnstableNode s = buildString(vm, NSTR("1"));
    UnstableNode t = buildString(vm, NSTR("2"));

    bool res;
    if (EXPECT_PROCEED(equals(vm, s, t, res)))
        EXPECT_FALSE(res);
}

TEST_F(StringTest, Equals) {
    for (const nchar* const s : stringTestVector) {
        UnstableNode sNode = buildString(vm, s);
        for (const nchar* const t : stringTestVector) {
            UnstableNode tNode = buildString(vm, t);

            auto tCopy = newLString(vm, makeLString(t));
            UnstableNode tNodeCopy = buildString(vm, std::move(tCopy));

            bool stEquals = (s == t);

            #define EXPECT_NODE_EQ(CHECKER, LEFT, RIGHT) \
                do { \
                    bool eqRes = false; \
                    if (EXPECT_PROCEED(equals(vm, LEFT, RIGHT, eqRes))) \
                        EXPECT_EQ(CHECKER, eqRes); \
                } while (0)

            EXPECT_NODE_EQ(stEquals, sNode, tNode);
            EXPECT_NODE_EQ(stEquals, tNode, sNode);
            EXPECT_NODE_EQ(stEquals, sNode, tNodeCopy);
            EXPECT_NODE_EQ(stEquals, tNodeCopy, sNode);
            EXPECT_NODE_EQ(true, tNodeCopy, tNode);
            EXPECT_NODE_EQ(true, tNode, tNodeCopy);

            #undef EXPECT_NODE_EQ
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

    UnstableNode nil = buildString(vm, NSTR(""));
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
        UnstableNode s = Cons::build(vm, std::get<0>(tup));
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
    UnstableNode s = Cons::build(vm, NSTR("foo"));

    UnstableNode label;
    size_t width;
    if (EXPECT_PROCEED(RecordLike(s).label(vm, label))) {
        EXPECT_EQ_ATOM(NSTR("|"), label);
    }
    if (EXPECT_PROCEED(RecordLike(s).width(vm, width))) {
        EXPECT_EQ(2u, width);
    }
}

