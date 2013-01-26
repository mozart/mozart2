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
  T* getThis() {
    return static_cast<T*>(this);
  }

public:
  // Requirement for StoredWithArrayOf
  size_t getArraySizeImpl() {
    return getThis()->_width;
  }

public:
  size_t getWidth() {
    return getThis()->getArraySize();
  }

  inline
  StableNode* getElement(size_t index);

public:
  // RecordLike interface

  bool isRecord(VM vm) {
    return true;
  }

  inline
  size_t width(VM vm);

  inline
  UnstableNode arityList(VM vm);

  inline
  UnstableNode waitOr(VM vm);

protected:
  /* To be implemented in subclasses
  inline
  UnstableNode getFeatureAt(size_t index);
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
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("tuple"));
  }

  template <typename L>
  inline
  Tuple(VM vm, size_t width, L&& label);

  inline
  Tuple(VM vm, size_t width, GR gr, Tuple& from);

public:
  StableNode* getLabel() {
    return &_label;
  }

  inline
  bool equals(VM vm, RichNode right, WalkStack& stack);

protected:
  friend class IntegerDottableHelper<Tuple>;

  bool isValidFeature(VM vm, nativeint feature) {
    return (feature > 0) && ((size_t) feature <= _width);
  }

  inline
  UnstableNode getValueAt(VM vm, nativeint feature);

  inline
  UnstableNode getFeatureAt(VM vm, size_t index);

public:
  // RecordLike interface

  bool isTuple(VM vm) {
    return true;
  }

  inline
  UnstableNode label(VM vm);

  inline
  UnstableNode clone(VM vm);

  inline
  bool testRecord(VM vm, RichNode arity);

  inline
  bool testTuple(VM vm, RichNode label, size_t width);

  inline
  bool testLabel(VM vm, RichNode label);

public:
  inline
  void printReprToStream(VM vm, std::ostream& out, int depth, int width);

  inline
  bool hasSharpRepr(VM vm, int depth);

  inline
  UnstableNode serialize(VM vm, SE se);

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
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("tuple"));
  }

  template <typename Head, typename Tail,
            typename = typename std::enable_if<
              !std::is_convertible<Head, GR>::value, int>::type>
  inline
  Cons(VM vm, Head&& head, Tail&& tail);

  inline
  explicit Cons(VM vm);

  inline
  Cons(VM vm, GR gr, Cons& from);

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
  bool equals(VM vm, RichNode right, WalkStack& stack);

protected:
  friend class IntegerDottableHelper<Cons>;

  bool isValidFeature(VM vm, nativeint feature) {
    return (feature == 1) || (feature == 2);
  }

  inline
  UnstableNode getValueAt(VM vm, nativeint feature);

public:
  // RecordLike interface

  bool isRecord(VM vm) {
    return true;
  }

  bool isTuple(VM vm) {
    return true;
  }

  inline
  UnstableNode label(VM vm);

  inline
  size_t width(VM vm);

  inline
  UnstableNode arityList(VM vm);

  inline
  UnstableNode clone(VM vm);

  inline
  UnstableNode waitOr(VM vm);

  inline
  bool testRecord(VM vm, RichNode arity);

  inline
  bool testTuple(VM vm, RichNode label, size_t width);

  inline
  bool testLabel(VM vm, RichNode label);

public:
  inline
  void printReprToStream(VM vm, std::ostream& out, int depth, int width);

  inline
  bool hasListRepr(VM vm, int depth);

  inline
  UnstableNode serialize(VM vm, SE se);

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
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("arity"));
  }

  template <typename L>
  inline
  Arity(VM vm, size_t width, L&& label);

  inline
  Arity(VM vm, size_t width, GR gr, Arity& from);

public:
  // Requirement for StoredWithArrayOf
  size_t getArraySizeImpl() {
    return _width;
  }

public:
  StableNode* getLabel() {
    return &_label;
  }

  size_t getWidth() {
    return getArraySizeImpl();
  }

  inline
  StableNode* getElement(size_t index);

public:
  // StructuralEquatable interface

  inline
  bool equals(VM vm, RichNode right, WalkStack& stack);

public:
  // Arity methods

  inline
  bool lookupFeature(VM vm, RichNode feature, size_t& offset);

public:
  // Miscellaneous

  inline
  void printReprToStream(VM vm, std::ostream& out, int depth, int width);

  inline
  UnstableNode serialize(VM vm, SE se);

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
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("record"));
  }

  template <typename A>
  inline
  Record(VM vm, size_t width, A&& arity);

  inline
  Record(VM vm, size_t width, GR gr, Record& from);

public:
  StableNode* getArity() {
    return &_arity;
  }

  inline
  bool equals(VM vm, RichNode right, WalkStack& stack);

protected:
  inline
  UnstableNode getFeatureAt(VM vm, size_t index);

public:
  // Dottable interface

  inline
  bool lookupFeature(VM vm, RichNode feature,
                     nullable<UnstableNode&> value);

  inline
  bool lookupFeature(VM vm, nativeint feature,
                     nullable<UnstableNode&> value);

public:
  // RecordLike interface

  bool isTuple(VM vm) {
    return false;
  }

  inline
  UnstableNode label(VM vm);

  inline
  UnstableNode clone(VM vm);

  inline
  bool testRecord(VM vm, RichNode arity);

  inline
  bool testTuple(VM vm, RichNode label, size_t width);

  inline
  bool testLabel(VM vm, RichNode label);

public:
  inline
  void printReprToStream(VM vm, std::ostream& out, int depth, int width);

  inline
  UnstableNode serialize(VM vm, SE se);

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
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("chunk"));
  }

  explicit Chunk(StableNode* underlying): _underlying(underlying) {}

  static void create(StableNode*& self, VM vm, StableNode* underlying) {
    self = underlying;
  }

  static void create(StableNode*& self, VM vm, RichNode underlying) {
    self = underlying.getStableRef(vm);
  }

  inline
  static void create(StableNode*& self, VM vm, GR gr, Chunk from);

public:
  StableNode* getUnderlying() {
    return _underlying;
  }

public:
  // Dottable interface

  inline
  bool lookupFeature(VM vm, RichNode feature,
                     nullable<UnstableNode&> value);

  inline
  bool lookupFeature(VM vm, nativeint feature,
                     nullable<UnstableNode&> value);

public:
  // ChunkLike interface

  bool isChunk(VM vm) {
    return true;
  }

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth, int width) {
    out << "<Chunk>";
  }

  inline
  UnstableNode serialize(VM vm, SE se);

private:
  StableNode* _underlying;
};

#ifndef MOZART_GENERATOR
#include "Chunk-implem-decl-after.hh"
#endif

}

#endif // __RECORDS_DECL_H
