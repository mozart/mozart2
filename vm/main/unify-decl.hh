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

#include "core-forward-decl.hh"

#include "store-decl.hh"
#include "vmallocatedlist-decl.hh"

namespace mozart {

inline
OpResult unify(VM vm, RichNode left, RichNode right);

inline
OpResult equals(VM vm, RichNode left, RichNode right, bool& result);

inline
OpResult notEquals(VM vm, RichNode left, RichNode right, bool& result);

inline
OpResult patternMatch(VM vm, RichNode value, RichNode pattern,
                      StaticArray<UnstableNode> captures, bool& result);

/////////////////////
// Data structures //
/////////////////////

struct WalkStackEntry {
private:
  friend class WalkStack;
  friend struct StructuralDualWalk;

  template <class T, class MM>
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
  inline
  void push(VM vm, StableNode* left, StableNode* right);

  inline
  void pushArray(VM vm, StaticArray<StableNode> left,
                 StaticArray<StableNode> right, size_t count);
private:
  friend struct StructuralDualWalk;

  inline
  bool empty();

  inline
  WalkStackEntry& front();

  inline
  void remove_front(VM vm);

  inline
  void clear(VM vm);
};

}

#endif // __UNIFY_DECL_H
