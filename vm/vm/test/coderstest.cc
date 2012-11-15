#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

class CodersTest : public MozartTest {};

struct TestVector {
  const char* encoded;
  const nchar* decoded;
  bool hasBom;
  bool isLittleEndian;
  nativeint length;
};

EncodingVariant makeVariant(bool isLittleEndian, bool hasBOM) {
  EncodingVariant v = EncodingVariant::none;
  if (hasBOM)
    v |= EncodingVariant::hasBOM;
  if (isLittleEndian)
    v |= EncodingVariant::littleEndian;
  return v;
}

TEST_F(CodersTest, EncodeLatin1) {
  TestVector testVectors[] = {
    {"foo", MOZART_STR("foo"), true, true, 3},
    {"foo", MOZART_STR("foo"), true, false, 3},
    {"foo", MOZART_STR("foo"), false, true, 3},
    {"foo", MOZART_STR("foo"), false, false, 3},
    {"?\xff\1", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 3},
    {"?\xff\1", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 3},
    {"?\xff\1", MOZART_STR("\U00010000\u00ff\u0001"), false, true, 3},
    {"?\xff\1", MOZART_STR("\U00010000\u00ff\u0001"), false, false, 3},
    {"", MOZART_STR(""), true, true, 0},
    {"", MOZART_STR(""), true, false, 0},
    {"", MOZART_STR(""), false, true, 0},
    {"", MOZART_STR(""), false, false, 0},
  };

  for (auto&& vec : testVectors) {
    EncodingVariant variant = makeVariant(vec.isLittleEndian, vec.hasBom);
    auto res = encodeLatin1(makeLString(vec.decoded), variant);
    EXPECT_EQ(makeLString(ustr(vec.encoded)), res);
  }
}

TEST_F(CodersTest, DecodeLatin1) {
  TestVector testVectors[] = {
    {"foo", MOZART_STR("foo"), true, true, 3},
    {"foo", MOZART_STR("foo"), true, false, 3},
    {"foo", MOZART_STR("foo"), false, true, 3},
    {"foo", MOZART_STR("foo"), false, false, 3},
    {"\xff\1", MOZART_STR("\u00ff\u0001"), true, true, 2},
    {"\xff\1", MOZART_STR("\u00ff\u0001"), true, false, 2},
    {"\xff\1", MOZART_STR("\u00ff\u0001"), false, true, 2},
    {"\xff\1", MOZART_STR("\u00ff\u0001"), false, false, 2},
    {"", MOZART_STR(""), true, true, 0},
    {"", MOZART_STR(""), true, false, 0},
    {"", MOZART_STR(""), false, true, 0},
    {"", MOZART_STR(""), false, false, 0},
  };

  for (auto&& vec : testVectors) {
    EncodingVariant variant = makeVariant(vec.isLittleEndian, vec.hasBom);
    auto res = decodeLatin1(makeLString(ustr(vec.encoded), vec.length), variant);
    EXPECT_EQ(makeLString(vec.decoded), res);
  }
}

