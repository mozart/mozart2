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

// Core methods ----------------------------------------------------------------

Implementation<ByteString>::Implementation(VM vm, GR gr, Self from)
  : _bytes(vm, from->_bytes) {}

bool Implementation<ByteString>::equals(VM vm, Self right) {
  return _bytes == right->_bytes;
}

void Implementation<ByteString>::getValueAt(Self self, VM vm,
                                            nativeint feature,
                                            UnstableNode& result) {
  result.make<SmallInt>(vm, _bytes[feature]);
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
  MOZART_CHECK_OPRESULT(StringLike(right).stringGet(vm, rightBytes));
  result = internal::compareByteStrings(_bytes, *rightBytes);
  return OpResult::proceed();
}

// StringLike ------------------------------------------------------------------

OpResult Implementation<ByteString>::stringGet(
  Self self, VM vm, LString<unsigned char>*& result) {

  result = &_bytes;
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::stringGet(
  Self self, VM vm, LString<nchar>*& result) {

  return raiseTypeError(vm, MOZART_STR("String"), self);
}

OpResult Implementation<ByteString>::stringCharAt(Self self, VM vm,
                                                  RichNode offsetNode,
                                                  nativeint& character) {
  nativeint offset = 0;
  MOZART_GET_ARG(offset, offsetNode, MOZART_STR("integer"));

  if (offset < 0 || offset >= _bytes.length)
    return raiseIndexOutOfBounds(vm, offsetNode, self);

  character = _bytes[offset];
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::stringAppend(Self self, VM vm,
                                                  RichNode right,
                                                  UnstableNode& result) {
  LString<unsigned char>* rightBytes = nullptr;
  MOZART_CHECK_OPRESULT(StringLike(right).stringGet(vm, rightBytes));
  LString<unsigned char> resultBytes = concatLString(vm, _bytes, *rightBytes);
  if (resultBytes.isError())
    return raiseUnicodeError(vm, resultBytes.error, self, right);
  result.make<ByteString>(vm, resultBytes);
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::stringSlice(Self self, VM vm,
                                                 RichNode from, RichNode to,
                                                 UnstableNode& result) {
  nativeint fromOffset = 0, toOffset = 0;
  MOZART_GET_ARG(fromOffset, from, MOZART_STR("integer"));
  MOZART_GET_ARG(toOffset, to, MOZART_STR("integer"));

  if (fromOffset < 0 || fromOffset > toOffset || toOffset > _bytes.length)
    return raiseIndexOutOfBounds(vm, fromOffset, toOffset);

  result.make<ByteString>(vm, _bytes.slice(fromOffset, toOffset));
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::stringSearch(
  Self self, VM vm, RichNode from, RichNode needleNode,
  UnstableNode& begin, UnstableNode& end) {

  using namespace patternmatching;

  nativeint fromOffset = 0;
  MOZART_GET_ARG(fromOffset, from, MOZART_STR("integer"));

  if (fromOffset < 0 || fromOffset > _bytes.length)
    return raiseIndexOutOfBounds(vm, fromOffset);

  LString<unsigned char> haystack = _bytes.slice(fromOffset);

  nativeint character = 0;
  OpResult matchRes = OpResult::proceed();

  if (matches(vm, matchRes, needleNode, capture(character))) {

    if (character < 0 || character >= 0x100)
      return raiseTypeError(vm, MOZART_STR("Integer between 0 and 255"),
                            needleNode);

    auto haystackUnsafe = const_cast<unsigned char*>(haystack.string);
    const void* searchRes = memchr(haystackUnsafe, character,
                                   haystack.bytesCount());
    if (searchRes == nullptr) {
      begin.make<Boolean>(vm, false);
      end.make<Boolean>(vm, false);
    } else {
      nativeint foundOffset =
        static_cast<const unsigned char*>(searchRes) - _bytes.string;
      begin.make<SmallInt>(vm, foundOffset);
      end.make<SmallInt>(vm, foundOffset + 1);
    }

  } else if (matchRes.isProceed()) {

    LString<unsigned char>* needle = nullptr;
    MOZART_CHECK_OPRESULT(StringLike(needleNode).stringGet(vm, needle));
    auto foundIter = std::search(haystack.begin(), haystack.end(),
                                 needle->begin(), needle->end());
    if (foundIter == haystack.end()) {
      begin.make<Boolean>(vm, false);
      end.make<Boolean>(vm, false);
    } else {
      nativeint foundOffset = foundIter - _bytes.string;
      begin.make<SmallInt>(vm, foundOffset);
      end.make<SmallInt>(vm, foundOffset + needle->length);
    }

  } else {
    return matchRes;
  }

  return OpResult::proceed();
}

OpResult Implementation<ByteString>::stringHasPrefix(Self self, VM vm,
                                                     RichNode prefixNode,
                                                     bool& result) {
  LString<unsigned char>* prefix = nullptr;
  MOZART_CHECK_OPRESULT(StringLike(prefixNode).stringGet(vm, prefix));
  if (_bytes.length < prefix->length)
    result = false;
  else
    result = (memcmp(_bytes.string, prefix->string, prefix->bytesCount()) == 0);
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::stringHasSuffix(Self self, VM vm,
                                                     RichNode suffixNode,
                                                     bool& result) {
  LString<unsigned char>* suffix = nullptr;
  MOZART_CHECK_OPRESULT(StringLike(suffixNode).stringGet(vm, suffix));
  if (_bytes.length < suffix->length)
    result = false;
  else
    result = (memcmp(_bytes.end() - suffix->length, suffix->string,
                     suffix->bytesCount()) == 0);
  return OpResult::proceed();
}

// VirtualString ---------------------------------------------------------------

OpResult Implementation<ByteString>::toString(Self self, VM vm,
                                              std::basic_ostream<nchar>& sink) {
  sink << decodeLatin1(_bytes, EncodingVariant::none);
  return OpResult::proceed();
}

OpResult Implementation<ByteString>::vsLength(Self self, VM vm,
                                              nativeint& result) {
  result = _bytes.length;
  return OpResult::proceed();
}

// Encode & decode -------------------------------------------------------------

OpResult Implementation<ByteString>::decode(Self self, VM vm,
                                            ByteStringEncoding encoding,
                                            EncodingVariant variant,
                                            UnstableNode& result) {
  DecoderFun decoder;
  switch (encoding) {
    case ByteStringEncoding::latin1: decoder = &decodeLatin1; break;
    case ByteStringEncoding::utf8:   decoder = &decodeUTF8;   break;
    case ByteStringEncoding::utf16:  decoder = &decodeUTF16;  break;
    case ByteStringEncoding::utf32:  decoder = &decodeUTF32;  break;
    default:
      return OpResult::fail();
  }

  auto res = newLString(vm, decoder(_bytes, variant));
  if (res.isError())
    return raiseUnicodeError(vm, res.error);
  result.make<String>(vm, res);
  return OpResult::proceed();
}

OpResult encodeToBytestring(VM vm, const BaseLString<nchar>& input,
                            ByteStringEncoding encoding,
                            EncodingVariant variant,
                            UnstableNode& result) {
  EncoderFun encoder;
  switch (encoding) {
    case ByteStringEncoding::latin1: encoder = &encodeLatin1; break;
    case ByteStringEncoding::utf8:   encoder = &encodeUTF8;   break;
    case ByteStringEncoding::utf16:  encoder = &encodeUTF16;  break;
    case ByteStringEncoding::utf32:  encoder = &encodeUTF32;  break;
    default:
      return OpResult::fail();
  }

  auto res = newLString(vm, encoder(input, variant));
  if (res.isError())
    return raiseUnicodeError(vm, res.error);
  result.make<ByteString>(vm, res);
  return OpResult::proceed();
}

// Miscellaneous ---------------------------------------------------------------

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
