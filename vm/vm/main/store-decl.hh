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

#ifndef __STORE_DECL_H
#define __STORE_DECL_H

#include "core-forward-decl.hh"
#include "type-decl.hh"
#include "memword.hh"
#include "storage-decl.hh"

#include <string>

namespace mozart {

/**
 * A value node in the store.
 * The store is entirely made of nodes. A node is basically a typed value.
 * Non-atomic values, such as records, contain references to other nodes in the
 * store, hence forming a graph, and the name "node".
 * There are two kinds of node: stable and unstable node. A stable node is
 * guaranteed never to change, whereas unstable node can change. In order to
 * maintain consistency in the store, non-atomic values are only allowed to
 * reference stable nodes. Unstable nodes are used for working data, and
 * inherently mutable data (such as the contents of a cell).
 */
class Node {
private:
  friend struct NodeBackup;
  friend struct NodeHole;
  friend class StableNode;
  friend class UnstableNode;
  friend class RichNode;
  friend class GraphReplicator;
  friend class Space;

  template <class T>
  friend class BaseSelf;

  template <class T>
  friend class WritableSelfType;

  template <class T>
  friend class TypeInfoOf;

  Node() {}

  template<class T, class... Args>
  void make(VM vm, Args&&... args) {
    Accessor<T>::init(data.type, data.value, vm, std::forward<Args>(args)...);
  }

  Type type() {
    return data.type;
  }

  MemWord value() {
    return data.value;
  }

  bool isCopyable() {
    return type().isCopyable();
  }

  inline
  StableNode* asStable();

  inline
  UnstableNode* asUnstable();

  void set(const Node& from) {
    data.type = from.data.type;
    data.value = from.data.value;
  }

  union {
    // Regular structure
    struct {
      Type type;
      MemWord value;
    } data;

    // Graph replicator hack
    struct {
      Node* grNext;
      Node* grFrom;
    };
  };
};

struct NodeBackup {
public:
  void restore() {
    *node = saved;
  }
private:
  friend class StableNode;
  friend class UnstableNode;
  friend class RichNode;

  NodeBackup(Node* node) : node(node), saved(*node) {}
private:
  Node* node;
  Node saved;
};

struct NodeHole {
public:
  NodeHole() {}

  inline
  NodeHole(StableNode* node);

  inline
  NodeHole(UnstableNode* node);
public:
  inline
  void fill(VM vm, UnstableNode&& value);
public:
  inline
  bool operator==(StableNode* rhs);

  inline
  bool operator==(UnstableNode* rhs);
private:
  friend class RichNode;

  Node* node() {
    return _node;
  }

  bool isStable() {
    return _isStable;
  }
private:
  Node* _node;
  bool _isStable;
};

template <class T>
class TypedRichNode {
};

/**
 * A rich node provides read access to nodes, with transparent dereferencing.
 */
class RichNode {
public:
  RichNode() {}

  __attribute__((always_inline))
  inline
  RichNode(StableNode& origin);

  __attribute__((always_inline))
  inline
  RichNode(UnstableNode& origin);

  __attribute__((always_inline))
  inline
  RichNode(NodeHole origin);

  __attribute__((always_inline))
  RichNode(std::nullptr_t): _node(nullptr), _isStable(false) {}

  __attribute__((always_inline))
  Type type() {
    return node()->type();
  }

  __attribute__((always_inline))
  inline
  bool isTransient();

  __attribute__((always_inline))
  inline
  bool isFeature();

  template <class T>
  __attribute__((always_inline))
  bool is() {
    return type() == T::type();
  }

  template <class T>
  __attribute__((always_inline))
  TypedRichNode<T> as() {
    assert(is<T>());
    return TypedRichNode<T>(*this);
  }

  __attribute__((always_inline))
  inline
  StableNode* getStableRef(VM vm);

  inline
  void update();

  inline
  void ensureStable(VM vm);

  NodeBackup makeBackup() {
    return NodeBackup(node());
  }

  bool isSameNode(RichNode right) {
    return node() == right.node();
  }

  inline
  std::string toDebugString();
private:
  __attribute__((always_inline))
  inline
  static StableNode* dereference(Node* node);

  __attribute__((noinline))
  inline
  static StableNode* dereferenceLoop(StableNode* node);

  __attribute__((always_inline))
  inline
  static StableNode* destOf(Node* node);
private:
  template <class T>
  friend class BaseSelf;

  friend class GarbageCollector;
  friend class SpaceCloner;
  friend struct StructuralDualWalk;

  inline void reinit(VM vm, StableNode& from);
  inline void reinit(VM vm, UnstableNode& from);
  inline void reinit(VM vm, UnstableNode&& from);
  inline void reinit(VM vm, RichNode from);

  __attribute__((always_inline))
  MemWord value() {
    return node()->value();
  }
private:
  friend class StableNode;
  friend class UnstableNode;

  __attribute__((always_inline))
  Node* node() {
    return _node;
  }

  __attribute__((always_inline))
  bool isStable() {
    return _isStable;
  }

  __attribute__((always_inline))
  StableNode& asStable() {
    return *node()->asStable();
  }

  __attribute__((always_inline))
  UnstableNode& asUnstable() {
    return *node()->asUnstable();
  }
private:
  Node* _node;
  bool _isStable;
};

/**
 * Stable node, which is guaranteed never to change
 */
class StableNode: public Node {
public:
  StableNode() {}

