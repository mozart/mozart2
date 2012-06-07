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

#include <vector>

#include "core-forward-decl.hh"
#include "lstring-decl.hh"

namespace mozart {

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
inline nativeint toUTF(char32_t character, char utf[4]);
inline nativeint toUTF(char32_t character, char16_t utf[2]);
inline nativeint toUTF(char32_t character, char32_t utf[1]);

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
inline std::pair<char32_t, nativeint> fromUTF(const char* utf,
                                              nativeint length = 4);
inline std::pair<char32_t, nativeint> fromUTF(const char16_t* utf,
                                              nativeint length = 2);
inline std::pair<char32_t, nativeint> fromUTF(const char32_t* utf,
                                              nativeint length = 1);

/**
 * Convert between two kinds of UTF sequences. The memory will be allocated from
 * the virtual machine heap. A copy will always be made on the VM heap.
 */
template <class To, class From>
inline LString<To> toUTF(VM vm, LString<From> input);

/**
 * Compare two strings by code-point order (without considering locale-specific
 * collation, normalization, etc.)
 */
template <class C>
inline int compareByCodePoint(LString<C> a, LString<C> b);

template <class C>
inline int compareByCodePoint(const C* a, LString<C> b) {
  return compareByCodePoint(LString<C>(a), b);
}

template <class C>
inline int compareByCodePoint(LString<C> a, const C* b) {
  return compareByCodePoint(a, LString<C>(b));
}

template <class C>
inline int compareByCodePoint(const C* a, const C* b) {
  return compareByCodePoint(LString<C>(a), LString<C>(b));
}

/**
 * Get the number of code units is needed to form a character. This is more
 * efficient than fromUTF() if decoding is not required, but it will also not
 * report if the trailing units is invalid.
 *
 * If the conversion failed, a negative number of type UnicodeErrorReason will
 * be returned.
 */
inline nativeint getUTFStride(const char* utf);
inline nativeint getUTFStride(const char16_t* utf);
inline nativeint getUTFStride(const char32_t* utf);

/**
 * Count the number of code points in the UTF string. These functions do not
 * attempt to validate if the input is valid.
 */
inline nativeint codePointCount(LString<char> input);
inline nativeint codePointCount(LString<char16_t> input);
inline nativeint codePointCount(LString<char32_t> input);

}

#endif // __UTF_DECL_H
