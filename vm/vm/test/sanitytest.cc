#include "mozart.hh"
#include <gtest/gtest.h>
#include <gtest/gtest-spi.h>
#include "testutils.hh"

using namespace mozart;

TEST_F(MozartTest, Copyable_Sanity) {
  EXPECT_TRUE(Reference::type().isCopyable());
  EXPECT_TRUE(SmallInt::type().isCopyable());
  EXPECT_TRUE(Boolean::type().isCopyable());
  EXPECT_TRUE(Atom::type().isCopyable());
  EXPECT_TRUE(Unit::type().isCopyable());

  EXPECT_FALSE(OptVar::type().isCopyable());
  EXPECT_FALSE(Variable::type().isCopyable());
  EXPECT_FALSE(Tuple::type().isCopyable());
  EXPECT_FALSE(String::type().isCopyable());
  EXPECT_FALSE(Cell::type().isCopyable());
}

TEST_F(MozartTest, ExpectRaise_Sanity) {
  EXPECT_RAISE(MOZART_STR("foo"), raise(vm, MOZART_STR("foo"), 2));
  EXPECT_NONFATAL_FAILURE(
    EXPECT_RAISE(MOZART_STR("null"), (void) (0)), "");
  /*EXPECT_NONFATAL_FAILURE(
    EXPECT_RAISE(MOZART_STR("null"), raise(vm, MOZART_STR("foo"), 2)), "");*/
}