TEST_F(CodersTest, EncodeUTF8) {
  TestVector testVectors[] = {
    {u8"\ufefffoo", MOZART_STR("foo"), true, true, 6},
    {u8"\ufefffoo", MOZART_STR("foo"), true, false, 6},
    {u8"foo", MOZART_STR("foo"), false, true, 3},
    {u8"foo", MOZART_STR("foo"), false, false, 3},
    {u8"\ufeff\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 10},
    {u8"\ufeff\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 10},
    {u8"\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), false, true, 7},
    {u8"\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), false, false, 7},
    {u8"\ufeff", MOZART_STR(""), true, true, 3},
    {u8"\ufeff", MOZART_STR(""), true, false, 3},
    {"", MOZART_STR(""), false, true, 0},
    {"", MOZART_STR(""), false, false, 0},
  };

  for (auto&& vec : testVectors) {
    EncodingVariant variant = makeVariant(vec.isLittleEndian, vec.hasBom);
    auto res = encodeUTF8(makeLString(vec.decoded), variant);
    auto encoded = makeLString(reinterpret_cast<const unsigned char*>(vec.encoded));
    EXPECT_EQ(encoded, res);
  }
}

TEST_F(CodersTest, DecodeUTF8) {
  TestVector testVectors[] = {
    {u8"\ufefffoo", MOZART_STR("foo"), true, true, 6},
    {u8"\ufefffoo", MOZART_STR("foo"), true, false, 6},
    {u8"\ufefffoo", MOZART_STR("\ufefffoo"), false, true, 6},
    {u8"\ufefffoo", MOZART_STR("\ufefffoo"), false, false, 6},
    {u8"foo", MOZART_STR("foo"), true, true, 3},
    {u8"foo", MOZART_STR("foo"), true, false, 3},
    {u8"foo", MOZART_STR("foo"), false, true, 3},
    {u8"foo", MOZART_STR("foo"), false, false, 3},
    {u8"\ufeff\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 10},
    {u8"\ufeff\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 10},
    {u8"\ufeff\U00010000\u00ff\u0001", MOZART_STR("\ufeff\U00010000\u00ff\u0001"), false, true, 10},
    {u8"\ufeff\U00010000\u00ff\u0001", MOZART_STR("\ufeff\U00010000\u00ff\u0001"), false, false, 10},
    {u8"\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 7},
    {u8"\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 7},
    {u8"\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), false, true, 7},
    {u8"\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), false, false, 7},
    {u8"\ufeff", MOZART_STR(""), true, true, 3},
    {u8"\ufeff", MOZART_STR(""), true, false, 3},
    {"", MOZART_STR(""), true, true, 0},
    {"", MOZART_STR(""), true, false, 0},
    {"", MOZART_STR(""), false, true, 0},
    {"", MOZART_STR(""), false, false, 0},
  };

  for (auto&& vec : testVectors) {
    EncodingVariant variant = makeVariant(vec.isLittleEndian, vec.hasBom);
    auto res = decodeUTF8(makeLString(ustr(vec.encoded), vec.length), variant);
    EXPECT_EQ(makeLString(vec.decoded), res);
  }
}

TEST_F(CodersTest, DecodeUTF8_Fail) {
  {
    auto res = decodeUTF8(ustr("\xc3"), EncodingVariant::none);
    EXPECT_EQ(UnicodeErrorReason::truncated, res.error);
  }
  {
    auto res = decodeUTF8(ustr("\xe0\x80\x80"), EncodingVariant::none);
    EXPECT_EQ(UnicodeErrorReason::invalidUTF8, res.error);
  }
  {
    auto res = decodeUTF8(ustr("\xed\xa0\x80"), EncodingVariant::none);
    EXPECT_EQ(UnicodeErrorReason::surrogate, res.error);
  }
}


TEST_F(CodersTest, EncodeUTF16) {
  TestVector testVectors[] = {
    {"\xff\xfe" "f\0o\0o\0", MOZART_STR("foo"), true, true, 8},
    {"\xfe\xff" "\0f\0o\0o", MOZART_STR("foo"), true, false, 8},
    {"f\0o\0o\0", MOZART_STR("foo"), false, true, 6},
    {"\0f\0o\0o", MOZART_STR("foo"), false, false, 6},
    {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 10},
    {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 10},
    {"\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\U00010000\u00ff\u0001"), false, true, 8},
    {"\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\U00010000\u00ff\u0001"), false, false, 8},
    {"\xff\xfe", MOZART_STR(""), true, true, 2},
    {"\xfe\xff", MOZART_STR(""), true, false, 2},
    {"", MOZART_STR(""), false, true, 0},
    {"", MOZART_STR(""), false, false, 0},
  };

  for (auto&& vec : testVectors) {
    EncodingVariant variant = makeVariant(vec.isLittleEndian, vec.hasBom);
    auto res = encodeUTF16(makeLString(vec.decoded), variant);
    auto encoded = makeLString(reinterpret_cast<const unsigned char*>(vec.encoded), vec.length);
    EXPECT_EQ(encoded, res);
  }
}

TEST_F(CodersTest, DecodeUTF16) {
  TestVector testVectors[] = {
    {"\xff\xfe" "f\0o\0o\0", MOZART_STR("foo"), true, true, 8},
    {"\xfe\xff" "\0f\0o\0o", MOZART_STR("foo"), true, false, 8},
    {"\xff\xfe" "f\0o\0o\0", MOZART_STR("foo"), true, false, 8},
    {"\xfe\xff" "\0f\0o\0o", MOZART_STR("foo"), true, true, 8},
    {"\xff\xfe" "f\0o\0o\0", MOZART_STR("\ufefffoo"), false, true, 8},
    {"\xfe\xff" "\0f\0o\0o", MOZART_STR("\ufefffoo"), false, false, 8},
    {"\xff\xfe" "f\0o\0o\0", MOZART_STR("\ufffe\u6600\u6f00\u6f00"), false, false, 8},
    {"\xfe\xff" "\0f\0o\0o", MOZART_STR("\ufffe\u6600\u6f00\u6f00"), false, true, 8},
    {"f\0o\0o\0", MOZART_STR("foo"), true, true, 6},
    {"\0f\0o\0o", MOZART_STR("foo"), true, false, 6},
    {"f\0o\0o\0", MOZART_STR("foo"), false, true, 6},
    {"\0f\0o\0o", MOZART_STR("foo"), false, false, 6},
    {"f\0o\0o\0", MOZART_STR("\u6600\u6f00\u6f00"), true, false, 6},
    {"\0f\0o\0o", MOZART_STR("\u6600\u6f00\u6f00"), true, true, 6},
    {"f\0o\0o\0", MOZART_STR("\u6600\u6f00\u6f00"), false, false, 6},
    {"\0f\0o\0o", MOZART_STR("\u6600\u6f00\u6f00"), false, true, 6},

    {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 10},
    {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 10},
    {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\ufeff\U00010000\u00ff\u0001"), false, true, 10},
    {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\ufeff\U00010000\u00ff\u0001"), false, false, 10},
    {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 10},
    {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 10},
    {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\ufffe\u00d8\u00dc\uff00\u0100"), false, false, 10},
    {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\ufffe\u00d8\u00dc\uff00\u0100"), false, true, 10},
    {"\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 8},
    {"\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 8},
    {"\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\U00010000\u00ff\u0001"), false, true, 8},
    {"\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\U00010000\u00ff\u0001"), false, false, 8},
    {"\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\u00d8\u00dc\uff00\u0100"), true, false, 8},
    {"\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\u00d8\u00dc\uff00\u0100"), true, true, 8},
    {"\x00\xd8\x00\xdc\xff\x00\x01\x00", MOZART_STR("\u00d8\u00dc\uff00\u0100"), false, false, 8},
    {"\xd8\x00\xdc\x00\x00\xff\x00\x01", MOZART_STR("\u00d8\u00dc\uff00\u0100"), false, true, 8},

    {"\xff\xfe", MOZART_STR(""), true, true, 2},
    {"\xfe\xff", MOZART_STR(""), true, false, 2},
    {"", MOZART_STR(""), true, true, 0},
    {"", MOZART_STR(""), true, false, 0},
    {"", MOZART_STR(""), false, true, 0},
    {"", MOZART_STR(""), false, false, 0},
  };

  for (auto&& vec : testVectors) {
    EncodingVariant variant = makeVariant(vec.isLittleEndian, vec.hasBom);
    auto res = decodeUTF16(makeLString(ustr(vec.encoded), vec.length), variant);
    EXPECT_EQ(makeLString(vec.decoded), res);
  }
}

TEST_F(CodersTest, DecodeUTF16_Fail) {
  {
    auto res = decodeUTF16(ustr("\x12\x34\x56"), EncodingVariant::none);
    EXPECT_EQ(UnicodeErrorReason::truncated, res.error);
  }
  {
    auto res = decodeUTF16(ustr("\xd8\x01"), EncodingVariant::none);
    EXPECT_EQ(UnicodeErrorReason::truncated, res.error);
  }
  {
    auto res = decodeUTF16(ustr("\xd8\x01\x01\x01"), EncodingVariant::none);
    EXPECT_EQ(UnicodeErrorReason::invalidUTF16, res.error);
  }
}

TEST_F(CodersTest, EncodeUTF32) {
  TestVector testVectors[] = {
    {"\xff\xfe\0\0" "f\0\0\0o\0\0\0o\0\0\0", MOZART_STR("foo"), true, true, 16},
    {"\0\0\xfe\xff" "\0\0\0f\0\0\0o\0\0\0o", MOZART_STR("foo"), true, false, 16},
    {"f\0\0\0o\0\0\0o\0\0\0", MOZART_STR("foo"), false, true, 12},
    {"\0\0\0f\0\0\0o\0\0\0o", MOZART_STR("foo"), false, false, 12},
    {"\xff\xfe\0\0\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 16},
    {"\0\0\xfe\xff\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 16},
    {"\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", MOZART_STR("\U00010000\u00ff\u0001"), false, true, 12},
    {"\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", MOZART_STR("\U00010000\u00ff\u0001"), false, false, 12},
    {"\xff\xfe\0\0", MOZART_STR(""), true, true, 4},
    {"\0\0\xfe\xff", MOZART_STR(""), true, false, 4},
    {"", MOZART_STR(""), false, true, 0},
    {"", MOZART_STR(""), false, false, 0},
  };

  for (auto&& vec : testVectors) {
    EncodingVariant variant = makeVariant(vec.isLittleEndian, vec.hasBom);
    auto res = encodeUTF32(makeLString(vec.decoded), variant);
    auto encoded = makeLString(reinterpret_cast<const unsigned char*>(vec.encoded), vec.length);
    EXPECT_EQ(encoded, res);
  }
}

TEST_F(CodersTest, DecodeUTF32) {
  TestVector testVectors[] = {
    {"\xff\xfe\0\0" "f\0\0\0o\0\0\0o\0\0\0", MOZART_STR("foo"), true, true, 16},
    {"\0\0\xfe\xff" "\0\0\0f\0\0\0o\0\0\0o", MOZART_STR("foo"), true, false, 16},
    {"\xff\xfe\0\0" "f\0\0\0o\0\0\0o\0\0\0", MOZART_STR("foo"), true, false, 16},
    {"\0\0\xfe\xff" "\0\0\0f\0\0\0o\0\0\0o", MOZART_STR("foo"), true, true, 16},
    {"\xff\xfe\0\0" "f\0\0\0o\0\0\0o\0\0\0", MOZART_STR("\ufefffoo"), false, true, 16},
    {"\0\0\xfe\xff" "\0\0\0f\0\0\0o\0\0\0o", MOZART_STR("\ufefffoo"), false, false, 16},
    {"\x00\x02\x01\x00", MOZART_STR("\U00020100"), true, false, 4},
    {"\x00\x02\x01\x00", MOZART_STR("\U00010200"), true, true, 4},
    {"f\0\0\0o\0\0\0o\0\0\0", MOZART_STR("foo"), true, true, 12},
    {"\0\0\0f\0\0\0o\0\0\0o", MOZART_STR("foo"), true, false, 12},
    {"f\0\0\0o\0\0\0o\0\0\0", MOZART_STR("foo"), false, true, 12},
    {"\0\0\0f\0\0\0o\0\0\0o", MOZART_STR("foo"), false, false, 12},
    {"\xff\xfe\0\0\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 16},
    {"\0\0\xfe\xff\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 16},
    {"\xff\xfe\0\0\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 16},
    {"\0\0\xfe\xff\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 16},
    {"\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", MOZART_STR("\U00010000\u00ff\u0001"), false, true, 12},
    {"\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", MOZART_STR("\U00010000\u00ff\u0001"), false, false, 12},
    {"\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", MOZART_STR("\U00010000\u00ff\u0001"), true, true, 12},
    {"\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", MOZART_STR("\U00010000\u00ff\u0001"), true, false, 12},
    {"\xff\xfe\0\0", MOZART_STR(""), true, true, 4},
    {"\0\0\xfe\xff", MOZART_STR(""), true, false, 4},
    {"\xff\xfe\0\0", MOZART_STR("\ufeff"), false, true, 4},
    {"\0\0\xfe\xff", MOZART_STR("\ufeff"), false, false, 4},
    {"", MOZART_STR(""), true, true, 0},
    {"", MOZART_STR(""), true, false, 0},
    {"", MOZART_STR(""), false, true, 0},
    {"", MOZART_STR(""), false, false, 0},
  };

  for (auto&& vec : testVectors) {
    EncodingVariant variant = makeVariant(vec.isLittleEndian, vec.hasBom);
    auto res = decodeUTF32(makeLString(ustr(vec.encoded), vec.length), variant);
    EXPECT_EQ(makeLString(vec.decoded), res);
  }
}

TEST_F(CodersTest, DecodeUTF32_Fail) {
  {
    auto res = decodeUTF32(ustr("\1\1\1\1"), EncodingVariant::none);
    EXPECT_EQ(UnicodeErrorReason::outOfRange, res.error);
  }
  {
    auto res = decodeUTF32(makeLString(ustr("\0\0\0\1\0"), 5),
                           EncodingVariant::none);
    EXPECT_EQ(UnicodeErrorReason::truncated, res.error);
  }
}

TEST_F(CodersTest, EncodeGeneric) {
  auto test = makeLString(MOZART_STR("a\U000180c3b"));

  EXPECT_EQ(
    makeLString(ustr("a?b"), 3),
    encodeGeneric(test, ByteStringEncoding::latin1, EncodingVariant::none));

  EXPECT_EQ(
    makeLString(ustr("a\xf0\x98\x83\x83" "b"), 6),
    encodeGeneric(test, ByteStringEncoding::utf8, EncodingVariant::none));

  EXPECT_EQ(
    makeLString(ustr("\0a\xd8\x20\xdc\xc3\0b"), 8),
    encodeGeneric(test, ByteStringEncoding::utf16, EncodingVariant::none));

  EXPECT_EQ(
    makeLString(ustr("\0\0\0a\0\1\x80\xc3\0\0\0b"), 12),
    encodeGeneric(test, ByteStringEncoding::utf32, EncodingVariant::none));
}

TEST_F(CodersTest, DecodeGeneric) {
  static const unsigned char a[] = "\xc3\x80\x01\x00\xc4\xbf\x10\x00";
  auto b = newLString(a, 8);

  EXPECT_EQ(
    makeLString(
      MOZART_STR("\u00c3\u0080\u0001\0\u00c4\u00bf\u0010\0"),
      std::is_same<nchar, char>::value ? 12 : 8),
    decodeGeneric(b, ByteStringEncoding::latin1, EncodingVariant::none));

  EXPECT_EQ(
    makeLString(
      MOZART_STR("\u00c0\u0001\0\u013f\u0010\0"),
      std::is_same<nchar, char>::value ? 8 : 6),
    decodeGeneric(b, ByteStringEncoding::utf8, EncodingVariant::none));

  EXPECT_EQ(
    MOZART_STR("\uc380\u0100\uc4bf\u1000"),
    decodeGeneric(b, ByteStringEncoding::utf16, EncodingVariant::none));

  EXPECT_EQ(
    MOZART_STR("\u80c3\u0001\ubfc4\u0010"),
    decodeGeneric(b, ByteStringEncoding::utf16, EncodingVariant::littleEndian));

  EXPECT_EQ(
    MOZART_STR("\U000180c3\U0010bfc4"),
    decodeGeneric(b, ByteStringEncoding::utf32, EncodingVariant::littleEndian));

  EXPECT_TRUE(
    decodeGeneric(b, ByteStringEncoding::utf32, EncodingVariant::none).isError());
}
