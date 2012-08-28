#include "mozart.hh"
#include <gtest/gtest.h>
#include <gtest/gtest-spi.h>
#include "testutils.hh"

using namespace mozart;

TEST_F(MozartTest, ExpectRaise_Sanity) {
  EXPECT_RAISE(MOZART_STR("foo"), raise(vm, MOZART_STR("foo"), 2));
  EXPECT_NONFATAL_FAILURE(
    EXPECT_RAISE(MOZART_STR("null"), (void) (0)), "");
  /*EXPECT_NONFATAL_FAILURE(
    EXPECT_RAISE(MOZART_STR("null"), raise(vm, MOZART_STR("foo"), 2)), "");*/
}
