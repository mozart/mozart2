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

///////////////////////////
// IntegerDottableHelper //
///////////////////////////

template <class T>
OpResult IntegerDottableHelper<T>::dot(Self self, VM vm,
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

template <class T>
OpResult IntegerDottableHelper<T>::dotNumber(Self self, VM vm,
                                             nativeint feature,
                                             UnstableNode& result) {
  if (internalIsValidFeature(self, vm, feature)) {
    // Inside bounds
    internalGetValueAt(self, vm, feature, result);
    return OpResult::proceed();
  } else {
    // Out of bounds
    return raise(vm, vm->coreatoms.illegalFieldSelection, self, feature);
  }
}

template <class T>
OpResult IntegerDottableHelper<T>::hasFeature(Self self, VM vm,
                                              RichNode feature,
                                              bool& result) {
  using namespace patternmatching;

  OpResult res = OpResult::proceed();
  nativeint featureIntValue = 0;

  // Fast-path for the integer case
  if (matches(vm, res, feature, capture(featureIntValue))) {
    result = internalIsValidFeature(self, vm, featureIntValue);
    return OpResult::proceed();
  } else {
    MOZART_REQUIRE_FEATURE(feature);
    result = false;
    return OpResult::proceed();
  }
}

////////////////////
// DottableHelper //
////////////////////

template <class T>
OpResult DottableHelper<T>::dotNumber(Self self, VM vm,
                                      nativeint feature,
                                      UnstableNode& result) {
  UnstableNode featureNode = SmallInt::build(vm, feature);
  return static_cast<This>(this)->dot(self, vm, featureNode, result);
}

}

#endif // MOZART_GENERATOR

#endif // __DATATYPESHELPERS_H
