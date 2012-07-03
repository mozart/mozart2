#include "mozart.hh"
#include <gtest/gtest.h>
#include "testutils.hh"

using namespace mozart;

namespace std {
    template <class T, class U, class V, class W>
    static bool operator==(const pair<T, U>& a, const pair<V, W>& b) noexcept {
        return a.first == b.first && a.second == b.second;
    }
}
// ^ This needs to be defined in std namespace in order to make ADL work.

class UTFTest : public MozartTest {};

TEST_F(UTFTest, ToUTF_8) {
    char buf[4];
    EXPECT_EQ(1, toUTF(U'\0', buf));
    EXPECT_EQ(0, buf[0]);

    EXPECT_EQ(1, toUTF(U'\x7f', buf));
    EXPECT_EQ('\x7f', buf[0]);

    EXPECT_EQ(2, toUTF(U'\u0080', buf));
    EXPECT_EQ('\xc2', buf[0]);
    EXPECT_EQ('\x80', buf[1]);

    EXPECT_EQ(2, toUTF(U'\u07ff', buf));
    EXPECT_EQ('\xdf', buf[0]);
    EXPECT_EQ('\xbf', buf[1]);

    EXPECT_EQ(3, toUTF(U'\u0800', buf));
    EXPECT_EQ('\xe0', buf[0]);
    EXPECT_EQ('\xa0', buf[1]);
    EXPECT_EQ('\x80', buf[2]);

    EXPECT_EQ(3, toUTF(U'\ud7ff', buf));
    EXPECT_EQ('\xed', buf[0]);
    EXPECT_EQ('\x9f', buf[1]);
    EXPECT_EQ('\xbf', buf[2]);

    EXPECT_EQ(3, toUTF(U'\ue000', buf));
    EXPECT_EQ('\xee', buf[0]);
    EXPECT_EQ('\x80', buf[1]);
    EXPECT_EQ('\x80', buf[2]);

    EXPECT_EQ(3, toUTF(U'\ufffe', buf));
    EXPECT_EQ('\xef', buf[0]);
    EXPECT_EQ('\xbf', buf[1]);
    EXPECT_EQ('\xbe', buf[2]);

    EXPECT_EQ(3, toUTF(U'\uffff', buf));
    EXPECT_EQ('\xef', buf[0]);
    EXPECT_EQ('\xbf', buf[1]);
    EXPECT_EQ('\xbf', buf[2]);

    EXPECT_EQ(4, toUTF(U'\U00010000', buf));
    EXPECT_EQ('\xf0', buf[0]);
    EXPECT_EQ('\x90', buf[1]);
    EXPECT_EQ('\x80', buf[2]);
    EXPECT_EQ('\x80', buf[3]);

    EXPECT_EQ(4, toUTF(U'\U0010ffff', buf));
    EXPECT_EQ('\xf4', buf[0]);
    EXPECT_EQ('\x8f', buf[1]);
    EXPECT_EQ('\xbf', buf[2]);
    EXPECT_EQ('\xbf', buf[3]);

    EXPECT_EQ(UnicodeErrorReason::surrogate, toUTF(0xd800, buf));
    EXPECT_EQ(UnicodeErrorReason::surrogate, toUTF(0xdbff, buf));
    EXPECT_EQ(UnicodeErrorReason::surrogate, toUTF(0xdc00, buf));
    EXPECT_EQ(UnicodeErrorReason::surrogate, toUTF(0xdfff, buf));
    EXPECT_EQ(UnicodeErrorReason::outOfRange, toUTF(0x110000, buf));
}

