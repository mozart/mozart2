// Copyright © 2012, Université catholique de Louvain
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// *  Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// *  Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#ifndef __UTF_DECL_H
#define __UTF_DECL_H

#include "mozartcore-decl.hh"
#include <utility>
#include <string>
#include <cstring>
#include <type_traits>
#include <ostream>

namespace mozart {

/////////////
// LString //
/////////////

/**
 * An integer indicating the string pair contains a surrogate character.
 */
enum UnicodeErrorReason : nativeint {
    empty = 0,         // not really an error...
    outOfRange = -1,   // the code point is outside of the valid range 0 -- 0x10ffff
    surrogate = -2,    // the code point refers to a surrogate 0xd800 -- 0xdfff
    invalidUTF8 = -3,  // an invalid UTF-8 sequence is provided.
    invalidUTF16 = -4, // an invalid UTF-16 sequence is provided.
    truncated = -5,    // the data is truncated such that an incomplete code unit exists.

    invalidUTFNative   // an invalid UTF sequence (based on nchar) is provided
        = std::is_same<nchar, char16_t>::value ? invalidUTF16 :
          std::is_same<nchar, char>::value ? invalidUTF8 : outOfRange
};

template <class C>
struct LString {    // LString = Length-prefixed string.
    const C* string;
    union {
        nativeint length;
        UnicodeErrorReason error;
    };

    bool isError() const { return length < 0; }
    bool isErrorOrEmpty() const { return length <= 0; }

    size_t bytesCount() const { return length * sizeof(C); }

    const C* begin() const { return string; }
    const C* end() const { return string + length; }

    C operator[](nativeint i) const { return string[i]; }

    /**
     * Free a string previously allocated from toUTF, fromLatin1 or toLatin1.
     */
    inline
    void free(VM vm);

    LString() : string(nullptr), length(0) {}
    LString(UnicodeErrorReason error) : string(nullptr), error(error) {}
    LString(const C* s) : string(s), length(std::char_traits<C>::length(s)) {}
    LString(const C* s, nativeint len) : string(s), length(len) {}
    LString(const LString&) = default;

    /**
     * Create a copy allocated on the VM heap.
     */
    inline
    LString(VM vm, LString<C> other);
};

/**
 * Write the string to an output stream.
 */
template <class C>
static std::basic_ostream<C>& operator<<(std::basic_ostream<C>& out, LString<C> input);

template <class C>
static bool operator==(LString<C> a, LString<C> b);

template <class C>
static bool operator!=(LString<C> a, LString<C> b);

/////////////////////////////////
// Unicode encoding conversion //
/////////////////////////////////

/**
 * Convert a Unicode character to a UTF string.
 *
 * @param character
 *      The Unicode character. It must be between 0 to 0x10ffff.
 * @param utf
 *      An array buffer of UTF code units to store this character.
 * @return
 *      How many code units are used. If the character is invalid, a negative
 *      number (of type UnicodeErrorReason) will be returned.
 */
static nativeint toUTF(char32_t character, char utf[4]);
static nativeint toUTF(char32_t character, char16_t utf[2]);
static nativeint toUTF(char32_t character, char32_t utf[1]);

/**
 * Convert a UTF string to a Unicode character
 *
 * @param utf
 *      An array buffer of UTF code units to extract a character.
 * @param length
 *      The length of the input buffer. It must be positive (> 0).
 * @return
 *      The Unicode character and how many code units are used. If the UTF
 *      sequence is invalid, the number of code units used will be negative of
 *      type UnicodeErrorReason.
 */
static std::pair<char32_t, nativeint> fromUTF(const char* utf, nativeint length = 4);
static std::pair<char32_t, nativeint> fromUTF(const char16_t* utf, nativeint length = 2);
static std::pair<char32_t, nativeint> fromUTF(const char32_t* utf, nativeint length = 1);

/**
 * Convert between two kinds of UTF sequences. The memory will be allocated from
 * the virtual machine heap. A copy will always be made on the VM heap.
 */
template <class To, class From>
static LString<To> toUTF(VM vm, LString<From> input);

/**
 * Convert between a string of Latin-1 (ISO-8859-1) string and native character
 * string.
 *
 * When a Unicode character is outside of the range of 0 -- 255, it will be
 * replaced by the character '?'.
 *
 * If the covnersion failed, (nullptr, invalidLength) will be returned.
 */
static LString<char> toLatin1(VM vm, LString<nchar> input);
static LString<nchar> fromLatin1(VM vm, LString<char> input);

/**
 * Compare two strings by code-point order (without considering locale-specific
 * collation, normalization, etc.)
 */
template <class C>
inline static int compareByCodePoint(LString<C> a, LString<C> b);

template <class C>
inline static int compareByCodePoint(const C* a, LString<C> b) {
  return compareByCodePoint(LString<C>(a), b);
}

template <class C>
inline static int compareByCodePoint(LString<C> a, const C* b) {
  return compareByCodePoint(a, LString<C>(b));
}

template <class C>
inline static int compareByCodePoint(const C* a, const C* b) {
  return compareByCodePoint(LString<C>(a), LString<C>(b));
}

/**
 * Get the number of code units is needed to form a character. This is more
 * effecient than fromUTF() if decoding is not required, but it will also not
 * report if the trailing units is invalid.
 *
 * If the conversion failed, a negative number of type UnicodeErrorReason will
 * be returned.
 */
static nativeint getUTFStride(const char* utf);
static nativeint getUTFStride(const char16_t* utf);
static nativeint getUTFStride(const char32_t* utf);

/**
 * Count the number of code points in the UTF string. These functions do not
 * attempt to validate if the input is valid.
 */
static nativeint codePointCount(LString<char> input);
static nativeint codePointCount(LString<char16_t> input);
static nativeint codePointCount(LString<char32_t> input);

}

#endif

