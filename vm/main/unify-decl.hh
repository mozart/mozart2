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

#ifndef __UNIFY_DECL_H
#define __UNIFY_DECL_H

#include "mozartcore.hh"

namespace mozart {

inline
BuiltinResult unify(VM vm, RichNode left, RichNode right);

inline
BuiltinResult equals(VM vm, RichNode left, RichNode right, bool* result);

inline
BuiltinResult notEquals(VM vm, RichNode left, RichNode right, bool* result);

/////////////////////
// Data structures //
/////////////////////

struct WalkStackEntry {
private:
  friend class WalkStack;
  friend struct StructuralDualWalk;

  template <class T>
  friend class MemManagedList;

  WalkStackEntry(StableNode* left, StableNode* right, size_t count = 1) :
    left(left), right(right), count(count) {}

  void next() {
    left++;
    right++;
    count--;
  }

  StableNode* left;
  StableNode* right;
  size_t count;
};

class WalkStack : private VMAllocatedList<WalkStackEntry> {
private:
  typedef VMAllocatedList<WalkStackEntry> Super;
public:
  void push(VM vm, StableNode* left, StableNode* right) {
    push_front_new(vm, left, right, 1);
  }

  void pushArray(VM vm, StaticArray<StableNode> left,
                 StaticArray<StableNode> right, size_t count) {
    push_front_new(vm, &left[0], &right[0], count);
  }
private:
  friend struct StructuralDualWalk;

  bool empty() {
    return Super::empty();
  }

  WalkStackEntry& front() {
    return Super::front();
  }

  void remove_front(VM vm) {
    if (front().count == 1)
      Super::remove_front(vm);
    else
      front().next();
  }

  void clear(VM vm) {
    Super::clear(vm);
  }
};

}

#endif // __UNIFY_DECL_H
