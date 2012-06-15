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

TEST_F(CodersTest, EncodeLatin1) {
    TestVector testVectors[] = {
        {"foo", NSTR("foo"), true, true},
        {"foo", NSTR("foo"), true, false},
        {"foo", NSTR("foo"), false, true},
        {"foo", NSTR("foo"), false, false},
        {"?\xff\1", NSTR("\U00010000\u00ff\u0001"), true, true},
        {"?\xff\1", NSTR("\U00010000\u00ff\u0001"), true, false},
        {"?\xff\1", NSTR("\U00010000\u00ff\u0001"), false, true},
        {"?\xff\1", NSTR("\U00010000\u00ff\u0001"), false, false},
        {"", NSTR(""), true, true},
        {"", NSTR(""), true, false},
        {"", NSTR(""), false, true},
        {"", NSTR(""), false, false},
    };

    for (auto&& vec : testVectors) {
        auto res = encodeLatin1(vm, vec.decoded, vec.isLittleEndian, vec.hasBom);
        EXPECT_EQ(LString<char>(vec.encoded), res);
        res.free(vm);
    }
}

TEST_F(CodersTest, DecodeLatin1) {
    TestVector testVectors[] = {
        {"foo", NSTR("foo"), true, true, 3},
        {"foo", NSTR("foo"), true, false, 3},
        {"foo", NSTR("foo"), false, true, 3},
        {"foo", NSTR("foo"), false, false, 3},
        {"\xff\1", NSTR("\u00ff\u0001"), true, true, 2},
        {"\xff\1", NSTR("\u00ff\u0001"), true, false, 2},
        {"\xff\1", NSTR("\u00ff\u0001"), false, true, 2},
        {"\xff\1", NSTR("\u00ff\u0001"), false, false, 2},
        {"", NSTR(""), true, true, 0},
        {"", NSTR(""), true, false, 0},
        {"", NSTR(""), false, true, 0},
        {"", NSTR(""), false, false, 0},
    };

    for (auto&& vec : testVectors) {
        auto res = decodeLatin1(vm, {vec.encoded, vec.length},
                                vec.isLittleEndian, vec.hasBom);
        EXPECT_EQ(LString<nchar>(vec.decoded), res);
        res.free(vm);
    }
}

