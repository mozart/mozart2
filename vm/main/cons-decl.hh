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

#ifndef __CONS_DECL_H
#define __CONS_DECL_H

#include "mozartcore-decl.hh"
#include "datatypeshelpers-decl.hh"

namespace mozart {

//////////
// Cons //
//////////

class Cons;

#ifndef MOZART_GENERATOR
#include "Cons-implem-decl.hh"
#endif

/**
 * Cons (specialization of Tuple with label '|' and width 2)
 *
 * Also contains a specialization as string.
 */
template <>
class Implementation<Cons>: public IntegerDottableHelper<Cons>,
  WithStructuralBehavior {
public:
  typedef SelfType<Cons>::Self Self;

  static constexpr UUID uuid = "{4da68e43-03d8-4566-8018-f53a19c362f5}";
public:
  inline
  Implementation(VM vm, RichNode head, RichNode tail);

  inline
  Implementation(VM vm, LString<nchar> string);

  inline
  Implementation(VM vm, GR gr, Self from);

public:
  inline
  OpResult getHead(VM vm, UnstableNode& result);

  inline
  OpResult getTail(VM vm, UnstableNode& result);

  inline
  OpResult getStableHeadAndTail(VM vm, StableNode*& head, StableNode*& tail);

  inline
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

public:
  OpResult isString(Self self, VM vm, bool& result) {
    return isVirtualString(self, vm, result);
  }

  inline
  OpResult getString(Self self, VM vm, LString<nchar>& result);

protected:
  friend class IntegerDottableHelper<Cons>;

  bool isValidFeature(Self self, VM vm, nativeint feature) {
    return (feature == 1) || (feature == 2);
  }

  inline
  OpResult getValueAt(Self self, VM vm, nativeint feature, UnstableNode& result);

public:
  // RecordLike interface

  OpResult isRecord(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  OpResult isTuple(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult label(Self self, VM vm, UnstableNode& result);

  inline
  OpResult width(Self self, VM vm, size_t& result);

  inline
  OpResult arityList(Self self, VM vm, UnstableNode& result);

  inline
  OpResult clone(Self self, VM vm, UnstableNode& result);

  inline
  OpResult waitOr(Self self, VM vm, UnstableNode& result);

public:
  // VirtualString inteface
  inline
  OpResult isVirtualString(Self self, VM vm, bool& result);

  inline
  OpResult toString(Self self, VM vm, std::basic_ostream<nchar>& sink);

  inline
  OpResult vsLength(Self self, VM vm, nativeint& result);

  inline
  OpResult vsChangeSign(Self self, VM vm,
                        RichNode replacement, UnstableNode& result);

public:
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

public:
  inline
  bool internalGetConsStuff(StableNode*& head, StableNode*& tail,
                            LString<nchar>& endStr);

private:
  // Resolve the intermediate status of cons/string. Returns whether it is a
  // string.
  inline OpResult resolveIsString(Self cons, VM vm);

  // Here we abuse the length/error field of the _string. Since a string must
  // not be empty or have error, we can assign some additional meanings to it.
  // For now,
  //   error    = this is an improper list or not a list of chars
  //   zero     = unknown
  //   positive = this is a string (_head/_tail may be invalid in this state)
  // In particular, !isString() ≠ isCons().
  inline bool isString() const { return !_string.isErrorOrEmpty(); }
  inline bool isCons() const { return _string.isError(); }
  inline bool isIntermediate() const { return _string.length == 0; }

  // Note: although _head/_tail and _string are mutually exclusive, there might
  //       be cases where the stable nodes are refered by others. Thus, all 3
  //       fields will exist together.
  StableNode _head;
  StableNode _tail;
  LString<nchar> _string;
};

#ifndef MOZART_GENERATOR
#include "Cons-implem-decl-after.hh"
#endif

}

#endif

