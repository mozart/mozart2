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

#ifndef __STRINGOFFSET_H
#define __STRINGOFFSET_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

//////////////////
// StringOffset //
//////////////////

#include "StringOffset-implem.hh"

// Core methods ----------------------------------------------------------------

Implementation<StringOffset>::Implementation(VM vm, nativeint offset,
                                             RichNode refString,
                                             nativeint index)
    : _offset(offset), _index(index)
{
  _ref.init(vm, refString);
  if (!refString.is<String>() && index < 0)
    _index = _offset;
}

Implementation<StringOffset>::Implementation(VM vm, GR gr, Self from)
    : _offset(from->_offset), _index(from->_index)
{
  gr->copyStableNode(_ref, from->_ref);
}

void Implementation<StringOffset>::resolveCharIndex(VM vm) {
  if (_index >= 0)
    return;

  LString<nchar>* string = nullptr;
  OpResult opRes = StringLike(_ref).stringGet(vm, string);
  assert(opRes.isProceed());
  if (!opRes.isProceed())
    return;
  LString<nchar> slice = string->slice(0, _offset);
  _index = codePointCount(slice);
  assert(_index >= 0);
}

bool Implementation<StringOffset>::refIs(VM vm, RichNode rhs) {
  return rhs.isSameNode(_ref);
}


bool Implementation<StringOffset>::equals(VM vm, Self right) {
  return compareFeatures(vm, right) == 0;
}

int Implementation<StringOffset>::compareFeatures(VM vm, Self right) {
  // If both string offsets refer to the same string, we can compare the offsets.
  if (refIs(vm, right->_ref)) {
    return _offset < right->_offset ? -1 : _offset > right->_offset ? 1 : 0;
  }

  // We need to resolve the character index and compare.
  resolveCharIndex(vm);
  right->resolveCharIndex(vm);
  return _index < right->_index ? -1 : _index > right->_index ? 1 : 0;
}

void Implementation<StringOffset>::printReprToStream(Self self, VM vm,
                                                     std::ostream& out, int depth) {
  out << "<StringOffset " << _offset << "/" << _index << ">";
}

// Comparable ------------------------------------------------------------------

OpResult Implementation<StringOffset>::compare(Self self, VM vm,
                                               RichNode right, int& result) {
  bool isStringOffset;
  MOZART_CHECK_OPRESULT(StringOffsetLike(right).isStringOffset(vm, isStringOffset));
  if (!isStringOffset)
    return raiseTypeError(vm, MOZART_STR("StringOffset"), right);

  if (right.is<StringOffset>()) {
    result = ::mozart::compareFeatures(vm, self, right);
  } else {
    resolveCharIndex(vm);
    nativeint rightCharIndex;
    MOZART_CHECK_OPRESULT(StringOffsetLike(right).getCharIndex(vm, rightCharIndex));
    result = _index < rightCharIndex ? -1 : _index > rightCharIndex ? 1 : 0;
  }
  return OpResult::proceed();
}

// StringOffsetLike ------------------------------------------------------------

OpResult Implementation<StringOffset>::toStringOffset(Self self, VM vm,
                                                      RichNode string,
                                                      nativeint& offset) {
  if (refIs(vm, string)) {
    offset = _offset;
    return OpResult::proceed();
  } else {
    resolveCharIndex(vm);
    UnstableNode intNode = SmallInt::build(vm, _index);
    return RichNode(intNode).as<SmallInt>().toStringOffset(vm, string, offset);
  }
}

OpResult Implementation<StringOffset>::getCharIndex(Self self, VM vm,
                                                    nativeint& index) {
  resolveCharIndex(vm);
  index = _index;
  return OpResult::proceed();
}

OpResult Implementation<StringOffset>::stringOffsetAdvance(Self self, VM vm,
                                                           RichNode refNode,
                                                           nativeint delta,
                                                           UnstableNode& result) {

  if (refIs(vm, refNode) && refNode.is<String>()) {
    nativeint newIndex = _index >= 0 ? _index + delta : -1;
    nativeint newOffset;
    UnicodeErrorReason error;

    LString<nchar>* wholeString;
    MOZART_CHECK_OPRESULT(StringLike(refNode).stringGet(vm, wholeString));
    if (delta >= 0) {

      LString<nchar> origSlice = wholeString->slice(_offset);
      LString<nchar> advancedSlice = sliceByCodePoints(origSlice, delta, 0);
      if (advancedSlice.isError()) {
        error = advancedSlice.error;
      } else {
        newOffset = advancedSlice.string - wholeString->string;
        error = UnicodeErrorReason::empty;
      }

    } else {

      LString<nchar> origSlice = wholeString->slice(0, _offset);
      LString<nchar> retreatedSlice = sliceByCodePoints(origSlice, 0, -delta);
      if (retreatedSlice.isError()) {
        error = retreatedSlice.error;
      } else {
        newOffset = retreatedSlice.end() - wholeString->string;
        error = UnicodeErrorReason::empty;
      }

    }

    switch (error) {
      case UnicodeErrorReason::empty:
        result.make<StringOffset>(vm, newOffset, refNode, newIndex);
        return OpResult::proceed();
      case UnicodeErrorReason::indexOutOfBounds:
        result.make<Boolean>(vm, false);
        return OpResult::proceed();
      default:
        return raiseUnicodeError(vm, error, refNode, self);
    }

  } else {

    resolveCharIndex(vm);
    UnstableNode intNode = SmallInt::build(vm, _index);
    return RichNode(intNode).as<SmallInt>().stringOffsetAdvance(vm, refNode, delta, result);

  }
}

}

#endif

#endif

