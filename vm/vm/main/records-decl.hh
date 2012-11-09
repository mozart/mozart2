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
    return static_cast<T*>(this)->_width;
  }

  size_t getArraySize() {
    return static_cast<T*>(this)->_width;
  }

  inline
  StableNode* getElement(Self self, size_t index);
public:
  bool isRecord(Self self, VM vm) {
    return true;
  }

  inline
  size_t width(Self self, VM vm);

  inline
  UnstableNode arityList(Self self, VM vm);

  inline
  UnstableNode waitOr(Self self, VM vm);
protected:
  /* To be implemented in subclasses
  inline
  UnstableNode getFeatureAt(Self self, size_t index);
  */
};

///////////
// Tuple //
///////////

#ifndef MOZART_GENERATOR
#include "Tuple-implem-decl.hh"
#endif

/**
 * Tuple (specialization of Record)
 */
class Tuple: public DataType<Tuple>, public BaseRecord<Tuple>,
  public IntegerDottableHelper<Tuple>,
  StoredWithArrayOf<StableNode>, WithStructuralBehavior {
public:
  typedef SelfType<Tuple>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("tuple"));
  }

  template <typename L>
  inline
  Tuple(VM vm, size_t width, StaticArray<StableNode> _elements, L&& label);

  inline
  Tuple(VM vm, size_t width, StaticArray<StableNode> _elements,
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
  UnstableNode getValueAt(Self self, VM vm, nativeint feature);

  inline
  UnstableNode getFeatureAt(Self self, VM vm, size_t index);

public:
  // RecordLike interface

  bool isTuple(Self self, VM vm) {
    return true;
  }

  inline
  UnstableNode label(Self self, VM vm);

  inline
  UnstableNode clone(Self self, VM vm);

  inline
  bool testRecord(Self self, VM vm, RichNode arity);

  inline
  bool testTuple(Self self, VM vm, RichNode label, size_t width);

  inline
  bool testLabel(Self self, VM vm, RichNode label);

public:
  // VirtualString inteface

  inline
  bool isVirtualString(Self self, VM vm);

  inline
  void toString(Self self, VM vm, std::basic_ostream<nchar>& sink);

  inline
  nativeint vsLength(Self self, VM vm);

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

#ifndef MOZART_GENERATOR
#include "Cons-implem-decl.hh"
#endif

/**
 * Cons (specialization of Tuple with label '|' and width 2)
 */
class Cons: public DataType<Cons>, public IntegerDottableHelper<Cons>,
  WithStructuralBehavior {
public:
  typedef SelfType<Cons>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("tuple"));
  }

  template <typename Head, typename Tail,
            typename = typename std::enable_if<
              !std::is_convertible<Head, GR>::value, int>::type>
  inline
  Cons(VM vm, Head&& head, Tail&& tail);

  inline
  Cons(VM vm);

  inline
  Cons(VM vm, GR gr, Self from);

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
  UnstableNode getValueAt(Self self, VM vm, nativeint feature);

public:
  // RecordLike interface

  bool isRecord(Self self, VM vm) {
    return true;
  }

  bool isTuple(Self self, VM vm) {
    return true;
  }

  inline
  UnstableNode label(Self self, VM vm);

  inline
  size_t width(Self self, VM vm);

  inline
  UnstableNode arityList(Self self, VM vm);

  inline
  UnstableNode clone(Self self, VM vm);

  inline
  UnstableNode waitOr(Self self, VM vm);

  inline
  bool testRecord(Self self, VM vm, RichNode arity);

  inline
  bool testTuple(Self self, VM vm, RichNode label, size_t width);

  inline
  bool testLabel(Self self, VM vm, RichNode label);

public:
  // VirtualString inteface

  inline
  bool isVirtualString(Self self, VM vm);

  inline
  void toString(Self self, VM vm, std::basic_ostream<nchar>& sink);

  inline
  nativeint vsLength(Self self, VM vm);

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

#ifndef MOZART_GENERATOR
#include "Arity-implem-decl.hh"
#endif

/**
 * Arity (of a record)
 */
class Arity: public DataType<Arity>,
  StoredWithArrayOf<StableNode>, WithStructuralBehavior {
public:
  typedef SelfType<Arity>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("arity"));
  }

  template <typename L>
  inline
  Arity(VM vm, size_t width, StaticArray<StableNode> _elements, L&& label);

  inline
  Arity(VM vm, size_t width, StaticArray<StableNode> _elements,
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

  inline
  StaticArray<StableNode> getElementsArray(Self self);

public:
  // StructuralEquatable interface

  inline
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

public:
  // Arity methods

  inline
  bool lookupFeature(Self self, VM vm, RichNode feature, size_t& offset);

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

#ifndef MOZART_GENERATOR
#include "Record-implem-decl.hh"
#endif

/**
 * Record
 */
class Record: public DataType<Record>, public BaseRecord<Record>,
  StoredWithArrayOf<StableNode>, WithStructuralBehavior {
public:
  typedef SelfType<Record>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("record"));
  }

  template <typename A>
  inline
  Record(VM vm, size_t width, StaticArray<StableNode> _elements, A&& arity);

  inline
  Record(VM vm, size_t width, StaticArray<StableNode> _elements,
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
  UnstableNode getFeatureAt(Self self, VM vm, size_t index);

public:
  // Dottable interface

  inline
  bool lookupFeature(Self self, VM vm, RichNode feature,
                     nullable<UnstableNode&> value);

  inline
  bool lookupFeature(Self self, VM vm, nativeint feature,
                     nullable<UnstableNode&> value);

public:
  // RecordLike interface

  bool isTuple(Self self, VM vm) {
    return false;
  }

  inline
  UnstableNode label(Self self, VM vm);

  inline
  UnstableNode clone(Self self, VM vm);

  inline
  bool testRecord(Self self, VM vm, RichNode arity);

  inline
  bool testTuple(Self self, VM vm, RichNode label, size_t width);

  inline
  bool testLabel(Self self, VM vm, RichNode label);

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

#ifndef MOZART_GENERATOR
#include "Chunk-implem-decl.hh"
#endif

class Chunk: public DataType<Chunk>, StoredAs<StableNode*> {
public:
  typedef SelfType<Chunk>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("chunk"));
  }

  Chunk(StableNode* underlying): _underlying(underlying) {}

  static void create(StableNode*& self, VM vm, StableNode* underlying) {
    self = underlying;
  }

  static void create(StableNode*& self, VM vm, RichNode underlying) {
    self = underlying.getStableRef(vm);
  }

  inline
  static void create(StableNode*& self, VM vm, GR gr, Self from);

public:
  StableNode* getUnderlying() {
    return _underlying;
  }

public:
  // Dottable interface

  inline
  bool lookupFeature(Self self, VM vm, RichNode feature,
                     nullable<UnstableNode&> value);

  inline
  bool lookupFeature(Self self, VM vm, nativeint feature,
                     nullable<UnstableNode&> value);

public:
  // ChunkLike interface

  bool isChunk(Self self, VM vm) {
    return true;
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
