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

#ifndef __STRING_H
#define __STRING_H

#include <string>
#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

////////////
// String //
////////////

#include "String-implem.hh"

// Core methods ----------------------------------------------------------------

Implementation<String>::Implementation(VM vm, GR gr, Self from)
  : _string(vm, from->_string) {}

bool Implementation<String>::equals(VM vm, Self right) {
  return _string == right->_string;
}

int Implementation<String>::compareFeatures(VM vm, Self right) {
  return compareByCodePoint(_string, right->_string);
}

void Implementation<String>::printReprToStream(Self self, VM vm,
                                               std::ostream& out, int depth) {
  out << '"' << toUTF<char>(_string) << '"'; // TODO: Escape characters.
}

// Comparable ------------------------------------------------------------------

OpResult Implementation<String>::compare(Self self, VM vm,
                                         RichNode right, int& result) {
  LString<nchar>* rightString = nullptr;
  MOZART_CHECK_OPRESULT(StringLike(right).stringGet(vm, rightString));
  result = compareByCodePoint(_string, *rightString);
  return OpResult::proceed();
}

// StringLike ------------------------------------------------------------------

OpResult Implementation<String>::stringGet(Self self, VM vm,
                                           LString<nchar>*& result) {
  result = &_string;
  return OpResult::proceed();
}

OpResult Implementation<String>::stringGet(Self self, VM vm,
                                           LString<unsigned char>*& result) {
  return raiseTypeError(vm, MOZART_STR("ByteString"), self);
}

OpResult Implementation<String>::stringCharAt(Self self, VM vm,
                                              RichNode offsetNode,
                                              nativeint& character) {
  nativeint offset;
  MOZART_CHECK_OPRESULT(StringOffsetLike(offsetNode).toStringOffset(vm, self, offset));
  if (offset >= _string.length)
    return raiseIndexOutOfBounds(vm, offsetNode, self);

  LString<nchar> slice = _string.slice(offset);

  char32_t codePoint;
  nativeint length;
  std::tie(codePoint, length) = fromUTF(slice.string, slice.length);
  if (length <= 0)
    return raiseUnicodeError(vm, (UnicodeErrorReason) length, self, offsetNode);

  character = codePoint;
  return OpResult::proceed();
}

OpResult Implementation<String>::stringAppend(Self self, VM vm,
                                              RichNode right,
                                              UnstableNode& result) {
  LString<nchar>* rightString = nullptr;
  MOZART_CHECK_OPRESULT(StringLike(right).stringGet(vm, rightString));
  LString<nchar> resultString = concatLString(vm, _string, *rightString);
  if (resultString.isError())
    return raiseUnicodeError(vm, resultString.error, self, right);
  result.make<String>(vm, resultString);
  return OpResult::proceed();
}

OpResult Implementation<String>::stringSlice(Self self, VM vm,
                                             RichNode from, RichNode to,
                                             UnstableNode& result) {
  nativeint fromOffset, toOffset;
  MOZART_CHECK_OPRESULT(StringOffsetLike(from).toStringOffset(vm, self, fromOffset));
  MOZART_CHECK_OPRESULT(StringOffsetLike(to).toStringOffset(vm, self, toOffset));
  if (fromOffset > toOffset)
    return raiseIndexOutOfBounds(vm, fromOffset, toOffset);
  result.make<String>(vm, _string.slice(fromOffset, toOffset));
  return OpResult::proceed();
}

