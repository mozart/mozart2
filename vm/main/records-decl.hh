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

#ifndef __RECORDS_DECL_H
#define __RECORDS_DECL_H

#include "mozartcore-decl.hh"

#include "datatypeshelpers-decl.hh"

namespace mozart {

////////////////
// BaseRecord //
////////////////

template <class T>
class BaseRecord {
private:
  typedef typename SelfType<T>::Self Self;
public:
  size_t getWidth() {
    return static_cast<Implementation<T>*>(this)->_width;
  }

  size_t getArraySize() {
    return static_cast<Implementation<T>*>(this)->_width;
  }

  inline
  StableNode* getElement(Self self, size_t index);
public:
  OpResult isRecord(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult width(Self self, VM vm, size_t& result);

  inline
  OpResult arityList(Self self, VM vm, UnstableNode& result);

  inline
  OpResult initElement(Self self, VM vm, size_t index, RichNode value);

  inline
  OpResult waitOr(Self self, VM vm, UnstableNode& result);
protected:
  /* To be implemented in subclasses
  inline
  void getFeatureAt(Self self, size_t index, UnstableNode& result);
  */
};

///////////
// Tuple //
///////////

class Tuple;

#ifndef MOZART_GENERATOR
#include "Tuple-implem-decl.hh"
#endif

/**
 * Tuple (specialization of Record)
 */
template <>
class Implementation<Tuple>: public BaseRecord<Tuple>,
  public IntegerDottableHelper<Tuple>,
  StoredWithArrayOf<StableNode>, WithStructuralBehavior {
public:
  typedef SelfType<Tuple>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("tuple"));
  }

  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements,
                 RichNode label);

  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements,
                 GR gr, Self from);

public:
  StableNode* getLabel() {
    return &_label;
  }

  inline
  StaticArray<StableNode> getElementsArray(Self self);

  inline
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

protected:
  friend class IntegerDottableHelper<Tuple>;

  bool isValidFeature(Self self, VM vm, nativeint feature) {
    return (feature > 0) && ((size_t) feature <= _width);
  }

  inline
  void getValueAt(Self self, VM vm, nativeint feature, UnstableNode& result);

  inline
  void getFeatureAt(Self self, VM vm, size_t index, UnstableNode& result);

public:
  // RecordLike interface

  OpResult isTuple(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult label(Self self, VM vm, UnstableNode& result);

  inline
  OpResult clone(Self self, VM vm, UnstableNode& result);

  inline
  OpResult testRecord(Self self, VM vm, RichNode arity, bool& result);

  inline
  OpResult testTuple(Self self, VM vm, RichNode label, size_t width,
                     bool& result);

  inline
  OpResult testLabel(Self self, VM vm, RichNode label, bool& result);

public:
  // VirtualString inteface

  inline
  OpResult isVirtualString(Self self, VM vm, bool& result);

  inline
  OpResult toString(Self self, VM vm, std::basic_ostream<nchar>& sink);

  inline
  OpResult vsLength(Self self, VM vm, nativeint& result);

private:
  inline bool hasSharpLabel(VM vm);

public:
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  friend class BaseRecord<Tuple>;

  StableNode _label;
  size_t _width;
};

#ifndef MOZART_GENERATOR
#include "Tuple-implem-decl-after.hh"
#endif

//////////
// Cons //
//////////

class Cons;

#ifndef MOZART_GENERATOR
#include "Cons-implem-decl.hh"
#endif

/**
 * Cons (specialization of Tuple with label '|' and width 2)
 */
template <>
class Implementation<Cons>: public IntegerDottableHelper<Cons>,
  WithStructuralBehavior {
public:
  typedef SelfType<Cons>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("tuple"));
  }

  inline
  Implementation(VM vm, RichNode head, RichNode tail);

  inline
  Implementation(VM vm);

  inline
  Implementation(VM vm, GR gr, Self from);

public:
  StableNode* getHead() {
    return &_elements[0];
  }

  StableNode* getTail() {
    return &_elements[1];
  }

  StaticArray<StableNode> getElementsArray() {
    return { _elements, 2 };
  }

  inline
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

protected:
  friend class IntegerDottableHelper<Cons>;

  bool isValidFeature(Self self, VM vm, nativeint feature) {
    return (feature == 1) || (feature == 2);
  }

  inline
  void getValueAt(Self self, VM vm, nativeint feature, UnstableNode& result);

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

  inline
  OpResult testRecord(Self self, VM vm, RichNode arity, bool& result);

  inline
  OpResult testTuple(Self self, VM vm, RichNode label, size_t width,
                     bool& result);

  inline
  OpResult testLabel(Self self, VM vm, RichNode label, bool& result);