  inline void init(VM vm, StableNode& from);
  inline void init(VM vm, UnstableNode& from);
  inline void init(VM vm, UnstableNode&& from);
  inline void init(VM vm, RichNode from);
  inline void init(VM vm);
public:
  // Make this class non-copyable and non-movable
  StableNode(const StableNode& from) = delete;
  StableNode& operator=(const StableNode& from) = delete;

  StableNode(StableNode&& from) = delete;
  StableNode& operator=(StableNode&& from) = delete;
};

/**
 * Unstable node, which is allowed to change over time
 */
class UnstableNode: public Node {
public:
  UnstableNode() {}

  UnstableNode(VM vm, StableNode& from) {
    copy(vm, from);
  }

  UnstableNode(VM vm, UnstableNode& from) {
    copy(vm, from);
  }

  UnstableNode(VM vm, RichNode from) {
    copy(vm, from);
  }

  inline void init(VM vm, StableNode& from);
  inline void init(VM vm, UnstableNode& from);
  inline void init(VM vm, UnstableNode&& from);
  inline void init(VM vm, RichNode from);
  inline void init(VM vm);

  inline void copy(VM vm, StableNode& from);
  inline void copy(VM vm, UnstableNode& from);
  inline void copy(VM vm, UnstableNode&& from);
  inline void copy(VM vm, RichNode from);

  template<class T, class... Args>
  static UnstableNode build(VM vm, Args&&... args) {
    UnstableNode result;
    result.make<T>(vm, std::forward<Args>(args)...);
    return result;
  }
public:
  // Make this class non-copyable
  UnstableNode(const UnstableNode& from) = delete;
  UnstableNode& operator=(const UnstableNode& from) = delete;

  // But make it movable
  UnstableNode(UnstableNode&& from) = default;
  UnstableNode& operator=(UnstableNode&& from) = default;
};

/**
 * Base class for Self types
 */
template <class T>
class BaseSelf {
public:
  BaseSelf(RichNode node) : _node(node) {}

  template<class U>
  void become(VM vm, U&& from) {
    _node.reinit(vm, std::forward<U>(from));
  }

  operator RichNode() {
    return _node;
  }
protected:
  auto getBase() -> decltype(Accessor<T>::get(std::declval<MemWord>())) {
    return Accessor<T>::get(_node.value());
  }
private:
  RichNode _node;
};

/**
 * Self type for custom storage-based types
 */
template <class T>
class CustomStorageSelf: public BaseSelf<T> {
public:
  CustomStorageSelf(RichNode node) : BaseSelf<T>(node) {}

  T get() {
    return this->getBase();
  }
};

/**
 * Self type for default storage-based types
 */
template <class T>
class DefaultStorageSelf: public BaseSelf<T> {
public:
  DefaultStorageSelf(RichNode node) : BaseSelf<T>(node) {}

  T* operator->() {
    return &this->getBase();
  }
};

/**
 * Extractor function for the template parameters of ImplWithArray
 * Given
 *   typedef ImplWithArray<I, E> T;
 * this provides
 *   ExtractImplWithArray<T>::Impl === I
 *   ExtractImplWithArray<T>::Elem === E
 */
template <class S>
struct ExtractImplWithArray {};

template <class I, class E>
struct ExtractImplWithArray<ImplWithArray<I, E>> {
  typedef I Impl;
  typedef E Elem;
};

/**
 * Self type for ImplWithArray-based types
 */
template <class T>
class ImplWithArraySelf: public BaseSelf<T> {
private:
  typedef typename Storage<T>::Type StorageType;
  typedef typename ExtractImplWithArray<StorageType>::Elem Elem;
public:
  ImplWithArraySelf(RichNode node) : BaseSelf<T>(node) {}

  T* operator->() {
    return get().operator->();
  }

  Elem& operator[](size_t i) {
    return get().operator[](i);
  }

  size_t getArraySize() {
    return get()->getArraySize();
  }

  StaticArray<Elem> getArray() {
    return get().getArray(getArraySize());
  }
private:
  ImplWithArray<T, Elem> get() {
    return ImplWithArray<T, Elem>(&this->getBase());
  }
};

/**
 * Helper for the metafunction SelfType
 */
template <class T, class S>
struct SelfTypeInner {
  typedef CustomStorageSelf<T> Self;
};

/**
 * Helper for the metafunction SelfType
 */
template <class T>
struct SelfTypeInner<T, DefaultStorage<T>> {
  typedef DefaultStorageSelf<T> Self;
};

/**
 * Helper for the metafunction SelfType
 */
template <class T, class I, class E>
struct SelfTypeInner<T, ImplWithArray<I, E>> {
  typedef ImplWithArraySelf<T> Self;
};

/**
 * Metafunction from type to its Self type
 * Use as SelfType<T>::Self
 */
template <class T>
struct SelfType {
  typedef typename SelfTypeInner<T, typename Storage<T>::Type>::Self Self;
};

/**
 * Base class for specializations of TypedRichNode<T>
 */
template <class T>
class BaseTypedRichNode {
protected:
  typedef typename SelfType<T>::Self Self;
public:
  BaseTypedRichNode(Self self) : _self(self) {}

  operator RichNode() {
    return _self;
  }
protected:
  Self _self;
};

}

#endif // __STORE_DECL_H
