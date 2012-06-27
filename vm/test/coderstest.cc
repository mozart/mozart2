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
        {"foo", MOZART_STR("foo"), true, true},
        {"foo", MOZART_STR("foo"), true, false},
        {"foo", MOZART_STR("foo"), false, true},
        {"foo", MOZART_STR("foo"), false, false},
        {"?\xff\1", MOZART_STR("\U00010000\u00ff\u0001"), true, true},
        {"?\xff\1", MOZART_STR("\U00010000\u00ff\u0001"), true, false},
        {"?\xff\1", MOZART_STR("\U00010000\u00ff\u0001"), false, true},
        {"?\xff\1", MOZART_STR("\U00010000\u00ff\u0001"), false, false},
        {"", MOZART_STR(""), true, true},
        {"", MOZART_STR(""), true, false},
        {"", MOZART_STR(""), false, true},
        {"", MOZART_STR(""), false, false},
    };

    for (auto&& vec : testVectors) {
        EncodingVariant variant = makeVariant(vec.isLittleEndian, vec.hasBom);
        auto res = encodeLatin1(makeLString(vec.decoded), variant);
        auto encoded = makeLString(reinterpret_cast<const unsigned char*>(vec.encoded));
        EXPECT_EQ(encoded, res);
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
        auto encoded = makeLString(reinterpret_cast<const unsigned char*>(vec.encoded), vec.length);
        auto res = decodeLatin1(encoded, variant);
        EXPECT_EQ(makeLString(vec.decoded), res);
    }
}

TEST_F(CodersTest, EncodeUTF8) {
    TestVector testVectors[] = {
        {u8"\ufefffoo", MOZART_STR("foo"), true, true},
        {u8"\ufefffoo", MOZART_STR("foo"), true, false},
        {u8"foo", MOZART_STR("foo"), false, true},
        {u8"foo", MOZART_STR("foo"), false, false},
        {u8"\ufeff\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), true, true},
        {u8"\ufeff\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), true, false},
        {u8"\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), false, true},
        {u8"\U00010000\u00ff\u0001", MOZART_STR("\U00010000\u00ff\u0001"), false, false},
        {u8"\ufeff", MOZART_STR(""), true, true},
        {u8"\ufeff", MOZART_STR(""), true, false},
        {"", MOZART_STR(""), false, true},
        {"", MOZART_STR(""), false, false},
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
        auto encoded = makeLString(reinterpret_cast<const unsigned char*>(vec.encoded), vec.length);
        auto res = decodeUTF8(encoded, variant);
        EXPECT_EQ(makeLString(vec.decoded), res);
    }
}

TEST_F(CodersTest, DecodeUTF8_Fail) {
    {
        const unsigned char s[] = "\xc3";
        auto res = decodeUTF8(s, EncodingVariant::none);
        EXPECT_EQ(UnicodeErrorReason::truncated, res.error);
    }
    {
        const unsigned char s[] = "\xe0\x80\x80";
        auto res = decodeUTF8(s, EncodingVariant::none);
        EXPECT_EQ(UnicodeErrorReason::invalidUTF8, res.error);
    }
    {
        const unsigned char s[] = "\xed\xa0\x80";
        auto res = decodeUTF8(s, EncodingVariant::none);
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
        auto encoded = makeLString(reinterpret_cast<const unsigned char*>(vec.encoded), vec.length);
        auto res = decodeUTF16(encoded, variant);
        EXPECT_EQ(makeLString(vec.decoded), res);
    }
}

TEST_F(CodersTest, DecodeUTF16_Fail) {
    {
        const unsigned char s[] = "\x12\x34\x56";
        auto res = decodeUTF16(s, EncodingVariant::none);
        EXPECT_EQ(UnicodeErrorReason::truncated, res.error);
    }
    {
        const unsigned char s[] = "\xd8\x01";
        auto res = decodeUTF16(s, EncodingVariant::none);
        EXPECT_EQ(UnicodeErrorReason::truncated, res.error);
    }
    {
        const unsigned char s[] = "\xd8\x01\x01\x01";
        auto res = decodeUTF16(s, EncodingVariant::none);
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
        auto encoded = makeLString(reinterpret_cast<const unsigned char*>(vec.encoded), vec.length);
        auto res = decodeUTF32(encoded, variant);
        EXPECT_EQ(makeLString(vec.decoded), res);
    }
}

TEST_F(CodersTest, DecodeUTF32_Fail) {
    {
        const unsigned char s[] = "\1\1\1\1";
        auto res = decodeUTF32(s, EncodingVariant::none);
        EXPECT_EQ(UnicodeErrorReason::outOfRange, res.error);
    }
    {
        const unsigned char s[] = "\0\0\0\1\0";
        auto res = decodeUTF32(makeLString(s, 5), EncodingVariant::none);
        EXPECT_EQ(UnicodeErrorReason::truncated, res.error);
    }
}


