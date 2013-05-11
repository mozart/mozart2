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
bool LiteralHelper<T>::lookupFeature(VM vm, RichNode feature,
                                     nullable<UnstableNode&> value) {
  requireFeature(vm, feature);
  return false;
}

template <class T>
bool LiteralHelper<T>::lookupFeature(VM vm, nativeint feature,
                                     nullable<UnstableNode&> value) {
  return false;
}

template <class T>
UnstableNode LiteralHelper<T>::label(RichNode self, VM vm) {
  return { vm, self };
}

template <class T>
size_t LiteralHelper<T>::width(VM vm) {
  return 0;
}

template <class T>
UnstableNode LiteralHelper<T>::arityList(VM vm) {
  return build(vm, vm->coreatoms.nil);
}

template <class T>
UnstableNode LiteralHelper<T>::clone(RichNode self, VM vm) {
  return { vm, self };
}

template <class T>
UnstableNode LiteralHelper<T>::waitOr(VM vm) {
  // Wait forever
  UnstableNode dummyVar = Variable::build(vm);
  waitFor(vm, dummyVar);
}

template <class T>
bool LiteralHelper<T>::testRecord(VM vm, RichNode arity) {
  return false;
}

template <class T>
bool LiteralHelper<T>::testTuple(RichNode self, VM vm,
                                 RichNode label, size_t width) {
  if (width == 0)
    return equals(vm, self, label);
  else
    return false;
}

template <class T>
bool LiteralHelper<T>::testLabel(RichNode self, VM vm, RichNode label) {
  return equals(vm, self, label);
}

///////////////////////////
// IntegerDottableHelper //
///////////////////////////

template <class T>
bool IntegerDottableHelper<T>::lookupFeature(VM vm, RichNode feature,
                                             nullable<UnstableNode&> value) {
  using namespace patternmatching;

  nativeint featureIntValue = 0;

  // Fast-path for the integer case
  if (matches(vm, feature, capture(featureIntValue))) {
    return lookupFeature(vm, featureIntValue, value);
  } else {
    requireFeature(vm, feature);
    return false;
  }
}

template <class T>
bool IntegerDottableHelper<T>::lookupFeature(VM vm, nativeint feature,
                                             nullable<UnstableNode&> value) {
  if (!internalIsValidFeature(vm, feature)) {
    return false;
  } else {
    if (value.isDefined())
      value.get() = internalGetValueAt(vm, feature);
    return true;
  }
}

}

#endif // MOZART_GENERATOR

#endif // __DATATYPESHELPERS_H