public:
  // VirtualString inteface

  inline
  OpResult isVirtualString(Self self, VM vm, bool& result);

  inline
  OpResult toString(Self self, VM vm, std::basic_ostream<nchar>& sink);

  inline
  OpResult vsLength(Self self, VM vm, nativeint& result);

public:
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  StableNode _elements[2];
};

#ifndef MOZART_GENERATOR
#include "Cons-implem-decl-after.hh"
#endif

///////////
// Arity //
///////////

class Arity;

#ifndef MOZART_GENERATOR
#include "Arity-implem-decl.hh"
#endif

/**
 * Arity (of a record)
 */
template <>
class Implementation<Arity>:
  StoredWithArrayOf<StableNode>, WithStructuralBehavior {
public:
  typedef SelfType<Arity>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("arity"));
  }

  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements,
                 RichNode label);

  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements,
                 GR gr, Self from);

public:
  StableNode* getLabel() {
    return &_label;
  }

  size_t getWidth() {
    return _width;
  }

  size_t getArraySize() {
    return _width;
  }

  inline
  StableNode* getElement(Self self, size_t index);

public:
  // StructuralEquatable interface

  inline
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

public:
  // ArrayInitializer interface

  inline
  OpResult initElement(Self self, VM vm, size_t index, RichNode value);

public:
  // Arity methods

  inline
  OpResult lookupFeature(Self self, VM vm, RichNode feature,
                         bool& found, size_t& result);

public:
  // Miscellaneous

  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  StableNode _label;
  size_t _width;
};

#ifndef MOZART_GENERATOR
#include "Arity-implem-decl-after.hh"
#endif

////////////
// Record //
////////////

class Record;

#ifndef MOZART_GENERATOR
#include "Record-implem-decl.hh"
#endif

/**
 * Record
 */
template <>
class Implementation<Record>: public BaseRecord<Record>,
  StoredWithArrayOf<StableNode>, WithStructuralBehavior {
public:
  typedef SelfType<Record>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("record"));
  }

  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements,
                 RichNode arity);

  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements,
                 GR gr, Self from);

public:
  StableNode* getArity() {
    return &_arity;
  }

  inline
  StaticArray<StableNode> getElementsArray(Self self);

  inline
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

protected:
  inline
  void getFeatureAt(Self self, VM vm, size_t index, UnstableNode& result);

public:
  // Dottable interface

  inline
  OpResult lookupFeature(Self self, VM vm, RichNode feature,
                         bool& found, nullable<UnstableNode&> value);

  inline
  OpResult lookupFeature(Self self, VM vm, nativeint feature,
                         bool& found, nullable<UnstableNode&> value);

public:
  // RecordLike interface

  OpResult isTuple(Self self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  inline
  OpResult label(Self self, VM vm, UnstableNode& result);

  inline
  OpResult clone(Self self, VM vm, UnstableNode& result);

  inline
  OpResult testRecord(Self self, VM vm, RichNode arity, bool& result);

  inline
  OpResult testTuple(Self self, VM vm, RichNode label, size_t width,
                     bool& result);

  inline
  OpResult testLabel(Self self, VM vm, RichNode label, bool& result);

public:
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  friend class BaseRecord<Record>;

  StableNode _arity;
  size_t _width;
};

#ifndef MOZART_GENERATOR
#include "Record-implem-decl-after.hh"
#endif

///////////
// Chunk //
///////////

class Chunk;

#ifndef MOZART_GENERATOR
#include "Chunk-implem-decl.hh"
#endif

template <>
class Implementation<Chunk>: StoredAs<StableNode*> {
public:
  typedef SelfType<Chunk>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("chunk"));
  }

  Implementation(StableNode* underlying): _underlying(underlying) {}

  static void build(StableNode*& self, VM vm, StableNode* underlying) {
    self = underlying;
  }

  static void build(StableNode*& self, VM vm, RichNode underlying) {
    self = underlying.getStableRef(vm);
  }

  inline
  static void build(StableNode*& self, VM vm, GR gr, Self from);

public:
  StableNode* getUnderlying() {
    return _underlying;
  }

public:
  // Dottable interface

  inline
  OpResult lookupFeature(Self self, VM vm, RichNode feature,
                         bool& found, nullable<UnstableNode&> value);

  inline
  OpResult lookupFeature(Self self, VM vm, nativeint feature,
                         bool& found, nullable<UnstableNode&> value);

public:
  // ChunkLike interface

  OpResult isChunk(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

public:
  // Miscellaneous

  void printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
    out << "<Chunk>";
  }

private:
  StableNode* _underlying;
};

#ifndef MOZART_GENERATOR
#include "Chunk-implem-decl-after.hh"
#endif

}

#endif // __RECORDS_DECL_H
