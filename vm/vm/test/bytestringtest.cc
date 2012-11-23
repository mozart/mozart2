#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class ByteStringTest : public MozartTest {};

TEST_F(ByteStringTest, Get) {
  static const unsigned char a[] = "\1\xf3";
  UnstableNode b = ByteString::build(vm, a);

  UnstableNode minusOne = SmallInt::build(vm, -1);
  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode one = SmallInt::build(vm, 1);
  UnstableNode two = SmallInt::build(vm, 2);

  EXPECT_EQ(1, StringLike(b).stringCharAt(vm, zero));

  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"),
               StringLike(b).stringCharAt(vm, two));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"),
               StringLike(b).stringCharAt(vm, minusOne));

  EXPECT_EQ(0xf3, StringLike(b).stringCharAt(vm, one));
}

TEST_F(ByteStringTest, Append) {
  static const unsigned char a1[] = "abc", a2[] = "\xde\xf0", a0[] = "";
  static const unsigned char a12[] = "abc\xde\xf0", a11[] = "abcabc";
  UnstableNode b1 = ByteString::build(vm, a1);
  UnstableNode b2 = ByteString::build(vm, a2);
  UnstableNode b0 = ByteString::build(vm, a0);

  UnstableNode b12i = StringLike(b1).stringAppend(vm, b2);
  RichNode b12 = b12i;
  if (EXPECT_IS<ByteString>(b12)) {
    EXPECT_EQ(a12, b12.as<ByteString>().value());
  }

  UnstableNode b11i = StringLike(b1).stringAppend(vm, b1);
  RichNode b11 = b11i;
  if (EXPECT_IS<ByteString>(b11)) {
    EXPECT_EQ(a11, b11.as<ByteString>().value());
  }

  UnstableNode b00i = StringLike(b0).stringAppend(vm, b0);
  RichNode b00 = b00i;
  if (EXPECT_IS<ByteString>(b00)) {
    EXPECT_EQ(a0, b00.as<ByteString>().value());
  }

  UnstableNode b10i = StringLike(b1).stringAppend(vm, b0);
  RichNode b10 = b10i;
  if (EXPECT_IS<ByteString>(b10)) {
    EXPECT_EQ(a1, b10.as<ByteString>().value());
  }
}

TEST_F(ByteStringTest, Decode) {
  static const unsigned char a[] = "\xc3\x80\x01\x00\xc4\xbf\x10\x00";
  UnstableNode bNode = ByteString::build(vm, newLString(a, 8));
  auto b = RichNode(bNode).as<ByteString>();

  // decode(vm, encoding, isLittleEndian, hasBOM, result)

  UnstableNode res;

  res = b.decode(vm, ByteStringEncoding::latin1, EncodingVariant::none);
  EXPECT_EQ_STRING(makeLString(
    MOZART_STR("\u00c3\u0080\u0001\0\u00c4\u00bf\u0010\0"),
    std::is_same<nchar, char>::value ? 12 : 8), res);

  res = b.decode(vm, ByteStringEncoding::utf8, EncodingVariant::none);
  EXPECT_EQ_STRING(makeLString(
    MOZART_STR("\u00c0\u0001\0\u013f\u0010\0"),
    std::is_same<nchar, char>::value ? 8 : 6), res);

  res = b.decode(vm, ByteStringEncoding::utf16, EncodingVariant::none);
  EXPECT_EQ_STRING(MOZART_STR("\uc380\u0100\uc4bf\u1000"), res);

  res = b.decode(vm, ByteStringEncoding::utf16, EncodingVariant::littleEndian);
  EXPECT_EQ_STRING(MOZART_STR("\u80c3\u0001\ubfc4\u0010"), res);

  res = b.decode(vm, ByteStringEncoding::utf32, EncodingVariant::littleEndian);
  EXPECT_EQ_STRING(MOZART_STR("\U000180c3\U0010bfc4"), res);

  EXPECT_RAISE(MOZART_STR("unicodeError"),
               b.decode(vm, ByteStringEncoding::utf32, EncodingVariant::none));
}

