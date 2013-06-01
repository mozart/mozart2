#include <tuple>
#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class StringTest : public MozartTest {};

static const char* stringTestVector[] = {
  "#", "|", "##", "o_O",
  "unit", "###", "unittest",
  "o", u8"\u0123", u8"\u0123\u4567",
  u8"\U00012345", u8"\U00012346", "",
};

TEST_F(StringTest, Build) {
  for (const char* s : stringTestVector) {
    UnstableNode node = String::build(vm, newLString(vm, s));
    EXPECT_EQ_STRING(makeLString(s), node);
  }
}

TEST_F(StringTest, IsString) {
  UnstableNode node1 = String::build(vm, "foo");
  EXPECT_TRUE(StringLike(node1).isString(vm));

  UnstableNode node2 = Atom::build(vm, "foo");
  EXPECT_FALSE(StringLike(node2).isString(vm));
}

TEST_F(StringTest, NotIsRecord) {
  for (const char* s : stringTestVector) {
    UnstableNode node = String::build(vm, newLString(vm, s));
    EXPECT_FALSE(RecordLike(node).isRecord(vm));
    EXPECT_FALSE(RecordLike(node).isTuple(vm));
  }
}

TEST_F(StringTest, Equals) {
  for (const char* s : stringTestVector) {
    UnstableNode sNode = String::build(vm, newLString(vm, s));
    for (const char* t : stringTestVector) {
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
  UnstableNode b = String::build(vm, u8"\U00012345\u6789");

  UnstableNode minusOne = SmallInt::build(vm, -1);
  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode one = SmallInt::build(vm, 1);
  UnstableNode two = SmallInt::build(vm, 2);

  EXPECT_EQ(0x12345, StringLike(b).stringCharAt(vm, zero));

  EXPECT_RAISE("indexOutOfBounds",
               StringLike(b).stringCharAt(vm, two));
  EXPECT_RAISE("indexOutOfBounds",
               StringLike(b).stringCharAt(vm, minusOne));

  EXPECT_EQ(0x6789, StringLike(b).stringCharAt(vm, one));
}

TEST_F(StringTest, Append) {
  UnstableNode b1 = String::build(vm, "abc");
  UnstableNode b2 = String::build(vm, u8"\U000def01");
  UnstableNode b0 = String::build(vm, "");

  UnstableNode b12i = StringLike(b1).stringAppend(vm, b2);
  EXPECT_EQ_STRING(u8"abc\U000def01", b12i);

  UnstableNode b11i = StringLike(b1).stringAppend(vm, b1);
  EXPECT_EQ_STRING("abcabc", b11i);

  UnstableNode b00i = StringLike(b0).stringAppend(vm, b0);
  EXPECT_EQ_STRING("", b00i);

  UnstableNode b10i = StringLike(b1).stringAppend(vm, b0);
  EXPECT_EQ_STRING("abc", b10i);
}

TEST_F(StringTest, SliceByCharCode) {
  UnstableNode b = String::build(vm, u8"a\U00012345b\u6789c");

  UnstableNode minusOne = SmallInt::build(vm, -1);
  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode two = SmallInt::build(vm, 2);
  UnstableNode three = SmallInt::build(vm, 3);
  UnstableNode four = SmallInt::build(vm, 4);
  UnstableNode five = SmallInt::build(vm, 5);
  UnstableNode six = SmallInt::build(vm, 6);


  UnstableNode result;

  EXPECT_RAISE("indexOutOfBounds",
               StringLike(b).stringSlice(vm, minusOne, zero));
  EXPECT_RAISE("indexOutOfBounds",
               StringLike(b).stringSlice(vm, five, six));
  EXPECT_RAISE("indexOutOfBounds",
               StringLike(b).stringSlice(vm, three, two));

  EXPECT_EQ_STRING(u8"b\u6789",
                   StringLike(b).stringSlice(vm, two, four));

  EXPECT_EQ_STRING(u8"a\U00012345b",
                   StringLike(b).stringSlice(vm, zero, three));
}

TEST_F(StringTest, Compare) {
  UnstableNode nodes[] = {String::build(vm, u8"\U000ffeed\uccbb"),
                          String::build(vm, u8"\U000ffeed"),
                          String::build(vm, "c")};

  // results[p][q] == nodes[p] cmp nodes[q].
  int results[3][3] = {{ 0,  1,  1},
                       {-1,  0,  1},
                       {-1, -1,  0}};

  for (int i = 0; i < 3; ++ i) {
    for (int j = 0; j < 3; ++ j) {
      int res = Comparable(nodes[i]).compare(vm, nodes[j]);
      EXPECT_EQ(results[i][j]<0, res<0);
      EXPECT_EQ(results[i][j]==0, res==0);
      EXPECT_EQ(results[i][j]>0, res>0);
    }
  }
}

TEST_F(StringTest, StrChr) {
  UnstableNode b = String::build(vm, u8"1\U000100023\U00010002\u00cc");

  UnstableNode minusOne = SmallInt::build(vm, -1);
  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode one = SmallInt::build(vm, 1);
  UnstableNode two = SmallInt::build(vm, 2);
  UnstableNode four = SmallInt::build(vm, 4);
  UnstableNode six = SmallInt::build(vm, 6);
  UnstableNode char2 = SmallInt::build(vm, 0x10002);
  UnstableNode charInvalid = SmallInt::build(vm, 0xd800);

  UnstableNode begin, end;

  EXPECT_RAISE("indexOutOfBounds",
               StringLike(b).stringSearch(vm, minusOne, char2, begin, end));
  EXPECT_RAISE("indexOutOfBounds",
               StringLike(b).stringSearch(vm, six, char2, begin, end));

  StringLike(b).stringSearch(vm, zero, char2, begin, end);
  EXPECT_EQ_INT(1, begin);
  EXPECT_EQ_INT(2, end);

  StringLike(b).stringSearch(vm, one, char2, begin, end);
  EXPECT_EQ_INT(1, begin);
  EXPECT_EQ_INT(2, end);

  StringLike(b).stringSearch(vm, two, char2, begin, end);
  EXPECT_EQ_INT(3, begin);
  EXPECT_EQ_INT(4, end);

  StringLike(b).stringSearch(vm, four, char2, begin, end);
  for (auto node : {&begin, &end}) {
    EXPECT_TRUE(patternmatching::matches(vm, *node, false));
  }

  EXPECT_RAISE("unicodeError",
               StringLike(b).stringSearch(vm, zero, minusOne, begin, end));
  EXPECT_RAISE("unicodeError",
               StringLike(b).stringSearch(vm, zero, charInvalid, begin, end));
}

TEST_F(StringTest, Search) {
  UnstableNode b = String::build(
    vm, u8"123\U000a0000b\U000a0000b\U000a0000b\U000a0000b\U000a000d");
  UnstableNode needle = String::build(
    vm, u8"\U000a0000b\U000a0000");

  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode three = SmallInt::build(vm, 3);
  UnstableNode four = SmallInt::build(vm, 4);
  UnstableNode six = SmallInt::build(vm, 6);
  UnstableNode eight = SmallInt::build(vm, 8);

  UnstableNode begin, end;

  StringLike(b).stringSearch(vm, zero, needle, begin, end);
  EXPECT_EQ_INT(3, begin);
  EXPECT_EQ_INT(6, end);

  StringLike(b).stringSearch(vm, three, needle, begin, end);
  EXPECT_EQ_INT(3, begin);
  EXPECT_EQ_INT(6, end);

  StringLike(b).stringSearch(vm, four, needle, begin, end);
  EXPECT_EQ_INT(5, begin);
  EXPECT_EQ_INT(8, end);

  StringLike(b).stringSearch(vm, six, needle, begin, end);
  EXPECT_EQ_INT(7, begin);
  EXPECT_EQ_INT(10, end);

  StringLike(b).stringSearch(vm, eight, needle, begin, end);
  if (EXPECT_IS<Boolean>(begin)) {
    EXPECT_FALSE(RichNode(begin).as<Boolean>().value());
  }
  if (EXPECT_IS<Boolean>(end)) {
    EXPECT_FALSE(RichNode(end).as<Boolean>().value());
  }
}