TEST_F(UTFTest, ToUTF_16) {
    char16_t buf[2];
    EXPECT_EQ(1, toUTF(U'\0', buf));
    EXPECT_EQ(0, buf[0]);

    EXPECT_EQ(1, toUTF(U'\x7f', buf));
    EXPECT_EQ(u'\x7f', buf[0]);

    EXPECT_EQ(1, toUTF(U'\ue000', buf));
    EXPECT_EQ(u'\ue000', buf[0]);

    EXPECT_EQ(1, toUTF(U'\ufffe', buf));
    EXPECT_EQ(u'\ufffe', buf[0]);

    EXPECT_EQ(1, toUTF(U'\uffff', buf));
    EXPECT_EQ(0xffff, buf[0]);

    EXPECT_EQ(2, toUTF(U'\U00010000', buf));
    EXPECT_EQ(0xd800, buf[0]);
    EXPECT_EQ(0xdc00, buf[1]);

    EXPECT_EQ(2, toUTF(U'\U0010ffff', buf));
    EXPECT_EQ(0xdbff, buf[0]);
    EXPECT_EQ(0xdfff, buf[1]);

    EXPECT_EQ(UnicodeErrorReason::surrogate, toUTF(0xd800, buf));
    EXPECT_EQ(UnicodeErrorReason::surrogate, toUTF(0xdbff, buf));
    EXPECT_EQ(UnicodeErrorReason::surrogate, toUTF(0xdc00, buf));
    EXPECT_EQ(UnicodeErrorReason::surrogate, toUTF(0xdfff, buf));
    EXPECT_EQ(UnicodeErrorReason::outOfRange, toUTF(0x110000, buf));
}

TEST_F(UTFTest, FromUTF_8) {
    EXPECT_EQ(std::make_pair(U'a', 1), fromUTF("abc"));
    EXPECT_EQ(std::make_pair(U'b', 1), fromUTF("bc"));
    EXPECT_EQ(std::make_pair(U'\u00a9', 2), fromUTF("\xc2\xa9"));
    EXPECT_EQ(std::make_pair(U'\u2260', 3), fromUTF("\xe2\x89\xa0"));
    EXPECT_EQ(std::make_pair(U'\ufffe', 3), fromUTF("\xef\xbf\xbe"));
    EXPECT_EQ(std::make_pair(U'\uffff', 3), fromUTF("\xef\xbf\xbf"));
    EXPECT_EQ(std::make_pair(U'\U00010000', 4), fromUTF("\xf0\x90\x80\x80"));
    EXPECT_EQ(std::make_pair(U'\U0010ffff', 4), fromUTF("\xf4\x8f\xbf\xbf"));
    EXPECT_EQ(std::make_pair(U'\ud7ff', 3), fromUTF("\xed\x9f\xbf"));
    EXPECT_EQ(std::make_pair(U'\0', 1), fromUTF("\0", 1));

    // invalid continuation byte
    EXPECT_EQ(UnicodeErrorReason::invalidUTF8, fromUTF("\xe2\x89\0").second);
    // invalid leading byte
    EXPECT_EQ(UnicodeErrorReason::invalidUTF8, fromUTF("\xc0\x8a").second);
    // invalid range (e0 80 8a decodes to something less than U+0800)
    EXPECT_EQ(UnicodeErrorReason::invalidUTF8, fromUTF("\xe0\x80\x8a").second);
    // invalid range
    EXPECT_EQ(UnicodeErrorReason::invalidUTF8, fromUTF("\xf0\x80\x80\x8a").second);
    // not unicode
    EXPECT_EQ(UnicodeErrorReason::outOfRange, fromUTF("\xf8\x80\x80\x80\x80").second);
    // not unicode
    EXPECT_EQ(UnicodeErrorReason::outOfRange, fromUTF("\xfc\x80\x80\x80\x80\x80").second);
    // not unicode (0x110000)
    EXPECT_EQ(UnicodeErrorReason::outOfRange, fromUTF("\xf4\x90\x80\x80").second);
    // lead surrogate
    EXPECT_EQ(UnicodeErrorReason::surrogate, fromUTF("\xed\xa0\x80").second);
    // trail surrogate
    EXPECT_EQ(UnicodeErrorReason::surrogate, fromUTF("\xed\xbf\xbf").second);
    // invalid leading byte
    EXPECT_EQ(UnicodeErrorReason::invalidUTF8, fromUTF("\x80\x80\x80").second);
    // invalid leading byte
    EXPECT_EQ(UnicodeErrorReason::invalidUTF8, fromUTF("\xbf\xbf\xbf").second);
    // invalid continuation byte
    EXPECT_EQ(UnicodeErrorReason::invalidUTF8, fromUTF("\xc2\xc2\xc2").second);
    // truncated
    EXPECT_EQ(UnicodeErrorReason::truncated, fromUTF("\xc2", 1).second);
}

