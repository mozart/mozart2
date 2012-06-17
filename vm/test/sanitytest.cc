#include "mozart.hh"
#include <gtest/gtest.h>
#include <gtest/gtest-spi.h>
#include "testutils.hh"

using namespace mozart;

TEST_F(MozartTest, ExpectRaise_Sanity) {
    EXPECT_RAISE(NSTR("illegalArity"), raiseIllegalArity(vm, 2, 4));
    EXPECT_NONFATAL_FAILURE(EXPECT_RAISE(NSTR("null"), OpResult::proceed()), "");
    EXPECT_NONFATAL_FAILURE(EXPECT_RAISE(NSTR("nullnullnull"), raiseIllegalArity(vm, 2, 4)), "");
}

