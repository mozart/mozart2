#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class ByteStringTest : public MozartTest {};

TEST_F(ByteStringTest, Get) {
  static const unsigned char a[] = "\1\xf3";
  UnstableNode b = ByteString::build(vm, a);

  unsigned char result;
  if (EXPECT_PROCEED(ByteStringLike(b).bsGet(vm, 0, result)))
    EXPECT_EQ((unsigned char) '\1', result);

  EXPECT_RAISE(MOZART_STR("indexOutOfBound"),
               ByteStringLike(b).bsGet(vm, 2, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBound"),
               ByteStringLike(b).bsGet(vm, -1, result));

  if (EXPECT_PROCEED(ByteStringLike(b).bsGet(vm, 1, result)))
    EXPECT_EQ((unsigned char) '\xf3', result);
}

TEST_F(ByteStringTest, Append) {
  static const unsigned char a1[] = "abc", a2[] = "\xde\xf0", a0[] = "";
  static const unsigned char a12[] = "abc\xde\xf0", a11[] = "abcabc";
  UnstableNode b1 = ByteString::build(vm, a1);
  UnstableNode b2 = ByteString::build(vm, a2);
  UnstableNode b0 = ByteString::build(vm, a0);

  UnstableNode b12i;
  if (EXPECT_PROCEED(ByteStringLike(b1).bsAppend(vm, b2, b12i))) {
    RichNode b12 = b12i;
    if (EXPECT_IS<ByteString>(b12)) {
      EXPECT_EQ(a12, b12.as<ByteString>().value());
    }
  }

  UnstableNode b11i;
  if (EXPECT_PROCEED(ByteStringLike(b1).bsAppend(vm, b1, b11i))) {
    RichNode b11 = b11i;
    if (EXPECT_IS<ByteString>(b11)) {
      EXPECT_EQ(a11, b11.as<ByteString>().value());
    }
  }

  UnstableNode b00i;
  if (EXPECT_PROCEED(ByteStringLike(b0).bsAppend(vm, b0, b00i))) {
    RichNode b00 = b00i;
    if (EXPECT_IS<ByteString>(b00)) {
      EXPECT_EQ(a0, b00.as<ByteString>().value());
    }
  }

  UnstableNode b10i;
  if (EXPECT_PROCEED(ByteStringLike(b1).bsAppend(vm, b0, b10i))) {
    RichNode b10 = b10i;
    if (EXPECT_IS<ByteString>(b10)) {
      EXPECT_EQ(a1, b10.as<ByteString>().value());
    }
  }
}

TEST_F(ByteStringTest, Decode) {
  static const unsigned char a[] = "\xc3\x80\x01\x00\xc4\xbf\x10\x00";
  UnstableNode b = ByteString::build(vm, newLString(a, 8));

  // bsDecode(vm, encoding, isLittleEndian, hasBOM, result)

  UnstableNode res;
  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::latin1, EncodingVariant::none, res))) {
    EXPECT_EQ_STRING(makeLString(
      MOZART_STR("\u00c3\u0080\u0001\0\u00c4\u00bf\u0010\0"),
      std::is_same<nchar, char>::value ? 12 : 8), res);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf8, EncodingVariant::none, res))) {
    EXPECT_EQ_STRING(makeLString(
      MOZART_STR("\u00c0\u0001\0\u013f\u0010\0"),
      std::is_same<nchar, char>::value ? 8 : 6), res);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf16, EncodingVariant::none, res))) {
    EXPECT_EQ_STRING(MOZART_STR("\uc380\u0100\uc4bf\u1000"), res);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf16, EncodingVariant::littleEndian, res))) {
    EXPECT_EQ_STRING(MOZART_STR("\u80c3\u0001\ubfc4\u0010"), res);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf32, EncodingVariant::littleEndian, res))) {
    EXPECT_EQ_STRING(MOZART_STR("\U000180c3\U0010bfc4"), res);
  }

  EXPECT_RAISE(MOZART_STR("unicodeError"),
               ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf32, EncodingVariant::none, res));
}

TEST_F(ByteStringTest, Slice) {
  static const unsigned char a[] = "12345";
  UnstableNode b = ByteString::build(vm, a);

  UnstableNode result;
  EXPECT_RAISE(MOZART_STR("indexOutOfBound"),
               ByteStringLike(b).bsSlice(vm, -1, 0, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBound"),
               ByteStringLike(b).bsSlice(vm, 5, 6, result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBound"),
               ByteStringLike(b).bsSlice(vm, 3, 2, result));

  if (EXPECT_PROCEED(ByteStringLike(b).bsSlice(vm, 2, 4, result))) {
    if (EXPECT_IS<ByteString>(result)) {
      static const unsigned char res[] = "34";
      EXPECT_EQ(makeLString(res), RichNode(result).as<ByteString>().value());
    }
  }
}

TEST_F(ByteStringTest, StrChr) {
  static const unsigned char a[] = "12321";
  UnstableNode b = ByteString::build(vm, a);

  UnstableNode result;
  EXPECT_RAISE(MOZART_STR("indexOutOfBound"),
               ByteStringLike(b).bsStrChr(vm, -1, '2', result));
  EXPECT_RAISE(MOZART_STR("indexOutOfBound"),
               ByteStringLike(b).bsStrChr(vm, 6, '2', result));

  if (EXPECT_PROCEED(ByteStringLike(b).bsStrChr(vm, 0, '2', result))) {
    EXPECT_EQ_INT(1, result);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsStrChr(vm, 1, '2', result))) {
    EXPECT_EQ_INT(1, result);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsStrChr(vm, 2, '2', result))) {
    EXPECT_EQ_INT(3, result);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsStrChr(vm, 4, '2', result))) {
    if (EXPECT_IS<Boolean>(result)) {
      bool value = true;
      if (EXPECT_PROCEED(BooleanValue(result).boolValue(vm, value)))
        EXPECT_FALSE(value);
    }
  }
}
