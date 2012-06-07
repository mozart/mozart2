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

namespace mozart {

//////////////
// Encoders //
//////////////

LString<unsigned char> encodeLatin1(VM vm, LString<nchar> input,
                                    bool isLittleEndian, bool insertBom) {
  if (input.isErrorOrEmpty())
    return input.error;

  std::vector<unsigned char> tempVector;
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

  return LString<unsigned char>(
    vm, LString<unsigned char>(tempVector.data(), tempVector.size()));
}

LString<unsigned char> encodeUTF8(VM vm, LString<nchar> input,
                                  bool isLittleEndian, bool insertBom) {
  auto utf8Result = toUTF<char>(vm, input);
  if (utf8Result.isError())
    return utf8Result.error;

  size_t encodedLength = utf8Result.bytesCount();
  if (insertBom)
    encodedLength += 3;

  unsigned char* encoded =
    static_cast<unsigned char*>(vm->malloc(encodedLength));
  unsigned char* cur = encoded;

  if (insertBom) {
    encoded[0] = 0xef;
    encoded[1] = 0xbb;
    encoded[2] = 0xbf;
    cur += 3;
  }

  memcpy(cur, utf8Result.string, utf8Result.length);

  utf8Result.free(vm);
  return LString<unsigned char>(encoded, encodedLength);
}

LString<unsigned char> encodeUTF16(VM vm, LString<nchar> input,
                                   bool isLittleEndian, bool insertBom) {
  auto utf16Result = toUTF<char16_t>(vm, input);
  if (utf16Result.isError())
    return utf16Result.error;

  size_t encodedLength = utf16Result.bytesCount();
  if (insertBom)
    encodedLength += 2;

  unsigned char* encoded =
    static_cast<unsigned char*>(vm->malloc(encodedLength));
  unsigned char* cur = encoded;

  if (insertBom) {
    encoded[0] = 0xfe + isLittleEndian;
    encoded[1] = 0xff - isLittleEndian;
    cur += 2;
  }

  for (char16_t ch : utf16Result) {
    unsigned char low = ch & 0xff;
    unsigned char high = ch >> 8;
    cur[0] = isLittleEndian ? low : high;
    cur[1] = isLittleEndian ? high : low;
    cur += 2;
  }

  utf16Result.free(vm);
  return LString<unsigned char>(encoded, encodedLength);
}

LString<unsigned char> encodeUTF32(VM vm, LString<nchar> input,
                                   bool isLittleEndian, bool insertBom) {
  auto utf32Result = toUTF<char32_t>(vm, input);
  if (utf32Result.isError())
    return utf32Result.error;

  size_t encodedLength = utf32Result.bytesCount();
  if (insertBom)
    encodedLength += 4;

  unsigned char* encoded =
    static_cast<unsigned char*>(vm->malloc(encodedLength));
  unsigned char* cur = encoded;

  if (insertBom) {
    encoded[0] = isLittleEndian ? 0xff : 0;
    encoded[1] = isLittleEndian ? 0xfe : 0;
    encoded[2] = isLittleEndian ? 0 : 0xfe;
    encoded[3] = isLittleEndian ? 0 : 0xff;
    cur += 4;
  }

  for (char32_t ch : utf32Result) {
    unsigned char a = ch & 0xff;
    unsigned char b = (ch >> 8) & 0xff;
    unsigned char c = (ch >> 16) & 0xff;
    unsigned char d = ch >> 24;
    cur[0] = isLittleEndian ? a : d;
    cur[1] = isLittleEndian ? b : c;
    cur[2] = isLittleEndian ? c : b;
    cur[3] = isLittleEndian ? d : a;
    cur += 4;
  }

  utf32Result.free(vm);
  return LString<unsigned char>(encoded, encodedLength);
}

//////////////
// Decoders //
//////////////

LString<nchar> decodeLatin1(VM vm, LString<unsigned char> input,
                            bool isLittleEndian, bool hasBom) {
  if (std::is_same<nchar, char>::value) {
    // UTF-8 needs special consideration, because 0x80~0xff maps to 2-byte
    // sequences.
    std::vector<nchar> tempVector;
    tempVector.reserve(input.length);

    for (char32_t c : input) {
      nchar encoded[4];
      nativeint length = toUTF(c, encoded);   // always valid.
      tempVector.insert(tempVector.end(), encoded, encoded + length);
    }

    return LString<nchar>(vm, LString<nchar>(tempVector.data(),
                                             tempVector.size()));
  } else {
    nchar* retval = static_cast<nchar*>(
      vm->malloc(input.length * sizeof(nchar)));
    std::copy(input.begin(), input.end(), retval);
    return LString<nchar>(retval, input.length);
  }
}

LString<nchar> decodeUTF8(VM vm, LString<unsigned char> input,
                          bool isLittleEndian, bool hasBom) {
  if (hasBom && input.length >= 3) {
    if (memcmp(input.string, "\xef\xbb\xbf", 3) == 0) {
      input.string += 3;
      input.length -= 3;
    }
  }

  std::vector<char> buffer;
  buffer.reserve(input.length);
  for (char c : input) {
    buffer.push_back(c);
  }

  return toUTF<nchar>(vm, LString<char>(buffer.data(), buffer.size()));
}

LString<nchar> decodeUTF16(VM vm, LString<unsigned char> input,
                           bool isLittleEndian, bool hasBom) {
  if (input.isError())
    return input.error;
  else if (input.length % 2 != 0)
    return UnicodeErrorReason::truncated;

  if (hasBom && input.length >= 2) {
    if (memcmp(input.string, "\xfe\xff", 2) == 0) {
      input.string += 2;
      input.length -= 2;
      isLittleEndian = false;
    } else if (memcmp(input.string, "\xff\xfe", 2) == 0) {
      input.string += 2;
      input.length -= 2;
      isLittleEndian = true;
    }
  }

  std::vector<char16_t> buffer;
  buffer.reserve(input.length / 2);
  for (nativeint i = 0; i < input.length; i += 2) {
    unsigned char low = isLittleEndian ? input.string[i] : input.string[i+1];
    unsigned char high = isLittleEndian ? input.string[i+1] : input.string[i];
    buffer.push_back(low | high << 8);
  }

  return toUTF<nchar>(vm, LString<char16_t>(buffer.data(), buffer.size()));
}

LString<nchar> decodeUTF32(VM vm, LString<unsigned char> input,
                           bool isLittleEndian, bool hasBom) {
  if (input.isError())
    return input.error;
  else if (input.length % 4 != 0)
    return UnicodeErrorReason::truncated;

  if (hasBom && input.length >= 4) {
    if (memcmp(input.string, "\x00\x00\xfe\xff", 4) == 0) {
      input.string += 4;
      input.length -= 4;
      isLittleEndian = false;
    } else if (memcmp(input.string, "\xff\xfe\x00\x00", 4) == 0) {
      input.string += 4;
      input.length -= 4;
      isLittleEndian = true;
    }
  }

  std::vector<char32_t> buffer;
  buffer.reserve(input.length / 4);
  for (nativeint i = 0; i < input.length; i += 4) {
    unsigned char a = isLittleEndian ? input.string[i] : input.string[i+3];
    unsigned char b = isLittleEndian ? input.string[i+1] : input.string[i+2];
    unsigned char c = isLittleEndian ? input.string[i+2] : input.string[i+1];
    unsigned char d = isLittleEndian ? input.string[i+3] : input.string[i];
    buffer.push_back(a | b << 8 | c << 16 | d << 24);
  }

  return toUTF<nchar>(vm, LString<char32_t>(buffer.data(), buffer.size()));
}

}
