#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;
using namespace mozart::patternmatching;

class MatchTest : public MozartTest {};

TEST_F(MatchTest, MatchDslCons_Normal) {
    auto normalCons = buildCons(vm, 123, 456);
    nativeint a;
    nativeint b;

    OpResult result = OpResult::proceed();
    ASSERT_TRUE(matchesCons(vm, result, normalCons, capture(a), capture(b)));
    if (EXPECT_PROCEED(result)) {
        EXPECT_EQ(123, a);
        EXPECT_EQ(456, b);
    }
}

TEST_F(MatchTest, MatchDslCons_String) {
    auto normalCons = buildString(vm, NSTR("\U0001000423"));
    nativeint a;
    UnstableNode b;

    OpResult result = OpResult::proceed();
    ASSERT_TRUE(matchesCons(vm, result, normalCons, capture(a), capture(b)));
    if (EXPECT_PROCEED(result)) {
        EXPECT_EQ(0x10004, a);
        EXPECT_EQ_STRING(NSTR("23"), b);
    }
}

TEST_F(MatchTest, PatternMatchCons_Normal) {
    auto normalCons = buildCons(vm, 123, 456);
    auto pattern = buildCons(vm, PatMatCapture::build(vm, 0), PatMatCapture::build(vm, 1));

    UnstableNode nodes[2];
    StaticArray<UnstableNode> captures (nodes, 2);

    bool result;
    if (EXPECT_PROCEED(patternMatch(vm, normalCons, pattern, captures, result))) {
        EXPECT_TRUE(result);
        if (result) {
            EXPECT_EQ_INT(123, nodes[0]);
            EXPECT_EQ_INT(456, nodes[1]);
        }
    }
}

TEST_F(MatchTest, PatternMatchCons_String) {
    auto normalCons = buildString(vm, NSTR("\U0001000412"));
    auto pattern = buildCons(vm, PatMatCapture::build(vm, 0), PatMatCapture::build(vm, 1));

    UnstableNode nodes[2];
    StaticArray<UnstableNode> captures (nodes, 2);

    bool result;
    if (EXPECT_PROCEED(patternMatch(vm, normalCons, pattern, captures, result))) {
        EXPECT_TRUE(result);
        if (result) {
            EXPECT_EQ_INT(0x10004, nodes[0]);
            EXPECT_EQ_STRING(NSTR("12"), nodes[1]);
        }
    }
}