OpResult Implementation<String>::stringSearch(Self self, VM vm,
                                              RichNode from, RichNode needleNode,
                                              UnstableNode& begin,
                                              UnstableNode& end) {
  nativeint fromOffset;
  MOZART_CHECK_OPRESULT(StringOffsetLike(from).toStringOffset(vm, self, fromOffset));

  nchar utf[4];
  mut::BaseLString<nchar> needleStorage;
  BaseLString<nchar>* needle;

  // Extract the needle. Could be a code point, or a string.
  {
    using namespace patternmatching;
    OpResult matchRes = OpResult::proceed();
    nativeint codePointInteger;
    if (matches(vm, matchRes, needleNode, capture(codePointInteger))) {

      char32_t codePoint = (char32_t) codePointInteger;
      nativeint length = toUTF(codePoint, utf);
      if (length <= 0)
        return raiseUnicodeError(vm, (UnicodeErrorReason) length, needleNode);
      needle = new (&needleStorage) BaseLString<nchar> (utf, length);

#ifdef _LIBCPP_TYPE_TRAITS
      static_assert(std::is_trivially_destructible<BaseLString<nchar>>::value,
                    "BaseLString<nchar> has been modified to have non-trivial "
                    "destructor! Please rewrite this piece of code to avoid "
                    "resource leak.");
      // ^ BaseLString<nchar> has trivial destructor, so we shouldn't need to
      //   explicitly destroy it.
      //   Note: libstdc++ before 4.8 still calls it 'std::has_trivial_destructor'.
#endif

    } else if (matchRes.isProceed()) {

      LString<nchar>* stringNeedle;
      MOZART_CHECK_OPRESULT(StringLike(needleNode).stringGet(vm, stringNeedle));
      needle = stringNeedle;

    } else {

      return matchRes;

    }
  }

  // Do the actual searching.
  LString<nchar> haystack = _string.slice(fromOffset);
  const nchar* foundIter = std::search(haystack.begin(), haystack.end(),
                                       needle->begin(), needle->end());
  if (foundIter == haystack.end()) {
    begin.make<Boolean>(vm, false);
    end.make<Boolean>(vm, false);
  } else {
    nativeint beginOffset = foundIter - _string.string;
    begin.make<StringOffset>(vm, beginOffset, self);
    end.make<StringOffset>(vm, beginOffset + needle->length, self);
  }
  return OpResult::proceed();
}

OpResult Implementation<String>::stringEnd(Self self, VM vm,
                                           UnstableNode& result) {
  result.make<StringOffset>(vm, _string.length, self);
  return OpResult::proceed();
}

OpResult Implementation<String>::stringHasPrefix(Self self, VM vm,
                                                 RichNode prefixNode,
                                                 bool& result) {
  LString<nchar>* prefix;
  MOZART_CHECK_OPRESULT(StringLike(prefixNode).stringGet(vm, prefix));
  if (_string.length < prefix->length)
    result = false;
  else
    result = (memcmp(_string.string, prefix->string, prefix->bytesCount()) == 0);
  return OpResult::proceed();
}

OpResult Implementation<String>::stringHasSuffix(Self self, VM vm,
                                                 RichNode suffixNode,
                                                 bool& result) {
  LString<nchar>* suffix;
  MOZART_CHECK_OPRESULT(StringLike(suffixNode).stringGet(vm, suffix));
  if (_string.length < suffix->length)
    result = false;
  else
    result = (memcmp(_string.end() - suffix->length, suffix->string, suffix->bytesCount()) == 0);
  return OpResult::proceed();
}

// Dottable --------------------------------------------------------------------

OpResult Implementation<String>::dot(Self self, VM vm, RichNode feature,
                                     UnstableNode& result) {
  nativeint character;
  MOZART_CHECK_OPRESULT(stringCharAt(self, vm, feature, character));
  result.make<SmallInt>(vm, character);
  return OpResult::proceed();
}

OpResult Implementation<String>::hasFeature(RichNode self, VM vm,
                                            RichNode feature, bool& result) {
  MOZART_REQUIRE_FEATURE(feature);

  nativeint offset;
  OpResult opRes = StringOffsetLike(feature).toStringOffset(vm, self, offset);
  if (!opRes.isProceed()) {
    result = false;
    return OpResult::proceed();
  }

  result = offset < _string.length && isLeadingCodeUnit(_string[offset]);
  return OpResult::proceed();
}

// VirtualString ---------------------------------------------------------------

OpResult Implementation<String>::toString(Self self, VM vm,
                                          std::basic_ostream<nchar>& sink) {
  sink << _string;
  return OpResult::proceed();
}

OpResult Implementation<String>::vsLength(Self self, VM vm, nativeint& result) {
  result = codePointCount(_string);
  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __STRING_H


