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

#include "boolean.hh"

#include <limits>
#include <iostream>

/////////////////////
// Inline SmallInt //
/////////////////////

BuiltinResult Implementation<SmallInt>::equals(Node* self, VM vm,
                                               UnstableNode* right,
                                               UnstableNode* result) {
  Node& rightNode = Reference::dereference(right->node);

  if (rightNode.type == SmallInt::type) {
    nativeint r = IMPLNOSELF(nativeint, SmallInt, value, &rightNode);
    result->make<Boolean>(vm, value() == r);
    return BuiltinResultContinue;
  } else if (rightNode.type->isTransient()) {
    return &rightNode;
  } else {
    // TODO SmallInt == non-SmallInt
    result->make<Boolean>(vm, false);
    return BuiltinResultContinue;
  }
}

BuiltinResult Implementation<SmallInt>::equalsInteger(Node* self, VM vm,
                                                      nativeint right,
                                                      bool* result) {
  *result = value() == right;
  return BuiltinResultContinue;
}

BuiltinResult Implementation<SmallInt>::add(Node* self, VM vm,
                                            UnstableNode* right,
                                            UnstableNode* result) {
  Node& rightNode = Reference::dereference(right->node);

  if (rightNode.type == SmallInt::type) {
    nativeint b = IMPLNOSELF(nativeint, SmallInt, value, &rightNode);
    return addValue(self, vm, b, result);
  } else if (rightNode.type->isTransient()) {
    return &rightNode;
  } else {
    // TODO SmallInt + non-SmallInt
    std::cout << "SmallInt expected but " << rightNode.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }
}

BuiltinResult Implementation<SmallInt>::addValue(Node* self, VM vm,
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

  return BuiltinResultContinue;
}

#endif // __SMALLINT_H
