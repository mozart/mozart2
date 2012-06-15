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

#ifndef __CODERS_H
#define __CODERS_H

#include "mozartcore.hh"

namespace mozart {

//////////////
// Encoders //
//////////////

static
LString<char> encodeLatin1(VM vm, LString<nchar> input,
                           bool isLittleEndian, bool insertBom);

static
LString<char> encodeUTF8(VM vm, LString<nchar> input,
                         bool isLittleEndian, bool insertBom);

static
LString<char> encodeUTF16(VM vm, LString<nchar> input,
                          bool isLittleEndian, bool insertBom);

static
LString<char> encodeUTF32(VM vm, LString<nchar> input,
                          bool isLittleEndian, bool insertBom);

//////////////
// Decoders //
//////////////

static
LString<nchar> decodeLatin1(VM vm, LString<char> input,
                            bool isLittleEndian, bool hasBom);
static
LString<nchar> decodeUTF8(VM vm, LString<char> input,
                          bool isLittleEndian, bool hasBom);

static
LString<nchar> decodeUTF16(VM vm, LString<char> input,
                           bool isLittleEndian, bool hasBom);

static
LString<nchar> decodeUTF32(VM vm, LString<char> input,
                           bool isLittleEndian, bool hasBom);

//////////////////////////////
// Encoders Implementations //
//////////////////////////////

static
LString<char> encodeLatin1(VM vm, LString<nchar> input,
                           bool isLittleEndian, bool insertBom) {
  return toLatin1(vm, input);
}

static
LString<char> encodeUTF8(VM vm, LString<nchar> input,
                         bool isLittleEndian, bool insertBom) {

  auto utf8Result = toUTF<char>(vm, input);
  if (!insertBom || utf8Result.isError()) {
    return utf8Result;
  } else {
    size_t length = utf8Result.length + 3;
    char* utf8WithBom = static_cast<char*>(vm->malloc(length));
    utf8WithBom[0] = 0xef;
    utf8WithBom[1] = 0xbb;
    utf8WithBom[2] = 0xbf;
    memcpy(utf8WithBom + 3, utf8Result.string, utf8Result.length);
    utf8Result.free(vm);
    return LString<char>(utf8WithBom, length);
  }
}

static
LString<char> encodeUTF16(VM vm, LString<nchar> input,
                          bool isLittleEndian, bool insertBom) {
  auto utf16Result = toUTF<char16_t>(vm, input);
  if (utf16Result.isError())
    return utf16Result.error;

  size_t encodedLength = utf16Result.bytesCount();
  if (insertBom)
    encodedLength += 2;
  char* encoded = static_cast<char*>(vm->malloc(encodedLength));
  char* cur = encoded;
  if (insertBom) {
    encoded[0] = 0xfe + isLittleEndian;
    encoded[1] = 0xff - isLittleEndian;
    cur += 2;
  }

  for (char16_t ch : utf16Result) {
    char low = (char) (ch & 0xff);
    char high = (char) (ch >> 8);
    cur[0] = isLittleEndian ? low : high;
    cur[1] = isLittleEndian ? high : low;
    cur += 2;
  }

  utf16Result.free(vm);
  return LString<char>(encoded, encodedLength);
}

static
LString<char> encodeUTF32(VM vm, LString<nchar> input,
                          bool isLittleEndian, bool insertBom) {
  auto utf32Result = toUTF<char32_t>(vm, input);
  if (utf32Result.isError())
    return utf32Result.error;

  size_t encodedLength = utf32Result.bytesCount();
  if (insertBom)
    encodedLength += 4;
  char* encoded = static_cast<char*>(vm->malloc(encodedLength));
  char* cur = encoded;
  if (insertBom) {
    encoded[0] = isLittleEndian ? 0xff : 0;
    encoded[1] = isLittleEndian ? 0xfe : 0;
    encoded[2] = isLittleEndian ? 0 : 0xfe;
    encoded[3] = isLittleEndian ? 0 : 0xff;
    cur += 4;
  }

  for (char32_t ch : utf32Result) {
    char a = (char) (ch & 0xff);
    char b = (char) ((ch >> 8) & 0xff);
    char c = (char) ((ch >> 16) & 0xff);
    char d = (char) (ch >> 24);
    cur[0] = isLittleEndian ? a : d;
    cur[1] = isLittleEndian ? b : c;
    cur[2] = isLittleEndian ? c : b;
    cur[3] = isLittleEndian ? d : a;
    cur += 4;
  }

  utf32Result.free(vm);
  return LString<char>(encoded, encodedLength);
}

//////////////////////////////
// Decoders Implementations //
//////////////////////////////

static
LString<nchar> decodeLatin1(VM vm, LString<char> input,
                            bool isLittleEndian, bool hasBom) {
  return fromLatin1(vm, input);
}

static
LString<nchar> decodeUTF8(VM vm, LString<char> input,
                          bool isLittleEndian, bool hasBom) {
  if (hasBom && input.length >= 3) {
    if (memcmp(input.string, "\xef\xbb\xbf", 3) == 0) {
      input.string += 3;
      input.length -= 3;
    }
  }
  return toUTF<nchar>(vm, input);
}

static
LString<nchar> decodeUTF16(VM vm, LString<char> input,
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

static
LString<nchar> decodeUTF32(VM vm, LString<char> input,
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

#endif