TEST_F(CodersTest, EncodeUTF8) {
    TestVector testVectors[] = {
        {u8"\ufefffoo", NSTR("foo"), true, true},
        {u8"\ufefffoo", NSTR("foo"), true, false},
        {u8"foo", NSTR("foo"), false, true},
        {u8"foo", NSTR("foo"), false, false},
        {u8"\ufeff\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), true, true},
        {u8"\ufeff\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), true, false},
        {u8"\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), false, true},
        {u8"\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), false, false},
        {u8"\ufeff", NSTR(""), true, true},
        {u8"\ufeff", NSTR(""), true, false},
        {"", NSTR(""), false, true},
        {"", NSTR(""), false, false},
    };

    for (auto&& vec : testVectors) {
        auto res = encodeUTF8(vm, vec.decoded, vec.isLittleEndian, vec.hasBom);
        EXPECT_EQ(LString<char>(vec.encoded), res);
        res.free(vm);
    }
}

TEST_F(CodersTest, DecodeUTF8) {
    TestVector testVectors[] = {
        {u8"\ufefffoo", NSTR("foo"), true, true, 6},
        {u8"\ufefffoo", NSTR("foo"), true, false, 6},
        {u8"\ufefffoo", NSTR("\ufefffoo"), false, true, 6},
        {u8"\ufefffoo", NSTR("\ufefffoo"), false, false, 6},
        {u8"foo", NSTR("foo"), true, true, 3},
        {u8"foo", NSTR("foo"), true, false, 3},
        {u8"foo", NSTR("foo"), false, true, 3},
        {u8"foo", NSTR("foo"), false, false, 3},
        {u8"\ufeff\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), true, true, 10},
        {u8"\ufeff\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), true, false, 10},
        {u8"\ufeff\U00010000\u00ff\u0001", NSTR("\ufeff\U00010000\u00ff\u0001"), false, true, 10},
        {u8"\ufeff\U00010000\u00ff\u0001", NSTR("\ufeff\U00010000\u00ff\u0001"), false, false, 10},
        {u8"\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), true, true, 7},
        {u8"\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), true, false, 7},
        {u8"\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), false, true, 7},
        {u8"\U00010000\u00ff\u0001", NSTR("\U00010000\u00ff\u0001"), false, false, 7},
        {u8"\ufeff", NSTR(""), true, true, 3},
        {u8"\ufeff", NSTR(""), true, false, 3},
        {"", NSTR(""), true, true, 0},
        {"", NSTR(""), true, false, 0},
        {"", NSTR(""), false, true, 0},
        {"", NSTR(""), false, false, 0},
    };

    for (auto&& vec : testVectors) {
        auto res = decodeUTF8(vm, {vec.encoded, vec.length},
                              vec.isLittleEndian, vec.hasBom);
        EXPECT_EQ(LString<nchar>(vec.decoded), res);
        res.free(vm);
    }
}

TEST_F(CodersTest, DecodeUTF8_Fail) {
    auto res = decodeUTF8(vm, "\xc3", false, false);
    EXPECT_EQ(UnicodeErrorReason::truncated, res.error);

    res = decodeUTF8(vm, "\xe0\x80\x80", false, false);
    EXPECT_EQ(UnicodeErrorReason::invalidUTF8, res.error);

    res = decodeUTF8(vm, "\xed\xa0\x80", false, false);
    EXPECT_EQ(UnicodeErrorReason::surrogate, res.error);
}


TEST_F(CodersTest, EncodeUTF16) {
    TestVector testVectors[] = {
        {"\xff\xfe" "f\0o\0o\0", NSTR("foo"), true, true, 8},
        {"\xfe\xff" "\0f\0o\0o", NSTR("foo"), true, false, 8},
        {"f\0o\0o\0", NSTR("foo"), false, true, 6},
        {"\0f\0o\0o", NSTR("foo"), false, false, 6},
        {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\U00010000\u00ff\u0001"), true, true, 10},
        {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\U00010000\u00ff\u0001"), true, false, 10},
        {"\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\U00010000\u00ff\u0001"), false, true, 8},
        {"\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\U00010000\u00ff\u0001"), false, false, 8},
        {"\xff\xfe", NSTR(""), true, true, 2},
        {"\xfe\xff", NSTR(""), true, false, 2},
        {"", NSTR(""), false, true, 0},
        {"", NSTR(""), false, false, 0},
    };

    for (auto&& vec : testVectors) {
        auto res = encodeUTF16(vm, vec.decoded, vec.isLittleEndian, vec.hasBom);
        EXPECT_EQ(LString<char>(vec.encoded, vec.length), res);
        res.free(vm);
    }
}

TEST_F(CodersTest, DecodeUTF16) {
    TestVector testVectors[] = {
        {"\xff\xfe" "f\0o\0o\0", NSTR("foo"), true, true, 8},
        {"\xfe\xff" "\0f\0o\0o", NSTR("foo"), true, false, 8},
        {"\xff\xfe" "f\0o\0o\0", NSTR("foo"), true, false, 8},
        {"\xfe\xff" "\0f\0o\0o", NSTR("foo"), true, true, 8},
        {"\xff\xfe" "f\0o\0o\0", NSTR("\ufefffoo"), false, true, 8},
        {"\xfe\xff" "\0f\0o\0o", NSTR("\ufefffoo"), false, false, 8},
        {"\xff\xfe" "f\0o\0o\0", NSTR("\ufffe\u6600\u6f00\u6f00"), false, false, 8},
        {"\xfe\xff" "\0f\0o\0o", NSTR("\ufffe\u6600\u6f00\u6f00"), false, true, 8},
        {"f\0o\0o\0", NSTR("foo"), true, true, 6},
        {"\0f\0o\0o", NSTR("foo"), true, false, 6},
        {"f\0o\0o\0", NSTR("foo"), false, true, 6},
        {"\0f\0o\0o", NSTR("foo"), false, false, 6},
        {"f\0o\0o\0", NSTR("\u6600\u6f00\u6f00"), true, false, 6},
        {"\0f\0o\0o", NSTR("\u6600\u6f00\u6f00"), true, true, 6},
        {"f\0o\0o\0", NSTR("\u6600\u6f00\u6f00"), false, false, 6},
        {"\0f\0o\0o", NSTR("\u6600\u6f00\u6f00"), false, true, 6},

        {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\U00010000\u00ff\u0001"), true, true, 10},
        {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\U00010000\u00ff\u0001"), true, false, 10},
        {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\ufeff\U00010000\u00ff\u0001"), false, true, 10},
        {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\ufeff\U00010000\u00ff\u0001"), false, false, 10},
        {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\U00010000\u00ff\u0001"), true, false, 10},
        {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\U00010000\u00ff\u0001"), true, true, 10},
        {"\xff\xfe\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\ufffe\u00d8\u00dc\uff00\u0100"), false, false, 10},
        {"\xfe\xff\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\ufffe\u00d8\u00dc\uff00\u0100"), false, true, 10},
        {"\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\U00010000\u00ff\u0001"), true, true, 8},
        {"\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\U00010000\u00ff\u0001"), true, false, 8},
        {"\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\U00010000\u00ff\u0001"), false, true, 8},
        {"\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\U00010000\u00ff\u0001"), false, false, 8},
        {"\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\u00d8\u00dc\uff00\u0100"), true, false, 8},
        {"\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\u00d8\u00dc\uff00\u0100"), true, true, 8},
        {"\x00\xd8\x00\xdc\xff\x00\x01\x00", NSTR("\u00d8\u00dc\uff00\u0100"), false, false, 8},
        {"\xd8\x00\xdc\x00\x00\xff\x00\x01", NSTR("\u00d8\u00dc\uff00\u0100"), false, true, 8},

        {"\xff\xfe", NSTR(""), true, true, 2},
        {"\xfe\xff", NSTR(""), true, false, 2},
        {"", NSTR(""), true, true, 0},
        {"", NSTR(""), true, false, 0},
        {"", NSTR(""), false, true, 0},
        {"", NSTR(""), false, false, 0},
    };

    for (auto&& vec : testVectors) {
        auto res = decodeUTF16(vm, {vec.encoded, vec.length},
                               vec.isLittleEndian, vec.hasBom);
        EXPECT_EQ(LString<nchar>(vec.decoded), res);
        res.free(vm);
    }
}

TEST_F(CodersTest, DecodeUTF16_Fail) {
    auto res = decodeUTF16(vm, "\x12\x34\x56", false, false);
    EXPECT_EQ(UnicodeErrorReason::truncated, res.error);

    res = decodeUTF16(vm, "\xd8\x01", false, false);
    EXPECT_EQ(UnicodeErrorReason::truncated, res.error);

    res = decodeUTF16(vm, "\xd8\x01\x01\x01", false, false);
    EXPECT_EQ(UnicodeErrorReason::invalidUTF16, res.error);
}

TEST_F(CodersTest, EncodeUTF32) {
    TestVector testVectors[] = {
        {"\xff\xfe\0\0" "f\0\0\0o\0\0\0o\0\0\0", NSTR("foo"), true, true, 16},
        {"\0\0\xfe\xff" "\0\0\0f\0\0\0o\0\0\0o", NSTR("foo"), true, false, 16},
        {"f\0\0\0o\0\0\0o\0\0\0", NSTR("foo"), false, true, 12},
        {"\0\0\0f\0\0\0o\0\0\0o", NSTR("foo"), false, false, 12},
        {"\xff\xfe\0\0\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", NSTR("\U00010000\u00ff\u0001"), true, true, 16},
        {"\0\0\xfe\xff\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", NSTR("\U00010000\u00ff\u0001"), true, false, 16},
        {"\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", NSTR("\U00010000\u00ff\u0001"), false, true, 12},
        {"\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", NSTR("\U00010000\u00ff\u0001"), false, false, 12},
        {"\xff\xfe\0\0", NSTR(""), true, true, 4},
        {"\0\0\xfe\xff", NSTR(""), true, false, 4},
        {"", NSTR(""), false, true, 0},
        {"", NSTR(""), false, false, 0},
    };

    for (auto&& vec : testVectors) {
        auto res = encodeUTF32(vm, vec.decoded, vec.isLittleEndian, vec.hasBom);
        EXPECT_EQ(LString<char>(vec.encoded, vec.length), res);
        res.free(vm);
    }
}

TEST_F(CodersTest, DecodeUTF32) {
    TestVector testVectors[] = {
        {"\xff\xfe\0\0" "f\0\0\0o\0\0\0o\0\0\0", NSTR("foo"), true, true, 16},
        {"\0\0\xfe\xff" "\0\0\0f\0\0\0o\0\0\0o", NSTR("foo"), true, false, 16},
        {"\xff\xfe\0\0" "f\0\0\0o\0\0\0o\0\0\0", NSTR("foo"), true, false, 16},
        {"\0\0\xfe\xff" "\0\0\0f\0\0\0o\0\0\0o", NSTR("foo"), true, true, 16},
        {"\xff\xfe\0\0" "f\0\0\0o\0\0\0o\0\0\0", NSTR("\ufefffoo"), false, true, 16},
        {"\0\0\xfe\xff" "\0\0\0f\0\0\0o\0\0\0o", NSTR("\ufefffoo"), false, false, 16},
        {"\x00\x02\x01\x00", NSTR("\U00020100"), true, false, 4},
        {"\x00\x02\x01\x00", NSTR("\U00010200"), true, true, 4},
        {"f\0\0\0o\0\0\0o\0\0\0", NSTR("foo"), true, true, 12},
        {"\0\0\0f\0\0\0o\0\0\0o", NSTR("foo"), true, false, 12},
        {"f\0\0\0o\0\0\0o\0\0\0", NSTR("foo"), false, true, 12},
        {"\0\0\0f\0\0\0o\0\0\0o", NSTR("foo"), false, false, 12},
        {"\xff\xfe\0\0\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", NSTR("\U00010000\u00ff\u0001"), true, true, 16},
        {"\0\0\xfe\xff\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", NSTR("\U00010000\u00ff\u0001"), true, false, 16},
        {"\xff\xfe\0\0\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", NSTR("\U00010000\u00ff\u0001"), true, false, 16},
        {"\0\0\xfe\xff\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", NSTR("\U00010000\u00ff\u0001"), true, true, 16},
        {"\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", NSTR("\U00010000\u00ff\u0001"), false, true, 12},
        {"\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", NSTR("\U00010000\u00ff\u0001"), false, false, 12},
        {"\x00\x00\x01\0\xff\0\0\0\x01\0\0\0", NSTR("\U00010000\u00ff\u0001"), true, true, 12},
        {"\0\x01\x00\x00\0\0\0\xff\0\0\0\x01", NSTR("\U00010000\u00ff\u0001"), true, false, 12},
        {"\xff\xfe\0\0", NSTR(""), true, true, 4},
        {"\0\0\xfe\xff", NSTR(""), true, false, 4},
        {"\xff\xfe\0\0", NSTR("\ufeff"), false, true, 4},
        {"\0\0\xfe\xff", NSTR("\ufeff"), false, false, 4},
        {"", NSTR(""), true, true, 0},
        {"", NSTR(""), true, false, 0},
        {"", NSTR(""), false, true, 0},
        {"", NSTR(""), false, false, 0},
    };

    for (auto&& vec : testVectors) {
        auto res = decodeUTF32(vm, {vec.encoded, vec.length},
                               vec.isLittleEndian, vec.hasBom);
        EXPECT_EQ(LString<nchar>(vec.decoded), res);
        res.free(vm);
    }
}

TEST_F(CodersTest, DecodeUTF32_Fail) {
    auto res = decodeUTF32(vm, "\1\1\1\1", false, false);
    EXPECT_EQ(UnicodeErrorReason::outOfRange, res.error);

    res = decodeUTF32(vm, LString<char>("\0\0\0\1\0", 5), false, false);
    EXPECT_EQ(UnicodeErrorReason::truncated, res.error);
}


