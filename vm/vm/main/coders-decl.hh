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

#ifndef __CODERS_DECL_H
#define __CODERS_DECL_H

#include "core-forward-decl.hh"
#include "lstring-decl.hh"

namespace mozart {

enum class ByteStringEncoding {
  latin1,
  utf8,
  utf16,
  utf32
};

enum EncodingVariant : uintptr_t {
  none = 0,
  littleEndian = 1,
  hasBOM = 2,
};

static inline
EncodingVariant& operator|=(EncodingVariant& a, EncodingVariant b) noexcept {
  return a = (EncodingVariant) (a | b);
}
static inline
EncodingVariant& operator&=(EncodingVariant& a, EncodingVariant b) noexcept {
  return a = (EncodingVariant) (a & b);
}
static inline
EncodingVariant operator~(EncodingVariant a) noexcept {
  return (EncodingVariant) ~((uintptr_t) a);
}

typedef ContainedLString<std::vector<unsigned char>> (*EncoderFun)
    (const BaseLString<nchar>& input, EncodingVariant variant);
typedef ContainedLString<std::vector<nchar>> (*DecoderFun)
    (const BaseLString<unsigned char>& input, EncodingVariant variant);

//////////////
// Encoders //
//////////////

auto encodeLatin1(const BaseLString<nchar>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<unsigned char>>;

auto encodeUTF8(const BaseLString<nchar>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<unsigned char>>;

auto encodeUTF16(const BaseLString<nchar>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<unsigned char>>;

auto encodeUTF32(const BaseLString<nchar>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<unsigned char>>;

auto encodeGeneric(const BaseLString<nchar>& input,
                   ByteStringEncoding encoding, EncodingVariant variant)
    -> ContainedLString<std::vector<unsigned char>>;

//////////////
// Decoders //
//////////////

auto decodeLatin1(const BaseLString<unsigned char>& input,
                  EncodingVariant variant)
    -> ContainedLString<std::vector<nchar>>;

auto decodeUTF8(const BaseLString<unsigned char>& input,
                EncodingVariant variant)
    -> ContainedLString<std::vector<nchar>>;

auto decodeUTF16(const BaseLString<unsigned char>& input,
                 EncodingVariant variant)
    -> ContainedLString<std::vector<nchar>>;

auto decodeUTF32(const BaseLString<unsigned char>& input,
                 EncodingVariant variant)
    -> ContainedLString<std::vector<nchar>>;

auto decodeGeneric(const BaseLString<unsigned char>& input,
                   ByteStringEncoding encoding, EncodingVariant variant)
    -> ContainedLString<std::vector<nchar>>;

}

#endif // __CODERS_DECL_H
