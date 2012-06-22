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

  nativeint result;
  if (EXPECT_PROCEED(StringLike(b).stringCharAt(vm, zero, result)))
    EXPECT_EQ(1, result);

  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringCharAt(vm, two, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringCharAt(vm, minusOne, result));

  if (EXPECT_PROCEED(StringLike(b).stringCharAt(vm, one, result)))
    EXPECT_EQ(0xf3, result);
}

TEST_F(ByteStringTest, Append) {
  static const unsigned char a1[] = "abc", a2[] = "\xde\xf0", a0[] = "";
  static const unsigned char a12[] = "abc\xde\xf0", a11[] = "abcabc";
  UnstableNode b1 = ByteString::build(vm, a1);
  UnstableNode b2 = ByteString::build(vm, a2);
  UnstableNode b0 = ByteString::build(vm, a0);

  UnstableNode b12i;
  if (EXPECT_PROCEED(StringLike(b1).stringAppend(vm, b2, b12i))) {
    RichNode b12 = b12i;
    if (EXPECT_IS<ByteString>(b12)) {
      EXPECT_EQ(a12, b12.as<ByteString>().value());
    }
  }

  UnstableNode b11i;
  if (EXPECT_PROCEED(StringLike(b1).stringAppend(vm, b1, b11i))) {
    RichNode b11 = b11i;
    if (EXPECT_IS<ByteString>(b11)) {
      EXPECT_EQ(a11, b11.as<ByteString>().value());
    }
  }

  UnstableNode b00i;
  if (EXPECT_PROCEED(StringLike(b0).stringAppend(vm, b0, b00i))) {
    RichNode b00 = b00i;
    if (EXPECT_IS<ByteString>(b00)) {
      EXPECT_EQ(a0, b00.as<ByteString>().value());
    }
  }

  UnstableNode b10i;
  if (EXPECT_PROCEED(StringLike(b1).stringAppend(vm, b0, b10i))) {
    RichNode b10 = b10i;
    if (EXPECT_IS<ByteString>(b10)) {
      EXPECT_EQ(a1, b10.as<ByteString>().value());
    }
  }
}

TEST_F(ByteStringTest, Decode) {
  static const unsigned char a[] = "\xc3\x80\x01\x00\xc4\xbf\x10\x00";
  UnstableNode bNode = ByteString::build(vm, newLString(a, 8));
  auto b = RichNode(bNode).as<ByteString>();

  // decode(vm, encoding, isLittleEndian, hasBOM, result)

  UnstableNode res;
  if (EXPECT_PROCEED(b.decode(vm, ByteStringEncoding::latin1, EncodingVariant::none, res))) {
    EXPECT_EQ_STRING(newLString(MOZART_STR("\u00c3\u0080\u0001\0\u00c4\u00bf\u0010\0"), 8), res);
  }

  if (EXPECT_PROCEED(b.decode(vm, ByteStringEncoding::utf8, EncodingVariant::none, res))) {
    EXPECT_EQ_STRING(makeLString(MOZART_STR("\u00c0\u0001\0\u013f\u0010\0"), 6), res);
  }

  if (EXPECT_PROCEED(b.decode(vm, ByteStringEncoding::utf16, EncodingVariant::none, res))) {
    EXPECT_EQ_STRING(MOZART_STR("\uc380\u0100\uc4bf\u1000"), res);
  }

  if (EXPECT_PROCEED(b.decode(vm, ByteStringEncoding::utf16, EncodingVariant::littleEndian, res))) {
    EXPECT_EQ_STRING(MOZART_STR("\u80c3\u0001\ubfc4\u0010"), res);
  }

  if (EXPECT_PROCEED(b.decode(vm, ByteStringEncoding::utf32, EncodingVariant::littleEndian, res))) {
    EXPECT_EQ_STRING(MOZART_STR("\U000180c3\U0010bfc4"), res);
  }

  EXPECT_RAISE(MOZART_STR("unicodeError"),
               b.decode(vm, ByteStringEncoding::utf32, EncodingVariant::none, res));
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
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSlice(vm, minusOne, zero, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSlice(vm, five, six, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSlice(vm, three, two, result));

  if (EXPECT_PROCEED(StringLike(b).stringSlice(vm, two, four, result))) {
    if (EXPECT_IS<ByteString>(result)) {
      static const unsigned char res[] = "34";
      EXPECT_EQ(makeLString(res), RichNode(result).as<ByteString>().value());
    }
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

  UnstableNode result;
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSearch(vm, minusOne, char2, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBounds"), StringLike(b).stringSearch(vm, six, char2, result));

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, zero, char2, result))) {
    EXPECT_EQ_INT(1, result);
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, one, char2, result))) {
    EXPECT_EQ_INT(1, result);
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, two, char2, result))) {
    EXPECT_EQ_INT(3, result);
  }

  if (EXPECT_PROCEED(StringLike(b).stringSearch(vm, four, char2, result))) {
    if (EXPECT_IS<Boolean>(result)) {
      bool value;
      if (EXPECT_PROCEED(BooleanValue(result).boolValue(vm, value)))
        EXPECT_FALSE(value);
    }
  }
}


