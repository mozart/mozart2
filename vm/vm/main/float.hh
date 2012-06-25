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

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

///////////
// Float //
///////////

#include "Float-implem.hh"

void Implementation<Float>::build(double& self, VM vm, GR gr, Self from) {
  self = from.get().value();
}

bool Implementation<Float>::equals(VM vm, Self right) {
  return value() == right.get().value();
}

OpResult Implementation<Float>::compare(Self self, VM vm,
                                        RichNode right, int& result) {
  double rightFloatValue = 0.0;
  MOZART_GET_ARG(rightFloatValue, right, u"float");

  result = (value() < rightFloatValue) ? -1 :
    (value() > rightFloatValue) ? 1 : 0;

  return OpResult::proceed();
}

OpResult Implementation<Float>::equalsFloat(Self self, VM vm,
                                            double right, bool& result) {
  result = value() == right;
  return OpResult::proceed();
}

OpResult Implementation<Float>::opposite(Self self, VM vm,
                                         UnstableNode& result) {
  result.make<Float>(vm, -value());
  return OpResult::proceed();
}

OpResult Implementation<Float>::add(Self self, VM vm,
                                    RichNode right, UnstableNode& result) {
  double rightFloatValue = 0.0;
  MOZART_GET_ARG(rightFloatValue, right, u"float");

  return addValue(self, vm, rightFloatValue, result);
}

OpResult Implementation<Float>::addValue(Self self, VM vm,
                                         double b, UnstableNode& result) {
  result.make<Float>(vm, value() + b);

  return OpResult::proceed();
}

OpResult Implementation<Float>::subtract(Self self, VM vm,
                                         RichNode right, UnstableNode& result) {
  double rightFloatValue = 0.0;
  MOZART_GET_ARG(rightFloatValue, right, u"float");

  return subtractValue(self, vm, rightFloatValue, result);
}

OpResult Implementation<Float>::subtractValue(Self self, VM vm,
                                              double b, UnstableNode& result) {
  result.make<Float>(vm, value() - b);

  return OpResult::proceed();
}

OpResult Implementation<Float>::multiply(Self self, VM vm,
                                         RichNode right, UnstableNode& result) {
  double rightFloatValue = 0.0;
  MOZART_GET_ARG(rightFloatValue, right, u"float");

  return multiplyValue(self, vm, rightFloatValue, result);
}

OpResult Implementation<Float>::multiplyValue(Self self, VM vm,
                                              double b, UnstableNode& result) {
  result.make<Float>(vm, value() * b);

  return OpResult::proceed();
}

OpResult Implementation<Float>::divide(Self self, VM vm,
                                       RichNode right, UnstableNode& result) {
  double rightFloatValue = 0.0;
  MOZART_GET_ARG(rightFloatValue, right, u"float");

  return divideValue(self, vm, rightFloatValue, result);
}

OpResult Implementation<Float>::divideValue(Self self, VM vm,
                                            double b, UnstableNode& result) {
  result.make<Float>(vm, value() / b);

  return OpResult::proceed();
}

OpResult Implementation<Float>::div(Self self, VM vm,
                                    RichNode right, UnstableNode& result) {
  return raiseTypeError(vm, u"Integer", self);
}

OpResult Implementation<Float>::mod(Self self, VM vm,
                                    RichNode right, UnstableNode& result) {
  return raiseTypeError(vm, u"Integer", self);
}

}

#endif // MOZART_GENERATOR

#endif // __FLOAT_H
