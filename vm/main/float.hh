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

#ifndef __FLOAT_H
#define __FLOAT_H

#include "float-decl.hh"

#include "boolean.hh"
#include "coreinterfaces.hh"

#include <iostream>

namespace mozart {

//////////////////
// Inline Float //
//////////////////

#ifndef MOZART_GENERATOR
#include "Float-implem.hh"
#endif

double Implementation<Float>::build(VM vm, GC gc, Self from) {
  return from.get().value();
}

bool Implementation<Float>::equals(VM vm, Self right) {
  return value() == right.get().value();
}

BuiltinResult Implementation<Float>::equalsFloat(Self self, VM vm,
                                                 double right,
                                                 bool* result) {
  *result = value() == right;
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Float>::add(Self self, VM vm,
                                         UnstableNode* right,
                                         UnstableNode* result) {
  double rightFloatValue = 0.0;
  FloatValue rightValue = *right;

  BuiltinResult res = rightValue.floatValue(vm, &rightFloatValue);
  if (!res.isProceed())
    return res;

  return addValue(self, vm, rightFloatValue, result);
}

BuiltinResult Implementation<Float>::addValue(Self self, VM vm,
                                              double b,
                                              UnstableNode* result) {
  result->make<Float>(vm, value() + b);

  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Float>::subtract(Self self, VM vm,
                                              UnstableNode* right,
                                              UnstableNode* result) {
  double rightFloatValue = 0.0;
  FloatValue rightValue = *right;

  BuiltinResult res = rightValue.floatValue(vm, &rightFloatValue);
  if (!res.isProceed())
    return res;

  return subtractValue(self, vm, rightFloatValue, result);
}

BuiltinResult Implementation<Float>::subtractValue(Self self, VM vm,
                                                   double b,
                                                   UnstableNode* result) {
  result->make<Float>(vm, value() - b);

  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Float>::multiply(Self self, VM vm,
                                              UnstableNode* right,
                                              UnstableNode* result) {
  double rightFloatValue = 0.0;
  FloatValue rightValue = *right;

  BuiltinResult res = rightValue.floatValue(vm, &rightFloatValue);
  if (!res.isProceed())
    return res;

  return multiplyValue(self, vm, rightFloatValue, result);
}

BuiltinResult Implementation<Float>::multiplyValue(Self self, VM vm,
                                                   double b,
                                                   UnstableNode* result) {
  result->make<Float>(vm, value() * b);

  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Float>::divide(Self self, VM vm,
                                            UnstableNode* right,
                                            UnstableNode* result) {
  double rightFloatValue = 0.0;
  FloatValue rightValue = *right;

  BuiltinResult res = rightValue.floatValue(vm, &rightFloatValue);
  if (!res.isProceed())
    return res;

  return divideValue(self, vm, rightFloatValue, result);
}

BuiltinResult Implementation<Float>::divideValue(Self self, VM vm,
                                                 double b,
                                                 UnstableNode* result) {
  result->make<Float>(vm, value() / b);

  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Float>::div(Self self, VM vm,
                                         UnstableNode* right,
                                         UnstableNode* result) {
  return raiseTypeError(vm, u"Integer", self);
}

BuiltinResult Implementation<Float>::mod(Self self, VM vm,
                                         UnstableNode* right,
                                         UnstableNode* result) {
  return raiseTypeError(vm, u"Integer", self);
}

}

#endif // __FLOAT_H
