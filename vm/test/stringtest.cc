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

TEST_F(StringTest, CharAt) {
  UnstableNode b = String::build(vm, MOZART_STR("\U00012345\u6789"));

  UnstableNode minusOne = SmallInt::build(vm, -1);
  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode one = SmallInt::build(vm, 1);
  UnstableNode two = SmallInt::build(vm, 2);

  nativeint result;
  if (EXPECT_PROCEED(StringLike(b).stringCharAt(vm, zero, result)))
    EXPECT_EQ(0x12345, result);

  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringCharAt(vm, two, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringCharAt(vm, minusOne, result));

  if (EXPECT_PROCEED(StringLike(b).stringCharAt(vm, one, result)))
    EXPECT_EQ(0x6789, result);
}

TEST_F(StringTest, Append) {
  UnstableNode b1 = String::build(vm, MOZART_STR("abc"));
  UnstableNode b2 = String::build(vm, MOZART_STR("\U000def01"));
  UnstableNode b0 = String::build(vm, MOZART_STR(""));

  UnstableNode b12i;
  if (EXPECT_PROCEED(StringLike(b1).stringAppend(vm, b2, b12i))) {
    EXPECT_EQ_STRING(MOZART_STR("abc\U000def01"), b12i);
  }

  UnstableNode b11i;
  if (EXPECT_PROCEED(StringLike(b1).stringAppend(vm, b1, b11i))) {
    EXPECT_EQ_STRING(MOZART_STR("abcabc"), b11i);
  }

  UnstableNode b00i;
  if (EXPECT_PROCEED(StringLike(b0).stringAppend(vm, b0, b00i))) {
    EXPECT_EQ_STRING(MOZART_STR(""), b00i);
  }

  UnstableNode b10i;
  if (EXPECT_PROCEED(StringLike(b1).stringAppend(vm, b0, b10i))) {
    EXPECT_EQ_STRING(MOZART_STR("abc"), b10i);
  }
}

TEST_F(StringTest, SliceByCharCode) {
  UnstableNode b = String::build(vm, MOZART_STR("a\U00012345b\u6789c"));

  UnstableNode minusOne = SmallInt::build(vm, -1);
  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode two = SmallInt::build(vm, 2);
  UnstableNode three = SmallInt::build(vm, 3);
  UnstableNode four = SmallInt::build(vm, 4);
  UnstableNode five = SmallInt::build(vm, 5);
  UnstableNode six = SmallInt::build(vm, 6);


  UnstableNode result;

  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSlice(vm, minusOne, zero, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSlice(vm, five, six, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSlice(vm, three, two, result));

  if (EXPECT_PROCEED(StringLike(b).stringSlice(vm, two, four, result))) {
    EXPECT_EQ_STRING(MOZART_STR("b\u6789"), result);
  }

  if (EXPECT_PROCEED(StringLike(b).stringSlice(vm, zero, three, result))) {
    EXPECT_EQ_STRING(MOZART_STR("a\U00012345b"), result);
  }
}

TEST_F(StringTest, Compare) {
  UnstableNode nodes[] = {String::build(vm, MOZART_STR("\U000ffeed\uccbb")),
                          String::build(vm, MOZART_STR("\U000ffeed")),
                          String::build(vm, MOZART_STR("c"))};

  // results[p][q] == nodes[p] cmp nodes[q].
  int results[3][3] = {{ 0,  1,  1},
                       {-1,  0,  1},
                       {-1, -1,  0}};

  for (int i = 0; i < 3; ++ i) {
    for (int j = 0; j < 3; ++ j) {
      int res;
      if (EXPECT_PROCEED(Comparable(nodes[i]).compare(vm, nodes[j], res))) {
        EXPECT_EQ(results[i][j]<0, res<0);
        EXPECT_EQ(results[i][j]==0, res==0);
        EXPECT_EQ(results[i][j]>0, res>0);
      }
    }
  }
}

TEST_F(StringTest, StrChr) {
  UnstableNode b = String::build(vm, MOZART_STR("1\U000100023\U00010002\u00cc"));

  UnstableNode minusOne = SmallInt::build(vm, -1);
  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode one = SmallInt::build(vm, 1);
  UnstableNode two = SmallInt::build(vm, 2);
  UnstableNode four = SmallInt::build(vm, 4);
  UnstableNode six = SmallInt::build(vm, 6);
  UnstableNode char2 = SmallInt::build(vm, 0x10002);
  UnstableNode charInvalid = SmallInt::build(vm, 0xd800);

  UnstableNode result;
  nativeint index;
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSearch(vm, minusOne, char2, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSearch(vm, six, char2, result));

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, zero, char2, result))) {
  printf("1\n");
    if (EXPECT_PROCEED(StringOffsetLike(result).getCharIndex(vm, index))) {
      EXPECT_EQ(1, index);
    }
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, one, char2, result))) {
  std::cout << repr(vm, result) << std::endl;
    if (EXPECT_PROCEED(StringOffsetLike(result).getCharIndex(vm, index))) {
      EXPECT_EQ(1, index);
    }
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, two, char2, result))) {
  printf("1\n");
    if (EXPECT_PROCEED(StringOffsetLike(result).getCharIndex(vm, index))) {
      EXPECT_EQ(3, index);
    }
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, four, char2, result))) {
    if (EXPECT_IS<Boolean>(result)) {
      bool value;
      if (EXPECT_PROCEED(BooleanValue(result).boolValue(vm, value)))
        EXPECT_FALSE(value);
    }
  }

  EXPECT_RAISE(MOZART_STR("unicodeError"), StringLike(b).stringSearch(vm, zero, minusOne, result));
  EXPECT_RAISE(MOZART_STR("unicodeError"), StringLike(b).stringSearch(vm, zero, charInvalid, result));
}

TEST_F(StringTest, Search) {
  UnstableNode b = String::build(vm, MOZART_STR("123\U000a0000b\U000a0000b\U000a0000b\U000a0000b\U000a000d"));
  UnstableNode needle = String::build(vm, MOZART_STR("\U000a0000b\U000a0000"));

  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode three = SmallInt::build(vm, 3);
  UnstableNode four = SmallInt::build(vm, 4);
  UnstableNode six = SmallInt::build(vm, 6);
  UnstableNode eight = SmallInt::build(vm, 8);

  UnstableNode result;
  nativeint index;
  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, zero, needle, result))) {
    if (EXPECT_PROCEED(StringOffsetLike(result).getCharIndex(vm, index))) {
      EXPECT_EQ(3, index);
    }
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, three, needle, result))) {
    if (EXPECT_PROCEED(StringOffsetLike(result).getCharIndex(vm, index))) {
      EXPECT_EQ(3, index);
    }
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, four, needle, result))) {
    if (EXPECT_PROCEED(StringOffsetLike(result).getCharIndex(vm, index))) {
      EXPECT_EQ(5, index);
    }
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, six, needle, result))) {
    if (EXPECT_PROCEED(StringOffsetLike(result).getCharIndex(vm, index))) {
      EXPECT_EQ(7, index);
    }
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, eight, needle, result))) {
    if (EXPECT_IS<Boolean>(result)) {
      EXPECT_FALSE(RichNode(result).as<Boolean>().value());
    }
  }
}


