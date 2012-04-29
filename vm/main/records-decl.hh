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

namespace mozart {

////////////////
// BaseRecord //
////////////////

template <class T>
class BaseRecord {
private:
  typedef typename SelfType<T>::Self Self;
public:
  nativeint getWidth() {
    return static_cast<Implementation<T>*>(this)->_width;
  }

  size_t getArraySize() {
    return static_cast<Implementation<T>*>(this)->_width;
  }

  inline
  StableNode* getElement(Self self, size_t index);
public:
  inline
  OpResult width(Self self, VM vm, UnstableNode& result);

  inline
  OpResult initElement(Self self, VM vm, size_t index, RichNode value);

  inline
  OpResult waitOr(Self self, VM vm, UnstableNode& result);
protected:
  /* To be implemented in subclasses
  inline
  void getFeatureAt(Self self, size_t index);
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
  StoredWithArrayOf<StableNode>, WithStructuralBehavior {
public:
  typedef SelfType<Tuple>::Self Self;
public:
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
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

protected:
  inline
  void getFeatureAt(Self self, VM vm, size_t index, UnstableNode& result);

public:
  // RecordLike interface

  inline
  OpResult label(Self self, VM vm, UnstableNode& result);

  inline
  OpResult dot(Self self, VM vm, RichNode feature, UnstableNode& result);

  inline
  OpResult dotNumber(Self self, VM vm, nativeint feature, UnstableNode& result);

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
class Implementation<Cons>: WithStructuralBehavior {
public:
  typedef SelfType<Cons>::Self Self;
public:
  inline
  Implementation(VM vm, RichNode head, RichNode tail);

  inline
  Implementation(VM vm, GR gr, Self from);

public:
  StableNode* getHead() {
    return &_head;
  }

  StableNode* getTail() {
    return &_tail;
  }

  inline
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

public:
  // RecordLike interface

  inline
  OpResult label(Self self, VM vm, UnstableNode& result);

  inline
  OpResult width(Self self, VM vm, UnstableNode& result);

  inline
  OpResult dot(Self self, VM vm, RichNode feature, UnstableNode& result);

  inline
  OpResult dotNumber(Self self, VM vm, nativeint feature, UnstableNode& result);

  inline
  OpResult waitOr(Self self, VM vm, UnstableNode& result);

public:
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  StableNode _head;
  StableNode _tail;
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
class Implementation<Arity>: WithStructuralBehavior {
public:
  typedef SelfType<Arity>::Self Self;
public:
  inline
  Implementation(VM vm, RichNode tuple);

  inline
  Implementation(VM vm, GR gr, Self from);

public:
  StableNode* getTuple() {
    return &_tuple;
  }

public:
  inline
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

public:
  inline
  OpResult label(Self self, VM vm, UnstableNode& result);

  inline
  OpResult lookupFeature(VM vm, RichNode record, RichNode feature,
                         size_t& result);

  inline
  void getFeatureAt(Self self, VM vm, size_t index, UnstableNode& result);

public:
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  StableNode _tuple;
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
  bool equals(Self self, VM vm, Self right, WalkStack& stack);

protected:
  inline
  void getFeatureAt(Self self, VM vm, size_t index, UnstableNode& result);

public:
  // RecordLike interface

  inline
  OpResult label(Self self, VM vm, UnstableNode& result);

  inline
  OpResult dot(Self self, VM vm, RichNode feature, UnstableNode& result);

  inline
  OpResult dotNumber(Self self, VM vm, nativeint feature, UnstableNode& result);

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

}

#endif // __RECORDS_DECL_H
