#include <limits.h>
#include <unistd.h>
#include <gtest/gtest.h>
#include "source.h"
static int something()
{
    function();
    return 0;
}
TEST(RRThread, CreateThread)
{
    EXPECT_EQ(0, something());
}
