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
#include <vector>
#include <cstring>
#include <type_traits>
#include <ostream>

namespace mozart {

////////////////////////
// UnicodeErrorReason //
////////////////////////

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

//////////////////////////////////////
// LString - Length-prefixed string //
//////////////////////////////////////

template <class C>
struct FreeableLString;

template <class C>
struct LString {
private:
    const C* _string;
    union {
        nativeint _length;
        UnicodeErrorReason _error;
    };

    void reset();

    friend struct FreeableLString<C>;

public:
    /// Whether this string contains an error.
    constexpr bool isError() const { return _length < 0; }

    /// Whether this string is empty or contains an error.
    constexpr bool isErrorOrEmpty() const { return _length <= 0; }

    /// Number of bytes occupied by the string.
    constexpr size_t bytesCount() const { return _length * sizeof(C); }

    /// Range interface - Beginning and end
    const C* begin() const { return _string; }
    const C* end() const { return _string + _length; }

    /// Properties.
    const C* string() const { return _string; }
    constexpr nativeint length() const { return _length; }
    constexpr UnicodeErrorReason error() const { return _error; }

    /// Indexing.
    C operator[](nativeint i) const { return _string[i]; }

    /// Initialize as empty string.
    constexpr LString() : _string(nullptr), _length(0) {}

    /// Initialize as error.
    constexpr LString(UnicodeErrorReason error) : _string(nullptr), _error(error) {}

    /// Initialize from immutable, ever-lasting C string (with length).
    LString(const C* s) : _string(s), _length(std::char_traits<C>::length(s)) {}
    LString(const C* s, nativeint len) : _string(s), _length(len) {}

    /// An LString is not copyable, but is movable.
    LString(const LString&) = delete;
    LString& operator=(const LString&) = delete;
    LString(LString&& other);
    LString& operator=(LString&&);

    // Equalities
    bool operator==(const LString& other) const;
    bool operator!=(const LString& other) const;

    /// Create a new reference of LString to the same string as this. This
    /// operation is unsafe, as there is now alasing. If one owner changes the
    /// content, the other one will also see the change, causing some unintended
    /// effects. This is safe if one can guarantee that the string is immutable.
    LString unsafeAlias() const { return LString(_string, _length); }

    /// Work on a substring.
    template <class F>
    auto withSubstring(nativeint from, const F& f) const -> decltype(f(*this)) {
        const LString<C> copy (_string + from, _length - from);
        return f(copy);
    }

    template <class F>
    auto withSubstring(nativeint from, nativeint to, const F& f) const -> decltype(f(*this)) {
        const LString<C> copy (_string + from, to - from);
        return f(copy);
    }
};

/// Convenient methods to create from C string (with length).
template <class C>
static inline LString<C> makeLString(const C* s, nativeint len) {
    return LString<C>(s, len);
}
template <class C>
static inline LString<C> makeLString(const C* s) {
    return LString<C>(s);
}


///////////////////////////////////////////////////////////////////
// FreeableLString - String which can be deterministically freed //
///////////////////////////////////////////////////////////////////

// Note: FreeableLString is a subclass of LString. It is safe to object-slice
//       a FreeableLString into an LString. The string will just become garbage
//       collected instead of deterministically destroyable.

template <class C>
struct FreeableLString : LString<C> {
    template <class K>
    friend void free(FreeableLString<K>&& string);
    template <class>
    friend FreeableLString<C> newLString(VM vm, const LString<C>& from);

    /// Initialize from pre-malloced memory and do some initialization on it.
    template <class F>
    FreeableLString(VM vm, nativeint length, const F& modifier);

    /// Rest of the constructors inherited from the base.
    FreeableLString(UnicodeErrorReason e) : LString<C>(e), _vm(nullptr) {}

private:
    VM _vm;

    void doFree();
};

template <class C>
static void free(FreeableLString<C>&& string) { string.doFree(); }

template <class C>
static FreeableLString<C> newLString(VM vm, const LString<C>& from);

template <class C>
static FreeableLString<C> newLString(VM vm, const std::vector<C>& vector);

template <class C>
static FreeableLString<C> newLString(VM vm, const std::basic_string<C>& cppStr);

template <class C>
static FreeableLString<C> newLString(VM vm, const C* cStr);

/// Write the string to an output stream.
template <class C>
static std::basic_ostream<C>& operator<<(std::basic_ostream<C>& out,
                                         const mozart::LString<C>& input);

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
static FreeableLString<To> toUTF(VM vm, const LString<From>& input);

/**
 * Convert between a string of Latin-1 (ISO-8859-1) string and native character
 * string.
 *
 * When a Unicode character is outside of the range of 0 -- 255, it will be
 * replaced by the character '?'.
 *
 * If the covnersion failed, (nullptr, invalidLength) will be returned.
 */
static FreeableLString<char> toLatin1(VM vm, const LString<nchar>& input);
static FreeableLString<nchar> fromLatin1(VM vm, const LString<char>& input);

/**
 * Compare two strings by code-point order (without considering locale-specific
 * collation, normalization, etc.)
 */
template <class C>
inline static int compareByCodePoint(const LString<C>& a, const LString<C>& b);

template <class C>
inline static int compareByCodePoint(const C* a, const LString<C>& b) {
  return compareByCodePoint(makeLString(a), b);
}

template <class C>
inline static int compareByCodePoint(const LString<C>& a, const C* b) {
  return compareByCodePoint(a, makeLString(b));
}

template <class C>
inline static int compareByCodePoint(const C* a, const C* b) {
  return compareByCodePoint(makeLString(a), makeLString(b));
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
static nativeint codePointCount(const LString<char>& input);
static nativeint codePointCount(const LString<char16_t>& input);
static nativeint codePointCount(const LString<char32_t>& input);

}

#endif

