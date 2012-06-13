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
  auto utf8Result = toUTF<char>(vm, _string);
  out << '"' << utf8Result << '"';
  utf8Result.free(vm);
}

OpResult Implementation<String>::toAtom(Self self, VM vm, UnstableNode& result) {
  result.make<Atom>(vm, _string.length, _string.string);
  return OpResult::proceed();
}

OpResult Implementation<String>::hasFeature(RichNode self, VM vm,
                                            RichNode feature, bool& result) {
  using namespace patternmatching;

  OpResult opRes = OpResult::proceed();
  nativeint value;

  if (_string.length > 0 && matches(vm, opRes, feature, capture(value))) {
    result = value == 1 || value == 2;
    return OpResult::proceed();
  } else if (opRes.isProceed()) {
    MOZART_REQUIRE_FEATURE(feature);
    result = false;
    return OpResult::proceed();
  } else {
    return opRes;
  }
}

OpResult Implementation<String>::dotNumber(Self self, VM vm,
                                           nativeint feature, UnstableNode& result) {
  if (_string.length <= 0 || (feature != 1 && feature != 2)) {
    return raise(vm, vm->coreatoms.illegalFieldSelection,
                 self, SmallInt::build(vm, feature));

  } else if (feature == 1) {
    auto decodeRes = fromUTF(_string.string);
    if (decodeRes.second < 0)
      return raiseUnicodeError(vm, (UnicodeErrorReason) decodeRes.second, self);
    result.make<SmallInt>(vm, decodeRes.first);
    return OpResult::proceed();

  } else {
    nativeint stride = getUTFStride(_string.string);
    if (stride <= 0)
      return raiseUnicodeError(vm, (UnicodeErrorReason) stride, self);
    result.make<String>(vm, LString<nchar>(_string.string + stride, _string.length - stride));
    return OpResult::proceed();
  }
}

OpResult Implementation<String>::dot(Self self, VM vm,
                                     RichNode feature, UnstableNode& result) {
  using namespace patternmatching;

  OpResult res = OpResult::proceed();
  nativeint featureIntValue = 0;

  // Fast-path for the integer case
  if (matches(vm, res, feature, capture(featureIntValue))) {
    return dotNumber(self, vm, featureIntValue, result);
  } else {
    MOZART_REQUIRE_FEATURE(feature);
    return raise(vm, vm->coreatoms.illegalFieldSelection, self, feature);
  }
}

OpResult Implementation<String>::label(Self self, VM vm, UnstableNode& result) {
  result.make<Atom>(vm, _string.isErrorOrEmpty() ? vm->coreatoms.nil : vm->coreatoms.pipe);
  return OpResult::proceed();
}

OpResult Implementation<String>::width(Self self, VM vm, size_t& result) {
  result = _string.isErrorOrEmpty() ? 0 : 2;
  return OpResult::proceed();
}

OpResult Implementation<String>::arityList(Self self, VM vm,
                                           UnstableNode& result) {
  if (_string.isErrorOrEmpty())
    result.make<Atom>(vm, vm->coreatoms.nil);
  else
    result = buildCons(vm, 1, buildCons(vm, 2, vm->coreatoms.nil));
  return OpResult::proceed();
}

OpResult Implementation<String>::clone(Self self, VM vm, UnstableNode& result) {
  if (_string.isErrorOrEmpty()) {
    result.make<Atom>(vm, vm->coreatoms.nil);
  } else {
    result = buildCons(vm, Unbound::build(vm),
                           buildCons(vm, Unbound::build(vm), vm->coreatoms.nil));
  }
  return OpResult::proceed();
}

OpResult Implementation<String>::waitOr(Self self, VM vm, UnstableNode& result) {
  if (_string.isErrorOrEmpty()) {
    // Wait forever (refer to LiteralHelper<Self>::waitOr)
    UnstableNode dummyVar = Variable::build(vm);
    return OpResult::waitFor(vm, dummyVar);
  } else {
    // No need to 'wait', all features are always available.
    result.make<SmallInt>(vm, 1);
    return OpResult::proceed();
  }
}

OpResult Implementation<String>::toString(Self self, VM vm,
                                          std::basic_ostream<nchar>& sink) {
  sink << _string;
  return OpResult::proceed();
}

OpResult Implementation<String>::vsLength(Self self, VM vm, nativeint& result) {
  result = codePointCount(_string);
  return OpResult::proceed();
}

OpResult Implementation<String>::vsChangeSign(Self self, VM vm,
                                              RichNode replacement,
                                              UnstableNode& result) {
  result.copy(vm, self);
  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __STRING_H


