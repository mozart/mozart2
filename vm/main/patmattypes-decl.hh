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

#ifndef __PATMATTYPES_DECL_H
#define __PATMATTYPES_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

///////////////////
// PatMatCapture //
///////////////////

class PatMatCapture;

#ifndef MOZART_GENERATOR
#include "PatMatCapture-implem-decl.hh"
#endif

/**
 * Placeholder for a capture in pattern matching
 */
template <>
class Implementation<PatMatCapture>: StoredAs<nativeint>,
  Copyable, WithValueBehavior {
public:
  typedef SelfType<PatMatCapture>::Self Self;
public:
  Implementation(nativeint index) : _index(index) {}

  static void build(nativeint& self, VM, nativeint index) {
    self = index;
  }

  inline
  static void build(nativeint& self, VM vm, GR gr, Self from);

public:
  nativeint index() const { return _index; }

  inline
  bool equals(VM vm, Self right);

public:
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  nativeint _index;
};

#ifndef MOZART_GENERATOR
#include "PatMatCapture-implem-decl-after.hh"
#endif

///////////////////////
// PatMatConjunction //
///////////////////////

class PatMatConjunction;

#ifndef MOZART_GENERATOR
#include "PatMatConjunction-implem-decl.hh"
#endif

/**
 * Conjunction of two patterns for pattern matching
 */
template <>
class Implementation<PatMatConjunction>:
  StoredWithArrayOf<StableNode>, WithStructuralBehavior {
public:
  typedef SelfType<PatMatConjunction>::Self Self;
public:
  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements);

  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements,
                 GR gr, Self from);

public:
  size_t getCount() {
    return _count;
  }

  size_t getArraySize() {
    return _count;
  }

  inline
  StableNode* getElement(Self self, size_t index);

  inline
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

public:
  // ArrayInitializer interface

  inline
  OpResult initElement(Self self, VM vm, size_t index, RichNode value);

public:
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  size_t _count;
};

#ifndef MOZART_GENERATOR
#include "PatMatConjunction-implem-decl-after.hh"
#endif

}

#endif // __PATMATTYPES_DECL_H
