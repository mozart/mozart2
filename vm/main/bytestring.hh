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

#ifndef __BYTESTRING_H
#define __BYTESTRING_H

#include <string>
#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

////////////////
// ByteString //
////////////////

#include "ByteString-implem.hh"

Implementation<ByteString>::Implementation(VM vm, GR gr, Self from)
  : _bytes(vm, from->_bytes) {}

bool Implementation<ByteString>::equals(VM vm, Self right) {
  return _bytes == right->_bytes;
}

namespace internal {
  inline
  int compareByteStrings(LString<unsigned char> left,
                         LString<unsigned char> right) {
    int cmpRes = left.string != right.string;
    if (cmpRes) {
      size_t minLength = std::min(left.bytesCount(), right.bytesCount());
      cmpRes = memcmp(left.string, right.string, minLength);
    }
    if (!cmpRes) {
      return left.length < right.length ? -1 :
             left.length > right.length ? 1 : 0;
    } else {
      return cmpRes;
    }
  }
}

OpResult Implementation<ByteString>::compare(Self self, VM vm,
                                             RichNode right, int& result) {
  LString<unsigned char>* rightBytes = nullptr;
  MOZART_CHECK_OPRESULT(ByteStringLike(right).stringGet(vm, rightBytes));
  result = internal::compareByteStrings(_bytes, *rightBytes);
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::stringGet(
  Self self, VM vm, LString<unsigned char>*& result) {

  result = &_bytes;
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::bsGet(Self self, VM vm, nativeint index,
                                           unsigned char& result) {
  if (index < 0 || index >= _bytes.length)
    return raise(vm, MOZART_STR("indexOutOfBound"), self, index);
  result = _bytes.string[index];
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::bsAppend(Self self, VM vm,
                                              RichNode right,
                                              UnstableNode& result) {
  if (!right.is<ByteString>())
    return raiseTypeError(vm, MOZART_STR("ByteString"), right);

  if (_bytes.length <= 0) {
    result.copy(vm, right);
    return OpResult::proceed();
  }

  auto rightBytes = right.as<ByteString>().value();
  if (rightBytes.length <= 0) {
    result.copy(vm, self);
    return OpResult::proceed();
  }

  nativeint totalLength = _bytes.length + rightBytes.length;

  if (_bytes.end() == rightBytes.begin()) {
    result.make<ByteString>(vm, LString<unsigned char>(_bytes.string,
                                                       totalLength));
    return OpResult::proceed();
  }

  unsigned char* newMem = new (vm) unsigned char[totalLength];
  memcpy(newMem, _bytes.string, _bytes.length);
  memcpy(newMem+_bytes.length, rightBytes.string, rightBytes.length);
  result.make<ByteString>(vm, LString<unsigned char>(newMem, totalLength));
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::bsDecode(Self self, VM vm,
                                              ByteStringEncoding encoding,
                                              bool isLittleEndian, bool hasBOM,
                                              UnstableNode& result) {
  LString<nchar> str;
  switch (encoding) {
    case ByteStringEncoding::latin1:
      str = decodeLatin1(vm, _bytes, isLittleEndian, hasBOM);
      break;
    case ByteStringEncoding::utf8:
      str = decodeUTF8(vm, _bytes, isLittleEndian, hasBOM);
      break;
    case ByteStringEncoding::utf16:
      str = decodeUTF16(vm, _bytes, isLittleEndian, hasBOM);
      break;
    case ByteStringEncoding::utf32:
      str = decodeUTF32(vm, _bytes, isLittleEndian, hasBOM);
      break;
    default:
      return OpResult::fail();
  }

  if (str.isError())
    return raiseUnicodeError(vm, str.error, self);

  result.make<String>(vm, str);
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::bsSlice(Self self, VM vm,
                                             nativeint from, nativeint to,
                                             UnstableNode& result) {
  if (from > to || from < 0 || to >= _bytes.length)
    return raise(vm, MOZART_STR("indexOutOfBound"), self, from, to);

  LString<unsigned char> newBytes (_bytes.string + from, to - from);
  result.make<ByteString>(vm, newBytes);
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::bsStrChr(Self self, VM vm, nativeint from,
                                              unsigned char character,
                                              UnstableNode& res) {
  if (from < 0 || from >= _bytes.length)
    return raise(vm, MOZART_STR("indexOutOfBound"), self, from);

  const unsigned char* start = _bytes.string + from;
  const void* result = memchr(static_cast<const void*>(start), character,
                              _bytes.length - from);
  if (result == nullptr)
    res.make<Boolean>(vm, false);
  else
    res.make<SmallInt>(
      vm, static_cast<const unsigned char*>(result) - _bytes.string);
  return OpResult::proceed();
}

OpResult encodeToBytestring(VM vm, LString<nchar> input,
                            ByteStringEncoding encoding,
                            bool isLittleEndian, bool hasBOM,
                            UnstableNode& result) {
  LString<unsigned char> bytes;
  switch (encoding) {
    case ByteStringEncoding::latin1:
      bytes = encodeLatin1(vm, input, isLittleEndian, hasBOM);
      break;
    case ByteStringEncoding::utf8:
      bytes = encodeUTF8(vm, input, isLittleEndian, hasBOM);
      break;
    case ByteStringEncoding::utf16:
      bytes = encodeUTF16(vm, input, isLittleEndian, hasBOM);
      break;
    case ByteStringEncoding::utf32:
      bytes = encodeUTF32(vm, input, isLittleEndian, hasBOM);
      break;
    default:
      return OpResult::fail();
  }

  if (bytes.isError())
    return raiseUnicodeError(vm, bytes.error, String::build(vm, input));

  result.make<ByteString>(vm, bytes);
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::toString(Self self, VM vm,
                                              std::basic_ostream<nchar>& sink) {
  // Latin1 -> UTF always succeed.
  auto latin1Result = decodeLatin1(vm, _bytes, true, false);
  sink << latin1Result;
  latin1Result.free(vm);
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::vsLength(Self self, VM vm,
                                              nativeint& result) {
  result = _bytes.length;
  return OpResult::proceed();
}

void Implementation<ByteString>::printReprToStream(Self self, VM vm,
                                                   std::ostream& out,
                                                   int depth) {
  out << "<ByteString \"";
  out.write(reinterpret_cast<const char*>(_bytes.string), _bytes.length);
  // TODO: Escape characters.
  out << "\">";
}

}

#endif // MOZART_GENERATOR

#endif // __BYTESTRING_H
