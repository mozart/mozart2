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

#ifndef __SMALLINT_H
#define __SMALLINT_H

#include "smallint-decl.hh"

#include "coreinterfaces.hh"
#include "boolean.hh"

#include <limits>
#include <iostream>

/////////////////////
// Inline SmallInt //
/////////////////////

#ifndef MOZART_GENERATOR
#include "SmallInt-implem.hh"
#endif

nativeint Implementation<SmallInt>::build(VM vm, GC gc, SelfReadOnlyView from) {
  return from.get().value();
}

BuiltinResult Implementation<SmallInt>::equals(Self self, VM vm,
                                               UnstableNode* right,
                                               UnstableNode* result) {
  RichNode rightNode = *right;

  if (rightNode.type() == SmallInt::type()) {
    nativeint r = rightNode.as<SmallInt>().value();
    result->make<Boolean>(vm, value() == r);
    return BuiltinResult::proceed();
  } else if (rightNode.type()->isTransient()) {
    return BuiltinResult::waitFor(vm, rightNode);
  } else {
    // TODO SmallInt == non-SmallInt
    result->make<Boolean>(vm, false);
    return BuiltinResult::proceed();
  }
}

BuiltinResult Implementation<SmallInt>::equalsInteger(Self self, VM vm,
                                                      nativeint right,
                                                      bool* result) {
  *result = value() == right;
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<SmallInt>::add(Self self, VM vm,
                                            UnstableNode* right,
                                            UnstableNode* result) {
  nativeint rightIntValue = 0;
  IntegerValue rightValue = *right;

  BuiltinResult res = rightValue.intValue(vm, &rightIntValue);
  if (!res.isProceed())
    return res;

  return addValue(self, vm, rightIntValue, result);
}

BuiltinResult Implementation<SmallInt>::addValue(Self self, VM vm,
                                                 nativeint b,
                                                 UnstableNode* result) {
  nativeint a = value();
  nativeint c = a + b;

  // Detecting overflow - platform dependent (2's complement)
  if ((((a ^ c) & (b ^ c)) >> std::numeric_limits<nativeint>::digits) == 0) {
    // No overflow
    result->make<SmallInt>(vm, c);
  } else {
    // Overflow - TODO: create a BigInt
    result->make<SmallInt>(vm, 0);
  }

  return BuiltinResult::proceed();
}

BuiltinResult Implementation<SmallInt>::subtract(Self self, VM vm,
                                                 UnstableNode* right,
                                                 UnstableNode* result) {
  nativeint rightIntValue = 0;
  IntegerValue rightValue = *right;

  BuiltinResult res = rightValue.intValue(vm, &rightIntValue);
  if (!res.isProceed())
    return res;

  return subtractValue(self, vm, rightIntValue, result);
}

BuiltinResult Implementation<SmallInt>::subtractValue(Self self, VM vm,
                                                      nativeint b,
                                                      UnstableNode* result) {
  nativeint a = value();
  nativeint c = a - b;

  // Detecting overflow - platform dependent (2's complement)
  if ((((a ^ c) & (-b ^ c)) >> std::numeric_limits<nativeint>::digits) == 0) {
    // No overflow
    result->make<SmallInt>(vm, c);
  } else {
    // Overflow - TODO: create a BigInt
    result->make<SmallInt>(vm, 0);
  }

  return BuiltinResult::proceed();
}

BuiltinResult Implementation<SmallInt>::multiply(Self self, VM vm,
                                                 UnstableNode* right,
                                                 UnstableNode* result) {
  nativeint rightIntValue = 0;
  IntegerValue rightValue = *right;

  BuiltinResult res = rightValue.intValue(vm, &rightIntValue);
  if (!res.isProceed())
    return res;

  return multiplyValue(self, vm, rightIntValue, result);
}

bool Implementation<SmallInt>::testMultiplyOverflow(nativeint a, nativeint b) {
  // This is platform dependent (2's complement)

  nativeint absa = a < 0 ? -a : a;
  nativeint absb = b < 0 ? -b : b;

  // Fast test first
  // If both absa and absb < sqrt(max()), then obviously there is no overflow
  const int bits = std::numeric_limits<nativeint>::digits / 2;
  if (((absa | absb) >> bits) == 0)
    return false;

  // Slow test (because of the division)
  return (b != 0) && (absa >= std::numeric_limits<nativeint>::max() / absb);
}

BuiltinResult Implementation<SmallInt>::multiplyValue(Self self, VM vm,
                                                      nativeint b,
                                                      UnstableNode* result) {
  nativeint a = value();

  // Detecting overflow
  if (!testMultiplyOverflow(a, b)) {
    // No overflow
    result->make<SmallInt>(vm, a * b);
  } else {
    // Overflow - TODO: create a BigInt
    result->make<SmallInt>(vm, 0);
  }

  return BuiltinResult::proceed();
}

BuiltinResult Implementation<SmallInt>::divide(Self self, VM vm,
                                               UnstableNode* right,
                                               UnstableNode* result) {
  return raiseTypeError(vm, u"Float", self);
}

BuiltinResult Implementation<SmallInt>::div(Self self, VM vm,
                                            UnstableNode* right,
                                            UnstableNode* result) {
  nativeint rightIntValue = 0;
  IntegerValue rightValue = *right;

  BuiltinResult res = rightValue.intValue(vm, &rightIntValue);
  if (!res.isProceed())
    return res;

  return divValue(self, vm, rightIntValue, result);
}

BuiltinResult Implementation<SmallInt>::divValue(Self self, VM vm,
                                                 nativeint b,
                                                 UnstableNode* result) {
  nativeint a = value();

  // Detecting overflow
  if ((a != std::numeric_limits<nativeint>::min()) || (b != -1)) {
    // No overflow
    result->make<SmallInt>(vm, a / b);
  } else {
    // Overflow - TODO: create a BigInt
    result->make<SmallInt>(vm, 0);
  }

  return BuiltinResult::proceed();
}

BuiltinResult Implementation<SmallInt>::mod(Self self, VM vm,
                                            UnstableNode* right,
                                            UnstableNode* result) {
  nativeint rightIntValue = 0;
  IntegerValue rightValue = *right;

  BuiltinResult res = rightValue.intValue(vm, &rightIntValue);
  if (!res.isProceed())
    return res;

  return modValue(self, vm, rightIntValue, result);
}

BuiltinResult Implementation<SmallInt>::modValue(Self self, VM vm,
                                                 nativeint b,
                                                 UnstableNode* result) {
  nativeint a = value();

  // Detecting overflow
  if ((a != std::numeric_limits<nativeint>::min()) || (b != -1)) {
    // No overflow
    result->make<SmallInt>(vm, a % b);
  } else {
    // Overflow - TODO: create a BigInt
    result->make<SmallInt>(vm, 0);
  }

  return BuiltinResult::proceed();
}

#endif // __SMALLINT_H
