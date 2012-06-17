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

//////////////////////////////
// Encoders Implementations //
//////////////////////////////

FreeableLString<char> encodeLatin1(VM vm, const LString<nchar>& input,
                                   bool isLittleEndian, bool insertBom) {
  return toLatin1(vm, input);
}

FreeableLString<char> encodeUTF8(VM vm, const LString<nchar>& input,
                                 bool isLittleEndian, bool insertBom) {

  auto utf8Result = toUTF<char>(vm, input);
  if (!insertBom || utf8Result.isError()) {
    return utf8Result;
  } else {
    size_t length = utf8Result.length() + 3;
    FreeableLString<char> retval (vm, length, [=, &utf8Result](char* utf8WithBom) {
      utf8WithBom[0] = 0xef;
      utf8WithBom[1] = 0xbb;
      utf8WithBom[2] = 0xbf;
      memcpy(utf8WithBom + 3, utf8Result.string(), utf8Result.bytesCount());
    });
    free(std::move(utf8Result));
    return retval;
  }
}

FreeableLString<char> encodeUTF16(VM vm, const LString<nchar>& input,
                                  bool isLittleEndian, bool insertBom) {
  auto utf16Result = toUTF<char16_t>(vm, input);
  if (utf16Result.isError())
    return utf16Result.error();

  size_t encodedLength = utf16Result.bytesCount();
  if (insertBom)
    encodedLength += 2;

  FreeableLString<char> retval (vm, encodedLength, [=, &utf16Result](char* encoded) {
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
  });

  free(std::move(utf16Result));
  return retval;
}

FreeableLString<char> encodeUTF32(VM vm, const LString<nchar>& input,
                                  bool isLittleEndian, bool insertBom) {
  auto utf32Result = toUTF<char32_t>(vm, input);
  if (utf32Result.isError())
    return utf32Result.error();

  nativeint encodedLength = utf32Result.bytesCount();
  if (insertBom)
    encodedLength += 4;

  FreeableLString<char> retval (vm, encodedLength, [=, &utf32Result](char* encoded) {
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
  });

  free(std::move(utf32Result));
  return retval;
}

//////////////////////////////
// Decoders Implementations //
//////////////////////////////

FreeableLString<nchar> decodeLatin1(VM vm, const LString<char>& input,
                                    bool isLittleEndian, bool hasBom) {
  return fromLatin1(vm, input);
}

FreeableLString<nchar> decodeUTF8(VM vm, const LString<char>& input,
                                  bool isLittleEndian, bool hasBom) {
  nativeint startIndex = 0;
  if (hasBom && input.length() >= 3)
    if (memcmp(input.string(), "\xef\xbb\xbf", 3) == 0)
      startIndex = 3;

  return input.withSubstring(startIndex, [&](const LString<char>& ref) {
    return toUTF<nchar>(vm, ref);
  });
}

FreeableLString<nchar> decodeUTF16(VM vm, const LString<char>& input,
                                   bool isLittleEndian, bool hasBom) {
  if (input.isError())
    return input.error();
  else if (input.length() % 2 != 0)
    return UnicodeErrorReason::truncated;

  nativeint i = 0;
  if (hasBom && input.length() >= 2) {
    if (memcmp(input.string(), "\xfe\xff", 2) == 0) {
      i = 2;
      isLittleEndian = false;
    } else if (memcmp(input.string(), "\xff\xfe", 2) == 0) {
      i = 2;
      isLittleEndian = true;
    }
  }

  std::vector<char16_t> buffer;
  buffer.reserve(input.length() / 2);
  for (; i < input.length(); i += 2) {
    unsigned char low = isLittleEndian ? input[i] : input[i+1];
    unsigned char high = isLittleEndian ? input[i+1] : input[i];
    buffer.push_back(low | high << 8);
  }

  return toUTF<nchar>(vm, makeLString(buffer.data(), buffer.size()));
}

FreeableLString<nchar> decodeUTF32(VM vm, const LString<char>& input,
                                   bool isLittleEndian, bool hasBom) {
  if (input.isError())
    return input.error();
  else if (input.length() % 4 != 0)
    return UnicodeErrorReason::truncated;

  nativeint i = 0;
  if (hasBom && input.length() >= 4) {
    if (memcmp(input.string(), "\x00\x00\xfe\xff", 4) == 0) {
      i = 4;
      isLittleEndian = false;
    } else if (memcmp(input.string(), "\xff\xfe\x00\x00", 4) == 0) {
      i = 4;
      isLittleEndian = true;
    }
  }

  std::vector<char32_t> buffer;
  buffer.reserve(input.length() / 4);
  for (; i < input.length(); i += 4) {
    unsigned char a = isLittleEndian ? input[i] : input[i+3];
    unsigned char b = isLittleEndian ? input[i+1] : input[i+2];
    unsigned char c = isLittleEndian ? input[i+2] : input[i+1];
    unsigned char d = isLittleEndian ? input[i+3] : input[i];
    buffer.push_back(a | b << 8 | c << 16 | d << 24);
  }

  return toUTF<nchar>(vm, makeLString(buffer.data(), buffer.size()));
}

}

