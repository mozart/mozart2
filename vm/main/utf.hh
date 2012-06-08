// Copyright © 2012, Université catholique de Louvain
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// *  Redistributions of source code must retain the above copyright notice,
//  this list of conditions and the following disclaimer.
// *  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
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

#ifndef __UTF_H
#define __UTF_H

#include <vector>
#include <algorithm>
#include "mozartcore-decl.hh"

// Note: Perhaps we should switch to <codecvt> when libstdc++ supports it.
//       or use icu's conversion function.

namespace mozart {

/////////////////////////////////
// Unicode encoding conversion //
/////////////////////////////////

__attribute__((unused))
static nativeint toUTF(char32_t character, char utf[4]) {
  if (character < 0x80) {
    utf[0] = (char) character;
    return 1;
  } else if (character < 0x800) {
    utf[0] = (char) (0xc0 | (character >> 6));
    utf[1] = (char) (0x80 | (character & 0x3f));
    return 2;
  } else if (character < 0x10000) {
    if (0xd800 <= character && character < 0xe000)
      return UnicodeErrorReason::surrogate;
    utf[0] = (char) (0xe0 | (character >> 12));
    utf[1] = (char) (0x80 | ((character >> 6) & 0x3f));
    utf[2] = (char) (0x80 | (character & 0x3f));
    return 3;
  } else if (character < 0x110000) {
    utf[0] = (char) (0xf0 | (character >> 18));
    utf[1] = (char) (0x80 | ((character >> 12) & 0x3f));
    utf[2] = (char) (0x80 | ((character >> 6) & 0x3f));
    utf[3] = (char) (0x80 | (character & 0x3f));
    return 4;
  } else {
    return UnicodeErrorReason::outOfRange;
  }
}

static nativeint toUTF(char32_t character, char16_t utf[2]) {
  if (character < 0x10000) {
    if (0xd800 <= character && character < 0xe000)
      return UnicodeErrorReason::surrogate;
    utf[0] = (char16_t) character;
    return 1;
  } else if (character < 0x110000) {
    character -= 0x10000;
    utf[0] = (char16_t) (0xd800 | (character >> 10));
    utf[1] = (char16_t) (0xdc00 | (character & 0x3ff));
    return 2;
  } else {
    return UnicodeErrorReason::outOfRange;
  }
}

__attribute__((unused))
static nativeint toUTF(char32_t character, char32_t utf[1]) {
  utf[0] = character;
  return 1;
}

static std::pair<char32_t, nativeint> fromUTF8ContSeq(const char* utf,
                                                      char32_t val,
                                                      nativeint length,
                                                      char32_t lowerLimit) {
  for (nativeint i = 1; i < length; ++ i) {
    if ((utf[i] & 0xc0) != 0x80)
      return std::make_pair(0xfffd, UnicodeErrorReason::invalidUTF8);
    val = val << 6 | (0x3f & (unsigned char) utf[i]);
  }
  if (val < lowerLimit)
    length = UnicodeErrorReason::invalidUTF8;
  return std::make_pair(val, length);
}

__attribute__((unused))
static std::pair<char32_t, nativeint> fromUTF(const char* utf, nativeint length) {
  unsigned char leadingByte = *utf;

  // 1-byte code.
  if (leadingByte < 0x80) {
    return std::make_pair(leadingByte, 1);
  }

  // invalid leading byte.
  else if (leadingByte < 0xc2) {
    return std::make_pair(0xfffd, UnicodeErrorReason::invalidUTF8);
  }

  else if (leadingByte > 0xf4) {
    return std::make_pair(0xfffd, UnicodeErrorReason::outOfRange);
  }

  // 2-byte code.
  else if (leadingByte < 0xe0) {
    if (length >= 2)
      return fromUTF8ContSeq(utf, leadingByte & 0x1f, 2, 0x80);
    else
      return std::make_pair(0xfffd, UnicodeErrorReason::truncated);
  }

  // 3-byte code.
  else if (leadingByte < 0xf0) {
    if (length < 3)
      return std::make_pair(0xfffd, UnicodeErrorReason::truncated);
    auto retval = fromUTF8ContSeq(utf, leadingByte & 0xf, 3, 0x800);
    if (0xd800 <= retval.first && retval.first < 0xe000)
      retval.second = UnicodeErrorReason::surrogate;
    return retval;
  }

  // 4-byte code.
  else {
    if (length < 4)
      return std::make_pair(0xfffd, UnicodeErrorReason::truncated);
    auto retval = fromUTF8ContSeq(utf, leadingByte & 7, 4, 0x10000);
    if (retval.first >= 0x110000)
      retval.second = UnicodeErrorReason::outOfRange;
    return retval;
  }
}

static std::pair<char32_t, nativeint> fromUTF(const char16_t* utf, nativeint length) {
  char16_t lead = *utf;
  if (lead < 0xd800 || lead >= 0xe000) {
    return std::make_pair(lead, 1);
  } else if (lead < 0xdc00) {
    if (length < 2)
      return std::make_pair(0xfffd, UnicodeErrorReason::truncated);
    char16_t trail = utf[1];
    if (0xdc00 <= trail && trail < 0xe000) {
      char32_t codePoint = 0x10000 + ((lead & 0x3ff) << 10 | (trail & 0x3ff));
      return std::make_pair(codePoint, 2);
    }
  }
  return std::make_pair(0xfffd, UnicodeErrorReason::invalidUTF16);
}

__attribute__((unused))
static std::pair<char32_t, nativeint> fromUTF(const char32_t* utf, nativeint) {
  char32_t c = *utf;
  nativeint length = 1;
  if (0xd800 <= c && c < 0xe000)
    length = UnicodeErrorReason::surrogate;
  else if (c >= 0x110000)
    length = UnicodeErrorReason::outOfRange;
  return std::make_pair(c, length);
}

template <class To, class From>
struct UTFConvertor {
  static LString<To> call(VM vm, LString<From> input) {
    // propagate error if needed.
    if (input.isErrorOrEmpty())
      return input.error;

    // The slow branch for required conversion.
    std::vector<To> tempVector;
    tempVector.reserve(input.length);

    const From* end = input.end();
    while (input.string < end) {
      auto codePointSizePair = fromUTF(input.string, end - input.string);
      if (codePointSizePair.second < 0)
        return (UnicodeErrorReason) codePointSizePair.second;
      input.string += codePointSizePair.second;

      To encoded[4];
      nativeint encodedLength = toUTF(codePointSizePair.first, encoded);
      if (encodedLength < 0)
        return (UnicodeErrorReason) encodedLength;
      tempVector.insert(tempVector.end(), encoded, encoded + encodedLength);
    }

    return LString<To>(vm, LString<To>(tempVector.data(), tempVector.size()));
  }
};

template <class To>
struct UTFConvertor<To, To> {
  static LString<To> call(VM vm, LString<To> input) {
    // propagate error if needed.
    if (input.isErrorOrEmpty())
      return input.error;

    // Just validate if the whole string is correct.
    LString<To> validator = input;
    const To* end = validator.end();
    while (validator.string < end) {
      nativeint length = fromUTF(validator.string, end - validator.string).second;
      if (length < 0)
        return (UnicodeErrorReason) length;
      validator.string += length;
    }

    // No conversion needed.
    return LString<To>(vm, input);
  }
};

template <class To, class From>
static LString<To> toUTF(VM vm, LString<From> input) {
  return UTFConvertor<To, From>::call(vm, input);
}

static LString<char> toLatin1(VM vm, LString<nchar> input) {
  if (input.isErrorOrEmpty())
    return input.error;

  std::vector<char> tempVector;
  tempVector.reserve(input.length);

  const nchar* end = input.end();
  while (input.string < end) {
    auto codePointSizePair = fromUTF(input.string, end - input.string);
    if (codePointSizePair.second < 0)
      return (UnicodeErrorReason) codePointSizePair.second;
    input.string += codePointSizePair.second;

    if (codePointSizePair.first > 0xff)
      tempVector.push_back('?');
    else
      tempVector.push_back(codePointSizePair.first);
  }

  return LString<char>(vm, LString<char>(tempVector.data(), tempVector.size()));
}

static LString<nchar> fromLatin1(VM vm, LString<char> input) {
  if (std::is_same<nchar, char>::value) {

    // UTF-8 needs special consideration, because 0x80~0xff maps to 2-byte
    // sequences.
    std::vector<nchar> tempVector;
    tempVector.reserve(input.length);

    for (nativeint i = 0; i < input.length; ++ i) {
      char32_t c = (unsigned char) input.string[i];
      nchar encoded[4];
      nativeint length = toUTF(c, encoded);   // always valid.
      tempVector.insert(tempVector.end(), encoded, encoded + length);
    }

    return LString<nchar>(vm, LString<nchar>(tempVector.data(), tempVector.size()));

  } else {

    nchar* retval = static_cast<nchar*>(vm->malloc(input.length * sizeof(nchar)));
    std::copy(reinterpret_cast<const unsigned char*>(input.begin()),
          reinterpret_cast<const unsigned char*>(input.end()),
          retval);
    return LString<nchar>(retval, input.length);

  }
}

template <class C>
static int compareByCodePoint(LString<C> a, LString<C> b) {
  if (a.string == b.string) {
    return a.length < b.length ? -1 : a.length > b.length ? 1 : 0;
  }

  size_t minLength = std::min(a.length, b.length);

  // UTF-8 and UTF-32 can be sorted directly.
  if (!std::is_same<C, char16_t>::value) {
    int compareRes = std::char_traits<C>::compare(a.string, b.string, minLength);
    if (compareRes != 0)
      return compareRes;
  }

  // UTF-16 need be compared manually, because a surrogate pair rank higher
  // than 0xe000, but the value in a string is lower.
  else {
    for (; minLength; -- minLength, ++ a.string, ++ b.string) {
      nchar aa = *a.string, bb = *b.string;
      if (aa == bb)
        continue;

      bool aIsSurrogate = 0xd800 <= aa && aa < 0xe000;
      bool bIsSurrogate = 0xd800 <= bb && bb < 0xe000;

      if (aIsSurrogate == bIsSurrogate) {
        return aa < bb ? -1 : 1;
      } else {
        return aIsSurrogate ? 1 : -1;
      }
    }
  }

  return a.length < b.length ? -1 : a.length > b.length ? 1 : 0;
}

__attribute__((unused))
static nativeint getUTFStride(const char* utf) {
  unsigned char leadingByte = *utf;
  if (leadingByte < 0x80)
    return 1;
  else if (leadingByte < 0xc2)
    return UnicodeErrorReason::invalidUTF8;
  else if (leadingByte > 0xf4)
    return UnicodeErrorReason::outOfRange;
  else if (leadingByte < 0xe0)
    return 2;
  else if (leadingByte < 0xf0)
    return 3;
  else
    return 4;
}

static nativeint getUTFStride(const char16_t* utf) {
  char16_t lead = *utf;
  if (lead < 0xd800 || lead >= 0xe000)
    return 1;
  else if (lead < 0xdc00)
    return 2;
  else
    return UnicodeErrorReason::invalidUTF16;
}

__attribute__((unused))
static nativeint getUTFStride(const char32_t* utf) {
  return 1;
}

__attribute__((unused))
static nativeint codePointCount(LString<char> input) {
  if (input.isErrorOrEmpty())
  return input.length;
  return std::count_if(input.begin(), input.end(), [](char c) {
    return !('\x80' <= c && c < '\xc0');
  });
}

static nativeint codePointCount(LString<char16_t> input) {
  if (input.isErrorOrEmpty())
  return input.length;
  return std::count_if(input.begin(), input.end(), [](char16_t c) {
    return !(0xdc00 <= c && c < 0xe000);
  });
}

__attribute__((unused))
static nativeint codePointCount(LString<char32_t> input) {
  return input.length;
}

/////////////
// LString //
/////////////

template <class C>
void LString<C>::free(VM vm) {
  if (length >= 0)
    vm->free(const_cast<C*>(string), length * sizeof(C));
  string = nullptr;
  length = 0;
}

template <class C>
LString<C>::LString(VM vm, LString<C> other) : length(other.length) {
  if (other.isErrorOrEmpty()) {
    string = nullptr;
  } else {
    void* memory = vm->malloc(other.bytesCount());
    memcpy(memory, other.string, other.bytesCount());
    string = static_cast<const C*>(memory);
  }
}

template <class C>
static std::basic_ostream<C>& operator<<(std::basic_ostream<C>& out, LString<C> input) {
  return out.write(input.string, input.length);
}

template <class C>
static bool operator==(LString<C> a, LString<C> b) {
  if (a.length != b.length)
    return false;
  if (a.string == b.string)
    return true;
  return memcmp(a.string, b.string, a.length*sizeof(C)) == 0;
}

template <class C>
static bool operator!=(LString<C> a, LString<C> b) {
  return !(a == b);
}

}

#endif

