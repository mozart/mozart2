// Copyright © 2011, Université catholique de Louvain
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

#ifndef __DATATYPESHELPERS_H
#define __DATATYPESHELPERS_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

///////////////////
// LiteralHelper //
///////////////////

template <class T>
void LiteralHelper<T>::isLiteral(Self self, VM vm, bool& result) {
  result = true;
}

template <class T>
void LiteralHelper<T>::lookupFeature(
  Self self, VM vm, RichNode feature, bool& found,
  nullable<UnstableNode&> value) {

  requireFeature(vm, feature);
  found = false;
}

template <class T>
void LiteralHelper<T>::lookupFeature(
  Self self, VM vm, nativeint feature, bool& found,
  nullable<UnstableNode&> value) {

  found = false;
}

template <class T>
void LiteralHelper<T>::label(Self self, VM vm, UnstableNode& result) {
  result.copy(vm, self);
}

template <class T>
void LiteralHelper<T>::width(Self self, VM vm, size_t& result) {
  result = 0;
}

template <class T>
void LiteralHelper<T>::arityList(Self self, VM vm, UnstableNode& result) {
  result = build(vm, vm->coreatoms.nil);
}

template <class T>
void LiteralHelper<T>::clone(Self self, VM vm, UnstableNode& result) {
  result.copy(vm, self);
}

template <class T>
void LiteralHelper<T>::waitOr(Self self, VM vm, UnstableNode& result) {
  // Wait forever
  UnstableNode dummyVar = Variable::build(vm);
  waitFor(vm, dummyVar);
}

template <class T>
void LiteralHelper<T>::testRecord(Self self, VM vm, RichNode arity,
                                  bool& result) {
  result = false;
}

template <class T>
void LiteralHelper<T>::testTuple(Self self, VM vm, RichNode label, size_t width,
                                 bool& result) {
  if (width == 0)
    equals(vm, self, label, result);
  else
    result = false;
}

template <class T>
void LiteralHelper<T>::testLabel(Self self, VM vm, RichNode label,
                                 bool& result) {
  return equals(vm, self, label, result);
}

///////////////////////////
// IntegerDottableHelper //
///////////////////////////

template <class T>
void IntegerDottableHelper<T>::lookupFeature(
  Self self, VM vm, RichNode feature, bool& found,
  nullable<UnstableNode&> value) {

  using namespace patternmatching;

  nativeint featureIntValue = 0;

  // Fast-path for the integer case
  if (matches(vm, feature, capture(featureIntValue))) {
    return lookupFeature(self, vm, featureIntValue, found, value);
  } else {
    requireFeature(vm, feature);
    found = false;
  }
}

template <class T>
void IntegerDottableHelper<T>::lookupFeature(
  Self self, VM vm, nativeint feature, bool& found,
  nullable<UnstableNode&> value) {

  found = internalIsValidFeature(self, vm, feature);
  if (found && value.isDefined())
    internalGetValueAt(self, vm, feature, value.get());
}

}

#endif // MOZART_GENERATOR

#endif // __DATATYPESHELPERS_H
