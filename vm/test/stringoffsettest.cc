#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

static constexpr size_t testCount = 9;
static constexpr nativeint nodeCharIndices[testCount] = {0, 1, 3, 0, 1, 3, 0, 1, 3};

class StringOffsetTest : public MozartTest {
protected:
  UnstableNode strings[2];
  nativeint offsets[2][4];
  // ^ offset[P][Q] = compute the string offset of string P at the Q-th character.

  UnstableNode nodes[testCount];

  virtual void SetUp() {
    strings[0] = String::build(vm, MOZART_STR("\u12345\U00067890"));
    strings[1] = String::build(vm, MOZART_STR("\U00012345\u6789\U00100000"));

    #define LEN(x) std::char_traits<nchar>::length(MOZART_STR(x))

    offsets[0][0] = 0;
    offsets[0][1] = LEN("\u1234");
    offsets[0][2] = LEN("\u12345");
    offsets[0][3] = LEN("\u12345\U00067890");
    offsets[1][0] = 0;
    offsets[1][1] = LEN("\U00012345");
    offsets[1][2] = LEN("\U00012345\u6789");
    offsets[1][3] = LEN("\U00012345\u6789\U00100000");

    #undef LEN

    nodes[0] = StringOffset::build(vm, 0, strings[0]);
    nodes[1] = StringOffset::build(vm, offsets[0][1], strings[0]);
    nodes[2] = StringOffset::build(vm, offsets[0][3], strings[0]);

    nodes[3] = StringOffset::build(vm, 0, strings[1]);
    nodes[4] = StringOffset::build(vm, offsets[1][1], strings[1]);
    nodes[5] = StringOffset::build(vm, offsets[1][3], strings[1]);

    nodes[6] = SmallInt::build(vm, 0);
    nodes[7] = SmallInt::build(vm, 1);
    nodes[8] = SmallInt::build(vm, 3);
  }

};

TEST_F(StringOffsetTest, Compare) {
  // compRes[p][q] = nodes[p] cmp nodes[q].
  static constexpr int compRes[testCount][testCount] = {
    { 0, -1, -1,  0, -1, -1,  0, -1, -1},
    { 1,  0, -1,  1,  0, -1,  1,  0, -1},
    { 1,  1,  0,  1,  1,  0,  1,  1,  0},
    { 0, -1, -1,  0, -1, -1,  0, -1, -1},
    { 1,  0, -1,  1,  0, -1,  1,  0, -1},
    { 1,  1,  0,  1,  1,  0,  1,  1,  0},
    { 0, -1, -1,  0, -1, -1,  0, -1, -1},
    { 1,  0, -1,  1,  0, -1,  1,  0, -1},
    { 1,  1,  0,  1,  1,  0,  1,  1,  0},
  };

  for (size_t i = 0; i < testCount; ++ i) {
    for (size_t j = 0; j < testCount; ++ j) {
      SCOPED_TRACE("Comparing: " + std::to_string(i) + ", " + std::to_string(j));
      int res;
      if (EXPECT_PROCEED(Comparable(nodes[i]).compare(vm, nodes[j], res))) {
        EXPECT_EQ(compRes[i][j]<0, res<0);
        EXPECT_EQ(compRes[i][j]==0, res==0);
        EXPECT_EQ(compRes[i][j]>0, res>0);
      }
    }
  }
}

TEST_F(StringOffsetTest, ToStringOffset) {
  for (size_t i = 0; i < testCount; ++ i) {
    for (size_t j = 0; j < 2; ++ j) {
      SCOPED_TRACE("i = " + std::to_string(i) + ", j = " + std::to_string(j));
      nativeint res;
      if (EXPECT_PROCEED(StringOffsetLike(nodes[i]).toStringOffset(vm, strings[j], res))) {
        EXPECT_EQ(offsets[j][nodeCharIndices[i]], res);
      }
    }
  }

  nativeint dummy;
  auto four = SmallInt::build(vm, 4);
  auto minusOne = SmallInt::build(vm, -1);
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"),
         StringOffsetLike(four).toStringOffset(vm, strings[0], dummy));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"),
         StringOffsetLike(minusOne).toStringOffset(vm, strings[0], dummy));
}

TEST_F(StringOffsetTest, GetCharIndex) {
  for (size_t i = 0; i < testCount; ++ i) {
    nativeint res;
    if (EXPECT_PROCEED(StringOffsetLike(nodes[i]).getCharIndex(vm, res))) {
      EXPECT_EQ(nodeCharIndices[i], res);
    }
  }
}

TEST_F(StringOffsetTest, Advance) {
  for (size_t i = 0; i < testCount; ++ i) {
    for (nativeint delta = -1; delta <= 1; ++ delta) {
      for (size_t j = 0; j < 2; ++ j) {
        SCOPED_TRACE("i=" + std::to_string(i) +
                     ", delta=" + std::to_string(delta) +
                     ", j=" + std::to_string(j));
        UnstableNode res;
        if (EXPECT_PROCEED(StringOffsetLike(nodes[i]).stringOffsetAdvance(vm, strings[j], delta, res))) {
          nativeint expectedCharIndex = nodeCharIndices[i] + delta;
          if (expectedCharIndex < 0 || expectedCharIndex > 3) {
            if (EXPECT_IS<Boolean>(res))
              EXPECT_FALSE(RichNode(res).as<Boolean>().value());
          } else {
            nativeint actualCharIndex;
            if (EXPECT_PROCEED(StringOffsetLike(res).getCharIndex(vm, actualCharIndex)))
              EXPECT_EQ(expectedCharIndex, actualCharIndex);
          }
        }
      }
    }
  }
}



