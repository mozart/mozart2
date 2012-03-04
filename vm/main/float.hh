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

#include <iostream>

//////////////////
// Inline Float //
//////////////////

#ifndef MOZART_GENERATOR
#include "Float-implem.hh"
#endif

double Implementation<Float>::build(VM vm, GC gc, Self from) {
  return from.get().value();
}

BuiltinResult Implementation<Float>::equals(Self self, VM vm,
                                            UnstableNode* right,
                                            UnstableNode* result) {
  Node& rightNode = Reference::dereference(right->node);

  if (rightNode.type == Float::type()) {
    double r = IMPLNOSELF(double, Float, value, &rightNode);
    result->make<Boolean>(vm, value() == r);
    return BuiltinResultContinue;
  } else if (rightNode.type->isTransient()) {
    return &rightNode;
  } else {
    // TODO Float == non-Float
    result->make<Boolean>(vm, false);
    return BuiltinResultContinue;
  }
}

BuiltinResult Implementation<Float>::equalsFloat(Self self, VM vm,
                                                 double right,
                                                 bool* result) {
  *result = value() == right;
  return BuiltinResultContinue;
}

BuiltinResult Implementation<Float>::add(Self self, VM vm,
                                         UnstableNode* right,
                                         UnstableNode* result) {
  Node& rightNode = Reference::dereference(right->node);

  if (rightNode.type == Float::type()) {
    double b = IMPLNOSELF(double, Float, value, &rightNode);
    return addValue(self, vm, b, result);
  } else if (rightNode.type->isTransient()) {
    return &rightNode;
  } else {
    // TODO Float + non-Float
    std::cout << "Float expected but " << rightNode.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }
}

BuiltinResult Implementation<Float>::addValue(Self self, VM vm,
                                              double b,
                                              UnstableNode* result) {
  result->make<Float>(vm, value() + b);

  return BuiltinResultContinue;
}

BuiltinResult Implementation<Float>::subtract(Self self, VM vm,
                                              UnstableNode* right,
                                              UnstableNode* result) {
  Node& rightNode = Reference::dereference(right->node);

  if (rightNode.type == Float::type()) {
    double b = IMPLNOSELF(double, Float, value, &rightNode);
    return subtractValue(self, vm, b, result);
  } else if (rightNode.type->isTransient()) {
    return &rightNode;
  } else {
    // TODO Float - non-Float
    std::cout << "Float expected but " << rightNode.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }
}

BuiltinResult Implementation<Float>::subtractValue(Self self, VM vm,
                                                   double b,
                                                   UnstableNode* result) {
  result->make<Float>(vm, value() - b);

  return BuiltinResultContinue;
}

BuiltinResult Implementation<Float>::multiply(Self self, VM vm,
                                              UnstableNode* right,
                                              UnstableNode* result) {
  Node& rightNode = Reference::dereference(right->node);

  if (rightNode.type == Float::type()) {
    double b = IMPLNOSELF(double, Float, value, &rightNode);
    return multiplyValue(self, vm, b, result);
  } else if (rightNode.type->isTransient()) {
    return &rightNode;
  } else {
    // TODO Float * non-Float
    std::cout << "Float expected but " << rightNode.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }
}

BuiltinResult Implementation<Float>::multiplyValue(Self self, VM vm,
                                                   double b,
                                                   UnstableNode* result) {
  result->make<Float>(vm, value() * b);

  return BuiltinResultContinue;
}

BuiltinResult Implementation<Float>::divide(Self self, VM vm,
                                            UnstableNode* right,
                                            UnstableNode* result) {
  Node& rightNode = Reference::dereference(right->node);

  if (rightNode.type == Float::type()) {
    double b = IMPLNOSELF(double, Float, value, &rightNode);
    return divideValue(self, vm, b, result);
  } else if (rightNode.type->isTransient()) {
    return &rightNode;
  } else {
    // TODO Float / non-Float
    std::cout << "Float expected but " << rightNode.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }
}

BuiltinResult Implementation<Float>::divideValue(Self self, VM vm,
                                                 double b,
                                                 UnstableNode* result) {
  result->make<Float>(vm, value() / b);

  return BuiltinResultContinue;
}

BuiltinResult Implementation<Float>::div(Self self, VM vm,
                                         UnstableNode* right,
                                         UnstableNode* result) {
  // TODO Raise exception
  std::cout << "Floats don't support arithmetic operation 'div'" << std::endl;
  return BuiltinResultContinue;
}

BuiltinResult Implementation<Float>::mod(Self self, VM vm,
                                         UnstableNode* right,
                                         UnstableNode* result) {
  // TODO Raise exception
  std::cout << "Floats don't support arithmetic operation 'mod'" << std::endl;
  return BuiltinResultContinue;
}

#endif // __FLOAT_H