TEST_F(UTFTest, FromUTF_16) {
    EXPECT_EQ(std::make_pair(U'a', 1), fromUTF(u"abc"));
    EXPECT_EQ(std::make_pair(U'b', 1), fromUTF(u"bc"));
    EXPECT_EQ(std::make_pair(U'\u00a9', 1), fromUTF(u"\u00a9"));
    EXPECT_EQ(std::make_pair(U'\u2260', 1), fromUTF(u"\u2260"));
    EXPECT_EQ(std::make_pair(U'\ufffe', 1), fromUTF(u"\ufffe"));
    EXPECT_EQ(std::make_pair(U'\0', 1), fromUTF(u"\0", 1));


    // Note: http://gcc.gnu.org/bugzilla/show_bug.cgi?id=41698
    char16_t buf[2] = {0xffff, 0};
    EXPECT_EQ(std::make_pair(U'\uffff', 1), fromUTF(buf));

    // Can't use u"\ud800\udc00" to write a surrogate pair
    buf[0] = 0xd800; buf[1] = 0xdc00;
    EXPECT_EQ(std::make_pair(U'\U00010000', 2), fromUTF(buf));

    buf[0] = 0xdbff; buf[1] = 0xdfff;
    EXPECT_EQ(std::make_pair(U'\U0010ffff', 2), fromUTF(buf));

    buf[0] = 0xd800; buf[1] = 0xd800;
    EXPECT_EQ(UnicodeErrorReason::invalidUTF16, fromUTF(buf).second);  // invalid trail surrogate
    buf[0] = 0xdc00; buf[1] = 0xdc00;
    EXPECT_EQ(UnicodeErrorReason::invalidUTF16, fromUTF(buf).second);  // invalid lead surrogate
    buf[0] = 0xd800; buf[1] = 1;
    EXPECT_EQ(UnicodeErrorReason::invalidUTF16, fromUTF(buf).second);  // invalid trail surrogate
    buf[0] = 0xdc00; buf[1] = 1;
    EXPECT_EQ(UnicodeErrorReason::invalidUTF16, fromUTF(buf).second);  // invalid lead surrogate
    buf[0] = 0xd800;
    EXPECT_EQ(UnicodeErrorReason::truncated, fromUTF(buf, 1).second);  // truncated
}

