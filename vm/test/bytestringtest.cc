#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class ByteStringTest : public MozartTest {};

TEST_F(ByteStringTest, Get) {
  UnstableNode b = ByteString::build(vm, "\1\xf3");
  char result;
  if (EXPECT_PROCEED(ByteStringLike(b).bsGet(vm, 0, result)))
    EXPECT_EQ('\1', result);

  EXPECT_RAISE(NSTR("indexOutOfBound"), ByteStringLike(b).bsGet(vm, 2, result));
  EXPECT_RAISE(NSTR("indexOutOfBound"), ByteStringLike(b).bsGet(vm, -1, result));

  if (EXPECT_PROCEED(ByteStringLike(b).bsGet(vm, 1, result)))
    EXPECT_EQ('\xf3', result);
}

TEST_F(ByteStringTest, Append) {
  UnstableNode b1 = ByteString::build(vm, "abc");
  UnstableNode b2 = ByteString::build(vm, "\xde\xf0");
  UnstableNode b0 = ByteString::build(vm, "");

  UnstableNode b12i;
  if (EXPECT_PROCEED(ByteStringLike(b1).bsAppend(vm, b2, b12i))) {
    RichNode b12 = b12i;
    if (EXPECT_IS<ByteString>(b12)) {
      EXPECT_EQ(LString<char>("abc\xde\xf0"), b12.as<ByteString>().getBytes());
    }
  }

  UnstableNode b11i;
  if (EXPECT_PROCEED(ByteStringLike(b1).bsAppend(vm, b1, b11i))) {
    RichNode b11 = b11i;
    if (EXPECT_IS<ByteString>(b11)) {
      EXPECT_EQ(LString<char>("abcabc"), b11.as<ByteString>().getBytes());
    }
  }

  UnstableNode b00i;
  if (EXPECT_PROCEED(ByteStringLike(b0).bsAppend(vm, b0, b00i))) {
    RichNode b00 = b00i;
    if (EXPECT_IS<ByteString>(b00)) {
      EXPECT_EQ(LString<char>(), b00.as<ByteString>().getBytes());
    }
  }

  UnstableNode b10i;
  if (EXPECT_PROCEED(ByteStringLike(b1).bsAppend(vm, b0, b10i))) {
    RichNode b10 = b10i;
    if (EXPECT_IS<ByteString>(b10)) {
      EXPECT_EQ(LString<char>("abc"), b10.as<ByteString>().getBytes());
    }
  }
}

TEST_F(ByteStringTest, Decode) {
  UnstableNode b = ByteString::build(vm, LString<char>("\xc3\x80\x01\x00\xc4\xbf\x10\x00", 8));

  // bsDecode(vm, encoding, isLittleEndian, hasBOM, result)

  UnstableNode res;
  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::latin1, false, false, res))) {
    EXPECT_EQ_STRING(LString<nchar>(NSTR("\u00c3\u0080\u0001\0\u00c4\u00bf\u0010\0"), 8), res);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf8, false, false, res))) {
    EXPECT_EQ_STRING(LString<nchar>(NSTR("\u00c0\u0001\0\u013f\u0010\0"), 6), res);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf16, false, false, res))) {
    EXPECT_EQ_STRING(NSTR("\uc380\u0100\uc4bf\u1000"), res);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf16, true, false, res))) {
    EXPECT_EQ_STRING(NSTR("\u80c3\u0001\ubfc4\u0010"), res);
  }

  if (EXPECT_PROCEED(ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf32, true, false, res))) {
    EXPECT_EQ_STRING(NSTR("\U000180c3\U0010bfc4"), res);
  }

  EXPECT_RAISE(NSTR("unicodeError"),
               ByteStringLike(b).bsDecode(vm, ByteStringEncoding::utf32, false, false, res));
}

TEST_F(ByteStringTest, Slice) {
  UnstableNode b = ByteString::build(vm, "12345");

  UnstableNode result;
  EXPECT_RAISE(NSTR("indexOutOfBound"), ByteStringLike(b).bsSlice(vm, -1, 0, result));
  EXPECT_RAISE(NSTR("indexOutOfBound"), ByteStringLike(b).bsSlice(vm, 5, 6, result));
  EXPECT_RAISE(NSTR("indexOutOfBound"), ByteStringLike(b).bsSlice(vm, 3, 2, result));

  if (EXPECT_PROCEED(ByteStringLike(b).bsSlice(vm, 2, 4, result))) {
    if (EXPECT_IS<ByteString>(result)) {
      EXPECT_EQ(LString<char>("34"), RichNode(result).as<ByteString>().getBytes());
    }
  }
}

TEST_F(ByteStringTest, StrChr) {
  UnstableNode b = ByteString::build(vm, "12321");

  UnstableNode result;
  EXPECT_RAISE(NSTR("indexOutOfBound"), ByteStringLike(b).bsStrChr(vm, -1, '2', result));
  EXPECT_RAISE(NSTR("indexOutOfBound"), ByteStringLike(b).bsStrChr(vm, 6, '2', result));

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
      bool value;
      if (EXPECT_PROCEED(BooleanValue(result).boolValue(vm, value)))
        EXPECT_FALSE(value);
    }
  }
}


