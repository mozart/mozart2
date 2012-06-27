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

TEST_F(StringTest, NotIsRecord) {
    for (const nchar* s : stringTestVector) {
        UnstableNode node;
        node.make<String>(vm, newLString(vm, s));
        bool res;
        if (EXPECT_PROCEED(RecordLike(node).isRecord(vm, res))) {
            EXPECT_FALSE(res);
        }
        if (EXPECT_PROCEED(RecordLike(node).isTuple(vm, res))) {
            EXPECT_FALSE(res);
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


