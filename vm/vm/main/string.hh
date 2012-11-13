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

String::String(VM vm, GR gr, String& from)
  : _string(vm, from._string) {
}

bool String::equals(VM vm, RichNode right) {
  return value() == right.as<String>().value();
}

// Comparable ------------------------------------------------------------------

int String::compare(VM vm, RichNode right) {
  auto rightString = StringLike(right).stringGet(vm);
  return compareByCodePoint(_string, *rightString);
}

// StringLike ------------------------------------------------------------------

LString<nchar>* String::stringGet(VM vm) {
  return &_string;
}

LString<unsigned char>* String::byteStringGet(RichNode self, VM vm) {
  return Interface<StringLike>().byteStringGet(self, vm);
}

nativeint String::stringCharAt(RichNode self, VM vm, RichNode indexNode) {
  auto index = getArgument<nativeint>(vm, indexNode);

  LString<nchar> slice = sliceByCodePointsFromTo(_string, index, index+1);
  if (slice.isError()) {
    if (slice.error == UnicodeErrorReason::indexOutOfBounds)
      raiseIndexOutOfBounds(vm, indexNode, self);
    else
      raiseUnicodeError(vm, slice.error, self);
  }

  char32_t codePoint;
  nativeint length;
  std::tie(codePoint, length) = fromUTF(slice.string, slice.length);
  if (length <= 0)
    raiseUnicodeError(vm, (UnicodeErrorReason) length, self, indexNode);

  return codePoint;
}

UnstableNode String::stringAppend(RichNode self, VM vm, RichNode right) {
  auto rightString = StringLike(right).stringGet(vm);
  auto resultString = concatLString(vm, _string, *rightString);

  if (resultString.isError())
    raiseUnicodeError(vm, resultString.error, self, right);

  return String::build(vm, resultString);
}

UnstableNode String::stringSlice(RichNode self, VM vm,
                                 RichNode from, RichNode to) {
  auto fromIndex = getArgument<nativeint>(vm, from);
  auto toIndex = getArgument<nativeint>(vm, to);

  LString<nchar> resultString =
    sliceByCodePointsFromTo(_string, fromIndex, toIndex);

  if (resultString.isError()) {
    if (resultString.error == UnicodeErrorReason::indexOutOfBounds)
      raiseIndexOutOfBounds(vm, self, from, to);
    else
      raiseUnicodeError(vm, resultString.error, self);
  }

  return String::build(vm, resultString);
}

void String::stringSearch(RichNode self, VM vm, RichNode from,
                          RichNode needleNode,
                          UnstableNode& begin, UnstableNode& end) {
  auto fromIndex = getArgument<nativeint>(vm, from);

  nchar utf[4];
  mut::BaseLString<nchar> needleStorage;
  BaseLString<nchar>* needle;

  // Extract the needle. Could be a code point, or a string.
  {
    using namespace patternmatching;
    nativeint codePointInteger = 0;
    if (matches(vm, needleNode, capture(codePointInteger))) {

      char32_t codePoint = (char32_t) codePointInteger;
      nativeint length = toUTF(codePoint, utf);
      if (length <= 0)
        raiseUnicodeError(vm, (UnicodeErrorReason) length, needleNode);

      needle = new (&needleStorage) BaseLString<nchar>(utf, length);

#ifdef _LIBCPP_TYPE_TRAITS
      static_assert(std::is_trivially_destructible<BaseLString<nchar>>::value,
                    "BaseLString<nchar> has been modified to have non-trivial "
                    "destructor! Please rewrite this piece of code to avoid "
                    "resource leak.");
      // ^ BaseLString<nchar> has trivial destructor, so we shouldn't need to
      //   explicitly destroy it.
      //   Note: libstdc++ before 4.8 still calls it 'std::has_trivial_destructor'.
#endif

    } else {
      needle = StringLike(needleNode).stringGet(vm);
    }
  }

  // Do the actual searching.
  LString<nchar> haystack = sliceByCodePointsFrom(_string, fromIndex);

  if (haystack.isError()) {
    if (haystack.error == UnicodeErrorReason::indexOutOfBounds)
      raiseIndexOutOfBounds(vm, self, from);
    else
      raiseUnicodeError(vm, haystack.error, self);
  }

  const nchar* foundIter = std::search(haystack.begin(), haystack.end(),
                                       needle->begin(), needle->end());

  // Make result
  if (foundIter == haystack.end()) {
    begin = Boolean::build(vm, false);
    end = Boolean::build(vm, false);
  } else {
    LString<nchar> haystackUntilNeedle =
      haystack.slice(0, foundIter-haystack.begin());
    nativeint foundIndex = fromIndex + codePointCount(haystackUntilNeedle);

    begin = SmallInt::build(vm, foundIndex);
    end = SmallInt::build(vm, foundIndex + codePointCount(*needle));
  }
}

bool String::stringHasPrefix(VM vm, RichNode prefixNode) {
  auto prefix = StringLike(prefixNode).stringGet(vm);
  if (_string.length < prefix->length)
    return false;
  else
    return memcmp(_string.string, prefix->string, prefix->bytesCount()) == 0;
}

bool String::stringHasSuffix(VM vm, RichNode suffixNode) {
  auto suffix = StringLike(suffixNode).stringGet(vm);
  if (_string.length < suffix->length)
    return false;
  else
    return memcmp(_string.end() - suffix->length, suffix->string,
                  suffix->bytesCount()) == 0;
}

// Dottable --------------------------------------------------------------------

bool String::lookupFeature(RichNode self, VM vm, RichNode feature,
                           nullable<UnstableNode&> value) {
  using namespace patternmatching;

  nativeint featureIntValue = 0;

  // Fast-path for the integer case
  if (matches(vm, feature, capture(featureIntValue))) {
    return lookupFeature(self, vm, featureIntValue, value);
  } else {
    requireFeature(vm, feature);
    return false;
  }
}

bool String::lookupFeature(RichNode self, VM vm, nativeint feature,
                           nullable<UnstableNode&> value) {
  LString<nchar> slice = sliceByCodePointsFromTo(_string, feature, feature+1);
  if (slice.isError()) {
    if (slice.error == UnicodeErrorReason::indexOutOfBounds) {
      return false;
    } else {
      raiseUnicodeError(vm, slice.error, self);
    }
  }

  char32_t codePoint;
  nativeint length;
  std::tie(codePoint, length) = fromUTF(slice.string, slice.length);
  if (length <= 0)
    raiseUnicodeError(vm, (UnicodeErrorReason) length, self, feature);

  if (value.isDefined())
    value.get() = mozart::build(vm, (nativeint) codePoint);
  return true;
}

// VirtualString ---------------------------------------------------------------

void String::toString(VM vm, std::basic_ostream<nchar>& sink) {
  sink << _string;
}

nativeint String::vsLength(VM vm) {
  return codePointCount(_string);
}

// Miscellaneous ---------------------------------------------------------------

void String::printReprToStream(VM vm, std::ostream& out, int depth) {
  out << '"' << toUTF<char>(_string) << '"';
}

}

#endif // MOZART_GENERATOR

#endif // __STRING_H