TEST_F(ByteStringTest, Slice) {
  static const unsigned char a[] = "12345";
  UnstableNode b = ByteString::build(vm, a);

  UnstableNode minusOne = SmallInt::build(vm, -1);
  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode two = SmallInt::build(vm, 2);
  UnstableNode three = SmallInt::build(vm, 3);
  UnstableNode four = SmallInt::build(vm, 4);
  UnstableNode five = SmallInt::build(vm, 5);
  UnstableNode six = SmallInt::build(vm, 6);

  UnstableNode result;

  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"),
               StringLike(b).stringSlice(vm, minusOne, zero));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"),
               StringLike(b).stringSlice(vm, five, six));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"),
               StringLike(b).stringSlice(vm, three, two));

  result = StringLike(b).stringSlice(vm, two, four);
  if (EXPECT_IS<ByteString>(result)) {
    static const unsigned char res[] = "34";
    EXPECT_EQ(makeLString(res), RichNode(result).as<ByteString>().value());
  }
}

TEST_F(ByteStringTest, StrChr) {
  static const unsigned char a[] = "12321";
  UnstableNode b = ByteString::build(vm, a);

  UnstableNode minusOne = SmallInt::build(vm, -1);
  UnstableNode zero = SmallInt::build(vm, 0);
  UnstableNode one = SmallInt::build(vm, 1);
  UnstableNode two = SmallInt::build(vm, 2);
  UnstableNode four = SmallInt::build(vm, 4);
  UnstableNode six = SmallInt::build(vm, 6);
  UnstableNode char2 = SmallInt::build(vm, '2');
  UnstableNode char256 = SmallInt::build(vm, 256);

  UnstableNode begin, end;

  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"),
               StringLike(b).stringSearch(vm, minusOne, char2, begin, end));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"),
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

  EXPECT_RAISE(MOZART_STR("error"), // type error
               StringLike(b).stringSearch(vm, zero, minusOne, begin, end));
  EXPECT_RAISE(MOZART_STR("error"), // type error
               StringLike(b).stringSearch(vm, zero, char256, begin, end));
}

TEST_F(ByteStringTest, Compare) {
  static const unsigned char a[] = "\xff\xee\xdd";
  static const unsigned char b[] = "\xff\xee";
  static const unsigned char c[] = "123";

  UnstableNode nodes[] = {ByteString::build(vm, a),
                          ByteString::build(vm, b),
                          ByteString::build(vm, c)};

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

TEST_F(ByteStringTest, Search) {
  static const unsigned char a[] = "123ababababd";
  //                                012345678901
  static const unsigned char needleString[] = "aba";

  UnstableNode b = ByteString::build(vm, a);
  UnstableNode needle = ByteString::build(vm, needleString);

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

TEST_F(ByteStringTest, Encode) {
  auto test = MOZART_STR("a\U000180c3b");

  UnstableNode res;

  res = encodeToBytestring(vm, test, ByteStringEncoding::latin1,
                           EncodingVariant::none);
  if (EXPECT_IS<ByteString>(res)) {
    const unsigned char expected[] = "a?b";
    EXPECT_EQ(makeLString(expected, 3), RichNode(res).as<ByteString>().value());
  }

  res = encodeToBytestring(vm, test, ByteStringEncoding::utf8,
                           EncodingVariant::none);
  if (EXPECT_IS<ByteString>(res)) {
    const unsigned char expected[] = "a\xf0\x98\x83\x83" "b";
    EXPECT_EQ(makeLString(expected, 6), RichNode(res).as<ByteString>().value());
  }

  res = encodeToBytestring(vm, test, ByteStringEncoding::utf16,
                           EncodingVariant::none);
  if (EXPECT_IS<ByteString>(res)) {
    const unsigned char expected[] = "\0a\xd8\x20\xdc\xc3\0b";
    EXPECT_EQ(makeLString(expected, 8), RichNode(res).as<ByteString>().value());
  }

  res = encodeToBytestring(vm, test, ByteStringEncoding::utf32,
                           EncodingVariant::none);
  if (EXPECT_IS<ByteString>(res)) {
    const unsigned char expected[] = "\0\0\0a\0\1\x80\xc3\0\0\0b";
    EXPECT_EQ(makeLString(expected, 12), RichNode(res).as<ByteString>().value());
  }
}
