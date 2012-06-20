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

#include "mozart.hh"
#include "coders.hh"

namespace mozart {

//////////////////////////////
// Encoders Implementations //
//////////////////////////////

auto encodeLatin1(const BaseLString<nchar>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<char>> {
  if (input.isErrorOrEmpty())
    return input.error;

  std::vector<char> tempVector;
  tempVector.reserve(input.length);
  UnicodeErrorReason curError = UnicodeErrorReason::empty;

  forEachCodePoint(input,
                   [&](char32_t codePoint) -> bool {
                     tempVector.push_back(codePoint > 0xff ? '?' : codePoint);
                     return true;
                   },
                   [&](nchar, UnicodeErrorReason error) -> bool {
                     curError = error;
                     return false;
                   });

  if (curError != UnicodeErrorReason::empty)
    return curError;
  else
    return std::move(tempVector);
}

auto encodeUTF8(const BaseLString<nchar>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<char>> {
  auto result = toUTF<char>(input);
  if (!result.isError() && (variant & EncodingVariant::hasBOM) != 0) {
    result.insertPrefix("\xef\xbb\xbf");
  }
  return result;
}

auto encodeUTF16(const BaseLString<nchar>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<char>> {

  auto utf16Result = toUTF<char16_t>(input);
  if (utf16Result.isError())
    return utf16Result.error;

  size_t encodedLength = utf16Result.bytesCount();
  bool hasBOM_ = (variant & EncodingVariant::hasBOM) != 0;
  bool isLittleEndian = (variant & EncodingVariant::littleEndian) != 0;
  if (hasBOM_)
    encodedLength += 2;

  std::vector<char> result;
  result.reserve(encodedLength);

  if (hasBOM_) {
    result.push_back(isLittleEndian ? 0xff : 0xfe);
    result.push_back(isLittleEndian ? 0xfe : 0xff);
  }

  for (char16_t ch : utf16Result) {
    char low = (char) (ch & 0xff);
    char high = (char) (ch >> 8);
    result.push_back(isLittleEndian ? low : high);
    result.push_back(isLittleEndian ? high : low);
  }

  return std::move(result);
}

auto encodeUTF32(const BaseLString<nchar>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<char>> {

  auto utf32Result = toUTF<char32_t>(input);
  if (utf32Result.isError())
    return utf32Result.error;

  size_t encodedLength = utf32Result.bytesCount();
  bool hasBOM_ = (variant & EncodingVariant::hasBOM) != 0;
  bool isLittleEndian = (variant & EncodingVariant::littleEndian) != 0;
  if (hasBOM_)
    encodedLength += 4;

  std::vector<char> result;
  result.reserve(encodedLength);

  if (hasBOM_) {
    result.push_back(isLittleEndian ? 0xff : 0);
    result.push_back(isLittleEndian ? 0xfe : 0);
    result.push_back(isLittleEndian ? 0 : 0xfe);
    result.push_back(isLittleEndian ? 0 : 0xff);
  }

  for (char16_t ch : utf32Result) {
    char a = (char) (ch & 0xff);
    char b = (char) ((ch >> 8) & 0xff);
    char c = (char) ((ch >> 16) & 0xff);
    char d = (char) (ch >> 24);
    result.push_back(isLittleEndian ? a : d);
    result.push_back(isLittleEndian ? b : c);
    result.push_back(isLittleEndian ? c : b);
    result.push_back(isLittleEndian ? d : a);
  }

  return std::move(result);
}

//////////////////////////////
// Decoders Implementations //
//////////////////////////////

auto decodeLatin1(const BaseLString<char>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<nchar>> {
  std::vector<nchar> tempVector;
  tempVector.reserve(input.length);

  if (std::is_same<nchar, char>::value) {

    // UTF-8 needs special consideration, because 0x80~0xff maps to 2-byte
    // sequences.
    for (nativeint i = 0; i < input.length; ++ i) {
      char32_t c = (unsigned char) input.string[i];
      nchar encoded[4];
      nativeint length = toUTF(c, encoded);   // always valid.
      tempVector.insert(tempVector.end(), encoded, encoded + length);
    }

  } else {

    std::copy(reinterpret_cast<const unsigned char*>(input.begin()),
              reinterpret_cast<const unsigned char*>(input.end()),
              std::back_inserter(tempVector));

  }

  return std::move(tempVector);
}

auto decodeUTF8(const BaseLString<char>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<nchar>> {

  nativeint start = 0;
  if ((variant & EncodingVariant::hasBOM) != 0 && input.length >= 3) {
    if (memcmp(input.string, "\xef\xbb\xbf", 3) == 0) {
      start = 3;
    }
  }

  return toUTF<nchar>(input.unsafeSlice(start));
}

auto decodeUTF16(const BaseLString<char>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<nchar>> {

  if (input.isError())
    return input.error;
  else if (input.length % 2 != 0)
    return UnicodeErrorReason::truncated;

  nativeint start = 0;
  bool isLittleEndian = (variant & EncodingVariant::littleEndian) != 0;
  if ((variant & EncodingVariant::hasBOM) != 0 && input.length >= 2) {
    if (memcmp(input.string, "\xfe\xff", 2) == 0) {
      start = 2;
      isLittleEndian = false;
    } else if (memcmp(input.string, "\xff\xfe", 2) == 0) {
      start = 2;
      isLittleEndian = true;
    }
  }

  std::vector<char16_t> buffer;
  buffer.reserve(input.length / 2);
  for (nativeint i = start; i < input.length; i += 2) {
    unsigned char low = isLittleEndian ? input.string[i] : input.string[i+1];
    unsigned char high = isLittleEndian ? input.string[i+1] : input.string[i];
    buffer.push_back(low | high << 8);
  }

  return toUTF<nchar>(makeLString(buffer.data(), buffer.size()));
}

auto decodeUTF32(const BaseLString<char>& input, EncodingVariant variant)
    -> ContainedLString<std::vector<nchar>> {

  if (input.isError())
    return input.error;
  else if (input.length % 4 != 0)
    return UnicodeErrorReason::truncated;

  nativeint start = 0;
  bool isLittleEndian = (variant & EncodingVariant::littleEndian) != 0;
  if ((variant & EncodingVariant::hasBOM) != 0 && input.length >= 4) {
    if (memcmp(input.string, "\x00\x00\xfe\xff", 4) == 0) {
      start = 4;
      isLittleEndian = false;
    } else if (memcmp(input.string, "\xff\xfe\x00\x00", 4) == 0) {
      start = 4;
      isLittleEndian = true;
    }
  }

  std::vector<char32_t> buffer;
  buffer.reserve(input.length / 4);
  for (nativeint i = start; i < input.length; i += 4) {
    unsigned char a = isLittleEndian ? input.string[i] : input.string[i+3];
    unsigned char b = isLittleEndian ? input.string[i+1] : input.string[i+2];
    unsigned char c = isLittleEndian ? input.string[i+2] : input.string[i+1];
    unsigned char d = isLittleEndian ? input.string[i+3] : input.string[i];
    buffer.push_back(a | b << 8 | c << 16 | d << 24);
  }

  return toUTF<nchar>(makeLString(buffer.data(), buffer.size()));
}

}

