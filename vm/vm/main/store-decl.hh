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
#include "memword.hh"
#include "storage.hh"

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
  friend class StableNode;
  friend class UnstableNode;
  friend class RichNode;

  template <class T>
  friend class BaseSelf;

  template <class T>
  friend class WritableSelfType;

  template<class T, class... Args>
  void make(VM vm, Args&&... args) {
    typedef Accessor<T, typename Storage<T>::Type> Access;
    Access::init(type, value, vm, std::forward<Args>(args)...);
  }

  const Type* type;
  MemWord value;
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

template <class T>
class TypedRichNode {
};

/**
 * A rich node is a node with an accompanying unstable origin
 * The important invariant of this class is that following a chain of
 * references starting at the origin eventually reaches the node.
 */
class RichNode {
private:
  RichNode(Node* node, UnstableNode& origin) : _node(node), _origin(&origin) {}
public:
  __attribute__((always_inline))
  inline
  RichNode(UnstableNode& origin);

  const Type* type() {
    return _node->type;
  }

  inline
  bool isTransient();

  inline
  bool isFeature();

  UnstableNode& origin() {
    return *_origin;
  }

  template <class T>
  bool is() {
    return type() == T::type();
  }

  template <class T>
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

  inline void reinit(VM vm, StableNode& from);
  inline void reinit(VM vm, UnstableNode& from);
  inline void reinit(VM vm, RichNode from);

  template<class T, class... Args>
  void remake(VM vm, Args&&... args) {
    _node->make<T>(vm, std::forward<Args>(args)...);
  }

  NodeBackup makeBackup() {
    return NodeBackup(_node);
  }

  bool isSameNode(RichNode right) {
    return _node == right._node;
  }

  inline
  std::string toDebugString();
private:
  inline
  static Node* dereference(Node* node);

  __attribute__((noinline))
  inline
  static Node* dereferenceLoop(Node* node);

  inline
  static StableNode* getStableRefFor(VM vm, UnstableNode& node);

  __attribute__((noinline))
  inline
  static StableNode* getStableRefForLoop(StableNode* node);

  inline
  static StableNode* destOf(Node* node);
private:
  template <class T>
  friend class BaseSelf;

  MemWord value() {
    return _node->value;
  }
private:
  Node* _node;
  UnstableNode* _origin;
};

/**
 * Stable node, which is guaranteed never to change
 */
class StableNode {
public:
  StableNode() {}

  inline void init(VM vm, StableNode& from);
  inline void init(VM vm, UnstableNode& from);
  inline void init(VM vm, RichNode from);

  template<class T, class... Args>
  void make(VM vm, Args&&... args) {
    node.make<T>(vm, std::forward<Args>(args)...);
  }

  NodeBackup makeBackup() {
    return NodeBackup(&node);
  }
public:
  // Make this class non-copyable and non-movable
  StableNode(const StableNode& from) = delete;
  StableNode& operator=(const StableNode& from) = delete;

  StableNode(StableNode&& from) = delete;
  StableNode& operator=(StableNode&& from) = delete;
private:
  friend struct NodeBackup;
  friend class UnstableNode;
  friend class RichNode;
  friend class GraphReplicator;
  friend class Space;

  inline
  bool isCopiable();

  union {
    Node node;

    // Graph replicator hack
    struct {
      StableNode* grNext;
      StableNode* grFrom;
    };
  };
};

/**
 * Unstable node, which is allowed to change over time
 */
class UnstableNode {
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
  inline void init(VM vm, RichNode from);

  inline void copy(VM vm, StableNode& from);
  inline void copy(VM vm, UnstableNode& from);
  inline void copy(VM vm, RichNode from);

  inline void swap(UnstableNode& from);
  inline void reset(VM vm);

  template<class T, class... Args>
  void make(VM vm, Args&&... args) {
    node.make<T>(vm, std::forward<Args>(args)...);
  }

  template<class T, class... Args>
  static UnstableNode build(VM vm, Args&&... args) {
    UnstableNode result;
    result.make<T>(vm, std::forward<Args>(args)...);
    return result;
  }

  NodeBackup makeBackup() {
    return NodeBackup(&node);
  }
public:
  // Make this class non-copyable
  UnstableNode(const UnstableNode& from) = delete;
  UnstableNode& operator=(const UnstableNode& from) = delete;

  // But make it movable

  UnstableNode(UnstableNode&& from) {
    node = from.node;
  }

  UnstableNode& operator=(UnstableNode&& from) {
    node = from.node;
    return *this;
  }
private:
  friend struct NodeBackup;
  friend class StableNode;
  friend class RichNode;
  friend class GraphReplicator;
  friend class Space;

  inline
  bool isCopiable();

  union {
    Node node;

    // Graph replicator hack
    struct {
      UnstableNode* grNext;
      UnstableNode* grFrom;
    };
  };
};

/**
 * Base class for Self types
 */
template <class T>
class BaseSelf {
protected:
  typedef typename Storage<T>::Type StorageType;
  typedef Accessor<T, StorageType> Access;
public:
  BaseSelf(RichNode node) : _node(node) {}

  template<class U, class... Args>
  void remake(VM vm, Args&&... args) {
    _node.remake<U>(vm, std::forward<Args>(args)...);
  }

  operator RichNode() {
    return _node;
  }
protected:
  auto getBase() -> decltype(Access::get(MemWord())) {
    return Access::get(_node.value());
  }
private:
  RichNode _node;
};

/**
 * Self type for custom storage-based types
 */
template <class T>
class CustomStorageSelf: public BaseSelf<T> {
private:
  typedef Implementation<T> Impl;
public:
  CustomStorageSelf(RichNode node) : BaseSelf<T>(node) {}

  Impl get() {
    return this->getBase();
  }
};

/**
 * Self type for default storage-based types
 */
template <class T>
class DefaultStorageSelf: public BaseSelf<T> {
private:
  typedef Implementation<T> Impl;
public:
  DefaultStorageSelf(RichNode node) : BaseSelf<T>(node) {}

  Impl* operator->() {
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
  typedef typename BaseSelf<T>::StorageType StorageType;
  typedef typename ExtractImplWithArray<StorageType>::Impl Impl;
  typedef typename ExtractImplWithArray<StorageType>::Elem Elem;
public:
  ImplWithArraySelf(RichNode node) : BaseSelf<T>(node) {}

  Impl* operator->() {
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
  ImplWithArray<Impl, Elem> get() {
    return ImplWithArray<Impl, Elem>(&this->getBase());
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
