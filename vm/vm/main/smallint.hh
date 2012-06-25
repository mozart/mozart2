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

#include "mozartcore.hh"

#include <limits>

#ifndef MOZART_GENERATOR

namespace mozart {

//////////////
// SmallInt //
//////////////

#include "SmallInt-implem.hh"

void Implementation<SmallInt>::build(nativeint& self, VM vm, GR gr, Self from) {
  self = from.get().value();
}

bool Implementation<SmallInt>::equals(VM vm, Self right) {
  return value() == right.get().value();
}

int Implementation<SmallInt>::compareFeatures(VM vm, Self right) {
  if (value() == right.get().value())
    return 0;
  else if (value() < right.get().value())
    return -1;
  else
    return 1;
}

OpResult Implementation<SmallInt>::compare(Self self, VM vm,
                                           RichNode right,
                                           int& result) {
  nativeint rightIntValue = 0;
  MOZART_GET_ARG(rightIntValue, right, u"integer");

  result = (value() == rightIntValue) ? 0 :
    (value() < rightIntValue) ? -1 : 1;

  return OpResult::proceed();
}

OpResult Implementation<SmallInt>::equalsInteger(Self self, VM vm,
                                                 nativeint right,
                                                 bool& result) {
  result = value() == right;
  return OpResult::proceed();
}

OpResult Implementation<SmallInt>::opposite(Self self, VM vm,
                                            UnstableNode& result) {
  // Detecting overflow - platform dependent (2's complement)
  if (value() != std::numeric_limits<nativeint>::min()) {
    // No overflow
    result.make<SmallInt>(vm, -value());
  } else {
    // Overflow - TODO: create a BigInt
    result.make<SmallInt>(vm, 0);
  }

  return OpResult::proceed();
}

OpResult Implementation<SmallInt>::add(Self self, VM vm,
                                       RichNode right, UnstableNode& result) {
  nativeint rightIntValue = 0;
  MOZART_GET_ARG(rightIntValue, right, u"integer");

  return addValue(self, vm, rightIntValue, result);
}

OpResult Implementation<SmallInt>::addValue(Self self, VM vm,
                                            nativeint b, UnstableNode& result) {
  nativeint a = value();
  nativeint c = a + b;

  // Detecting overflow - platform dependent (2's complement)
  if ((((a ^ c) & (b ^ c)) >> std::numeric_limits<nativeint>::digits) == 0) {
    // No overflow
    result.make<SmallInt>(vm, c);
  } else {
    // Overflow - TODO: create a BigInt
    result.make<SmallInt>(vm, 0);
  }

  return OpResult::proceed();
}

OpResult Implementation<SmallInt>::subtract(Self self, VM vm,
                                            RichNode right,
                                            UnstableNode& result) {
  nativeint rightIntValue = 0;
  MOZART_GET_ARG(rightIntValue, right, u"integer");

  return subtractValue(self, vm, rightIntValue, result);
}

OpResult Implementation<SmallInt>::subtractValue(Self self, VM vm,
                                                 nativeint b,
                                                 UnstableNode& result) {
  nativeint a = value();
  nativeint c = a - b;

  // Detecting overflow - platform dependent (2's complement)
  if ((((a ^ c) & (-b ^ c)) >> std::numeric_limits<nativeint>::digits) == 0) {
    // No overflow
    result.make<SmallInt>(vm, c);
  } else {
    // Overflow - TODO: create a BigInt
    result.make<SmallInt>(vm, 0);
  }

  return OpResult::proceed();
}

OpResult Implementation<SmallInt>::multiply(Self self, VM vm,
                                            RichNode right,
                                            UnstableNode& result) {
  nativeint rightIntValue = 0;
  MOZART_GET_ARG(rightIntValue, right, u"integer");

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

OpResult Implementation<SmallInt>::multiplyValue(Self self, VM vm,
                                                 nativeint b,
                                                 UnstableNode& result) {
  nativeint a = value();

  // Detecting overflow
  if (!testMultiplyOverflow(a, b)) {
    // No overflow
    result.make<SmallInt>(vm, a * b);
  } else {
    // Overflow - TODO: create a BigInt
    result.make<SmallInt>(vm, 0);
  }

  return OpResult::proceed();
}

OpResult Implementation<SmallInt>::divide(Self self, VM vm,
                                          RichNode right,
                                          UnstableNode& result) {
  return raiseTypeError(vm, u"Float", self);
}

OpResult Implementation<SmallInt>::div(Self self, VM vm,
                                       RichNode right, UnstableNode& result) {
  nativeint rightIntValue = 0;
  MOZART_GET_ARG(rightIntValue, right, u"integer");

  return divValue(self, vm, rightIntValue, result);
}

OpResult Implementation<SmallInt>::divValue(Self self, VM vm,
                                            nativeint b, UnstableNode& result) {
  nativeint a = value();

  // Detecting overflow
  if ((a != std::numeric_limits<nativeint>::min()) || (b != -1)) {
    // No overflow
    result.make<SmallInt>(vm, a / b);
  } else {
    // Overflow - TODO: create a BigInt
    result.make<SmallInt>(vm, 0);
  }

  return OpResult::proceed();
}

OpResult Implementation<SmallInt>::mod(Self self, VM vm,
                                       RichNode right, UnstableNode& result) {
  nativeint rightIntValue = 0;
  MOZART_GET_ARG(rightIntValue, right, u"integer");

  return modValue(self, vm, rightIntValue, result);
}

OpResult Implementation<SmallInt>::modValue(Self self, VM vm,
                                            nativeint b, UnstableNode& result) {
  nativeint a = value();

  // Detecting overflow
  if ((a != std::numeric_limits<nativeint>::min()) || (b != -1)) {
    // No overflow
    result.make<SmallInt>(vm, a % b);
  } else {
    // Overflow - TODO: create a BigInt
    result.make<SmallInt>(vm, 0);
  }

  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __SMALLINT_H
