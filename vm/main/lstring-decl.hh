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

#ifndef __LSTRING_DECL_H
#define __LSTRING_DECL_H

#include <utility>
#include <string>
#include <cstring>
#include <type_traits>
#include <ostream>

#include "core-forward-decl.hh"

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

  invalidUTFNative = // an invalid UTF sequence (based on nchar) is provided
    std::is_same<nchar, char16_t>::value ? invalidUTF16 :
    std::is_same<nchar, char>::value ? invalidUTF8 : outOfRange
};

/**
 * Length-prefixed string
 */
template <class C>
struct LString {
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
inline std::basic_ostream<C>& operator<<(std::basic_ostream<C>& out,
                                         LString<C> input);

template <class C>
inline bool operator==(LString<C> a, LString<C> b);

template <class C>
inline bool operator!=(LString<C> a, LString<C> b);

}

#endif // __LSTRING_DECL_H