TEST_F(UTFTest, ToUTF) {
    #define MAKE_TEST_CASE(String) \
        EXPECT_EQ(u8##String, toUTF<char>(makeLString(u8##String))); \
        EXPECT_EQ(u8##String, toUTF<char>(makeLString(u##String))); \
        EXPECT_EQ(u8##String, toUTF<char>(makeLString(U##String))); \
        EXPECT_EQ(u##String, toUTF<char16_t>(makeLString(u8##String))); \
        EXPECT_EQ(u##String, toUTF<char16_t>(makeLString(u##String))); \
        EXPECT_EQ(u##String, toUTF<char16_t>(makeLString(U##String))); \
        EXPECT_EQ(U##String, toUTF<char32_t>(makeLString(u8##String))); \
        EXPECT_EQ(U##String, toUTF<char32_t>(makeLString(u##String))); \
        EXPECT_EQ(U##String, toUTF<char32_t>(makeLString(U##String)))

    MAKE_TEST_CASE("abc");
    MAKE_TEST_CASE("a\u0300\u0080");
    MAKE_TEST_CASE("\ufffe\ue000\u0800");
    MAKE_TEST_CASE("\U00010000\U00020000@\U0010ffff");
    MAKE_TEST_CASE("");

    #undef MAKE_TEST_CASE
}

/*
TEST_F(UTFTest, ToLatin1) {
    EXPECT_EQ(LString<char>("a\xe1\x80\1c"), toLatin1(vm, MOZART_STR("a\u00e1\u0080\u0001c")));
    EXPECT_EQ(LString<char>("\x01\x12???"), toLatin1(vm, MOZART_STR("\u0001\u0012\u0123\u1234\U00012345")));
    EXPECT_EQ(LString<char>(), toLatin1(vm, MOZART_STR("")));
    EXPECT_EQ(LString<char>("\0\0", 2), toLatin1(vm, LString<nchar>(MOZART_STR("\0\0"), 2)));
}

TEST_F(UTFTest, FromLatin1) {
    EXPECT_EQ(LString<nchar>(MOZART_STR("a\u00e1\u0080\u0001c")), fromLatin1(vm, "a\xe1\x80\1c"));
    EXPECT_EQ(LString<nchar>(), fromLatin1(vm, ""));
    EXPECT_EQ(LString<nchar>(MOZART_STR("\0\0"), 2), fromLatin1(vm, LString<char>("\0\0", 2)));
}
*/

TEST_F(UTFTest, CompareByCodePoint) {
    #define MAKE_TEST_CASE(P, C) \
        EXPECT_EQ(0, compareByCodePoint(P##"foo", P##"foo")); \
        EXPECT_EQ(0, compareByCodePoint(P##"foo", P##"foo")); \
        EXPECT_EQ(0, compareByCodePoint(P##"\u1234\U00012345", P##"\u1234\U00012345")); \
        EXPECT_LT(compareByCodePoint(P##"bar", P##"foo"), 0); \
        EXPECT_LT(compareByCodePoint(P##"\u1234\u5678", P##"\U00010000"), 0); \
        EXPECT_GT(compareByCodePoint(P##"foo", P##"bar"), 0); \
        EXPECT_GT(compareByCodePoint(P##"\u1234\U00010000", P##"\u1234\uffff"), 0); \
        EXPECT_GT(compareByCodePoint(P##"aa", P##"a"), 0); \
        EXPECT_LT(compareByCodePoint(P##"", makeLString(P##"\0", 1)), 0); \
        EXPECT_EQ(0, compareByCodePoint(P##"", P##""))

    MAKE_TEST_CASE(u8, char);
    MAKE_TEST_CASE(u, char16_t);
    MAKE_TEST_CASE(U, char32_t);

    #undef MAKE_TEST_CASE

    EXPECT_GT(compareByCodePoint(makeLString(u8"\U00010000\0", 5), u8"\U00010000"), 0);
    EXPECT_GT(compareByCodePoint(makeLString(u"\U00010000\0", 3), u"\U00010000"), 0);
    EXPECT_GT(compareByCodePoint(makeLString(U"\U00010000\0", 2), U"\U00010000"), 0);
}

TEST_F(UTFTest, GetUTFStride) {
    EXPECT_EQ(1, getUTFStride(u8"a"));
    EXPECT_EQ(2, getUTFStride(u8"\u0080"));
    EXPECT_EQ(2, getUTFStride(u8"\u07ff"));
    EXPECT_EQ(3, getUTFStride(u8"\u0800"));
    EXPECT_EQ(3, getUTFStride(u8"\ud7ff"));
    EXPECT_EQ(3, getUTFStride(u8"\ue000"));
    EXPECT_EQ(3, getUTFStride(u8"\ufffe"));
    EXPECT_EQ(4, getUTFStride(u8"\U00010000"));
    EXPECT_EQ(4, getUTFStride(u8"\U0010ffff"));
    EXPECT_EQ(1, getUTFStride(u8"\0"));
    EXPECT_EQ(UnicodeErrorReason::outOfRange, getUTFStride("\xff"));

    EXPECT_EQ(1, getUTFStride(u"a"));
    EXPECT_EQ(1, getUTFStride(u"\u0080"));
    EXPECT_EQ(1, getUTFStride(u"\ud7ff"));
    EXPECT_EQ(1, getUTFStride(u"\ue000"));
    EXPECT_EQ(1, getUTFStride(u"\ufffe"));
    EXPECT_EQ(2, getUTFStride(u"\U00010000"));
    EXPECT_EQ(2, getUTFStride(u"\U0010ffff"));
    EXPECT_EQ(1, getUTFStride(u"\0"));

    char16_t invalid[] = {0xdc00};
    EXPECT_EQ(UnicodeErrorReason::invalidUTF16, getUTFStride(invalid));
}

TEST_F(UTFTest, CodePointCount) {
    EXPECT_EQ(3, codePointCount(makeLString(u8"asd", 3)));
    EXPECT_EQ(2, codePointCount(makeLString(u8"asd", 2)));
    EXPECT_EQ(5, codePointCount(makeLString(u8"\u0008\u0080\u0800\u8000\U00080000", 13)));
    EXPECT_EQ(2, codePointCount(makeLString(u8"\0\0", 2)));

    EXPECT_EQ(3, codePointCount(makeLString(u"asd", 3)));
    EXPECT_EQ(2, codePointCount(makeLString(u"asd", 2)));
    EXPECT_EQ(5, codePointCount(makeLString(u"\u0008\u0080\u0800\u8000\U00080000", 6)));
    EXPECT_EQ(2, codePointCount(makeLString(u"\0\0", 2)));

    EXPECT_EQ(3, codePointCount(makeLString(U"asd", 3)));
    EXPECT_EQ(2, codePointCount(makeLString(U"asd", 2)));
    EXPECT_EQ(5, codePointCount(makeLString(U"\u0008\u0080\u0800\u8000\U00080000", 5)));
    EXPECT_EQ(2, codePointCount(makeLString(U"\0\0", 2)));
}

TEST_F(UTFTest, SliceByCodePoints) {
    #define DO_TEST(p) \
        EXPECT_EQ(newLString(p##"bcd"), \
                  sliceByCodePoints(newLString(p##"abcd"), 1, 0)); \
        EXPECT_EQ(newLString(p##"\U00012345\u1234\U00065432\u0065"), \
                  sliceByCodePoints(newLString(p##"\U00012345\u1234\U00065432\u0065"), 0, 0)); \
        EXPECT_EQ(newLString(p##"\u1234\U00065432\u0065"), \
                  sliceByCodePoints(newLString(p##"\U00012345\u1234\U00065432\u0065"), 1, 0)); \
        EXPECT_EQ(newLString(p##"\u0065"), \
                  sliceByCodePoints(newLString(p##"\U00012345\u1234\U00065432\u0065"), 3, 0)); \
        EXPECT_EQ(newLString(p##"\U00012345\u1234\U00065432"), \
                  sliceByCodePoints(newLString(p##"\U00012345\u1234\U00065432\u0065"), 0, 1)); \
        EXPECT_EQ(newLString(p##"\U00012345"), \
                  sliceByCodePoints(newLString(p##"\U00012345\u1234\U00065432\u0065"), 0, 3)); \
        EXPECT_EQ(newLString(p##"\u1234\U00065432"), \
                  sliceByCodePoints(newLString(p##"\U00012345\u1234\U00065432\u0065"), 1, 1)); \
        EXPECT_EQ(UnicodeErrorReason::indexOutOfBounds, \
                  sliceByCodePoints(newLString(p##"\U00012345"), 2, 0).error); \
        EXPECT_EQ(UnicodeErrorReason::indexOutOfBounds, \
                  sliceByCodePoints(newLString(p##"\U00012345"), 0, 2).error); \
        EXPECT_EQ(UnicodeErrorReason::indexOutOfBounds, \
                  sliceByCodePoints(newLString(p##"\U00012345"), 1, 1).error); \
        EXPECT_EQ(0, sliceByCodePoints(newLString(p##"\U00012345"), 1, 0).length); \
        EXPECT_EQ(0, sliceByCodePoints(newLString(p##"\U00012345"), 0, 1).length); \
        EXPECT_EQ(0, sliceByCodePoints(newLString(p##"pq"), 1, 1).length)

    DO_TEST(u8);
    DO_TEST(u);
    DO_TEST(U);

    #undef DO_TEST


}


