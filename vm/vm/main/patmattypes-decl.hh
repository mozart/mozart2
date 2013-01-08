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

#ifndef MOZART_GENERATOR
#include "PatMatCapture-implem-decl.hh"
#endif

/**
 * Placeholder for a capture in pattern matching
 */
class PatMatCapture: public DataType<PatMatCapture>, StoredAs<nativeint>,
  WithValueBehavior {
public:
  explicit PatMatCapture(nativeint index) : _index(index) {}

  static void create(nativeint& self, VM, nativeint index) {
    self = index;
  }

  inline
  static void create(nativeint& self, VM vm, GR gr, PatMatCapture from);

public:
  nativeint index() const { return _index; }

  inline
  bool equals(VM vm, RichNode right);

public:
  inline
  void printReprToStream(VM vm, std::ostream& out, int depth);

  inline
  UnstableNode serialize(VM vm, SE se);

private:
  nativeint _index;
};

#ifndef MOZART_GENERATOR
#include "PatMatCapture-implem-decl-after.hh"
#endif

///////////////////////
// PatMatConjunction //
///////////////////////

#ifndef MOZART_GENERATOR
#include "PatMatConjunction-implem-decl.hh"
#endif

/**
 * Conjunction of two patterns for pattern matching
 */
class PatMatConjunction: public DataType<PatMatConjunction>,
  StoredWithArrayOf<StableNode>, WithStructuralBehavior {
public:
  inline
  PatMatConjunction(VM vm, size_t width);

  inline
  PatMatConjunction(VM vm, size_t width, GR gr, PatMatConjunction& from);

public:
  // Requirement for StoredWithArrayOf
  size_t getArraySizeImpl() {
    return _count;
  }

public:
  size_t getCount() {
    return _count;
  }

  inline
  StableNode* getElement(size_t index);

  inline
  bool equals(VM vm, RichNode right, WalkStack& stack);

public:
  inline
  void printReprToStream(VM vm, std::ostream& out, int depth);

  inline
  UnstableNode serialize(VM vm, SE se);

private:
  size_t _count;
};

#ifndef MOZART_GENERATOR
#include "PatMatConjunction-implem-decl-after.hh"
#endif

//////////////////////
// PatMatOpenRecord //
//////////////////////

#ifndef MOZART_GENERATOR
#include "PatMatOpenRecord-implem-decl.hh"
#endif

/**
 * Open record in pattern matching
 * label(f1:P1 f2:P2 ...)
 */
class PatMatOpenRecord: public DataType<PatMatOpenRecord>,
  StoredWithArrayOf<StableNode> {
public:
  template <typename A>
  inline
  PatMatOpenRecord(VM vm, size_t width, A&& arity);

  inline
  PatMatOpenRecord(VM vm, size_t width, GR gr, PatMatOpenRecord& from);

public:
  // Requirement for StoredWithArrayOf
  size_t getArraySizeImpl() {
    return _width;
  }

public:
  inline
  StableNode* getElement(size_t index);

public:
  StableNode* getArity() {
    return &_arity;
  }

public:
  inline
  void printReprToStream(VM vm, std::ostream& out, int depth);

  inline
  UnstableNode serialize(VM vm, SE se);

private:
  StableNode _arity;
  size_t _width;
};

#ifndef MOZART_GENERATOR
#include "PatMatOpenRecord-implem-decl-after.hh"
#endif

}

#endif // __PATMATTYPES_DECL_H
