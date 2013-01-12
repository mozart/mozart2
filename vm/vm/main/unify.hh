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

#ifndef __UNIFY_H
#define __UNIFY_H

#include "mozartcore.hh"

namespace mozart {

///////////////
// WalkStack //
///////////////

void WalkStack::push(VM vm, StableNode* left, StableNode* right) {
  push_front_new(vm, left, right, 1);
}

void WalkStack::pushArray(VM vm, StaticArray<StableNode> left,
                          StaticArray<StableNode> right, size_t count) {
  push_front_new(vm, &left[(size_t) 0], &right[(size_t) 0], count);
}

bool WalkStack::empty() {
  return Super::empty();
}

WalkStackEntry& WalkStack::front() {
  return Super::front();
}

void WalkStack::remove_front(VM vm) {
  if (front().count == 1)
    Super::remove_front(vm);
  else
    front().next();
}

void WalkStack::clear(VM vm) {
  Super::clear(vm);
}

/////////////////////
// Global routines //
/////////////////////

void fullUnify(VM vm, RichNode left, RichNode right);

bool fullEquals(VM vm, RichNode left, RichNode right);

bool fullPatternMatch(VM vm, RichNode value, RichNode pattern,
                      StaticArray<UnstableNode> captures);

#ifndef MOZART_GENERATOR

void unify(VM vm, RichNode left, RichNode right) {
  if (left.isSameNode(right))
    return;

  auto leftType = left.type();
  auto rightType = right.type();

  StructuralBehavior leftBehavior = leftType.getStructuralBehavior();
  StructuralBehavior rightBehavior = rightType.getStructuralBehavior();

  // Code duplicate with unify.cc. Is it possible to avoid this?
  if (leftBehavior == sbVariable) {
    if (rightBehavior == sbVariable) {
      if (leftType.getBindingPriority() > rightType.getBindingPriority())
        DataflowVariable(left).bind(vm, right);
      else
        DataflowVariable(right).bind(vm, left);
    } else {
      DataflowVariable(left).bind(vm, right);
    }
  } else if (rightBehavior == sbVariable) {
    DataflowVariable(right).bind(vm, left);
  } else {
    fullUnify(vm, left, right);
  }
}

bool equals(VM vm, RichNode left, RichNode right) {
  if (left.isSameNode(right))
    return true;

  auto leftType = left.type();
  auto rightType = right.type();

  StructuralBehavior leftBehavior = leftType.getStructuralBehavior();
  StructuralBehavior rightBehavior = rightType.getStructuralBehavior();

  if (leftBehavior != sbVariable && rightBehavior != sbVariable) {
    if (leftType != rightType)
      return false;

    switch (leftBehavior) {
      case sbValue:
        return ValueEquatable(left).equals(vm, right);

      case sbTokenEq:
        return false;

      default: ; // fall through
    }
  }

  return fullEquals(vm, left, right);
}

bool patternMatch(VM vm, RichNode value, RichNode pattern,
                  StaticArray<UnstableNode> captures) {
  return fullPatternMatch(vm, value, pattern, captures);
}

#endif // MOZART_GENERATOR

}

#endif // __UNIFY_H
