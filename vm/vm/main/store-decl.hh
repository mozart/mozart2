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
  friend class TypeInfoOf;

  Node() {}

  template<class T, class... Args>
  void make(VM vm, Args&&... args) {
    Accessor<T>::init(data.type, data.value, vm, std::forward<Args>(args)...);
  }

  Type type() {
    return data.type;
  }

  template <typename T>
  __attribute__((always_inline))
  auto access() -> decltype(Accessor<T>::get(std::declval<MemWord>())) {
    return Accessor<T>::get(data.value);
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

  template <typename T>
  void become(VM vm, T&& value) {
    assert((type().getStructuralBehavior() == sbTokenEq) ||
           (type().getStructuralBehavior() == sbVariable));
    reinit(vm, std::forward<T>(value));
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
  friend class TypedRichNode;

  template <typename T>
  friend class TypeInfoOf;

  friend class GarbageCollector;
  friend class SpaceCloner;
  friend struct StructuralDualWalk;

  inline void reinit(VM vm, StableNode& from);
  inline void reinit(VM vm, UnstableNode& from);
  inline void reinit(VM vm, UnstableNode&& from);
  inline void reinit(VM vm, RichNode from);

  template <typename T>
  __attribute__((always_inline))
  auto access() -> decltype(std::declval<Node>().access<T>()) {
    return node()->access<T>();
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

  template <typename T>
  StableNode(VM vm, T&& from) {
    init(vm, std::forward<T>(from));
  }

  inline void init(VM vm, StableNode& from);
  inline void init(VM vm, UnstableNode& from);
  inline void init(VM vm, UnstableNode&& from);
  inline void init(VM vm, RichNode from);
  inline void init(VM vm);

  template <typename T>
  inline void init(VM vm, T&& from);
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

  template <typename T>
  UnstableNode(VM vm, T&& from) {
    init(vm, std::forward<T>(from));
  }

  inline void init(VM vm);

  template <typename T>
  void init(VM vm, T&& from) {
    copy(vm, std::forward<T>(from));
  }

  inline void copy(VM vm, StableNode& from);
  inline void copy(VM vm, UnstableNode& from);
  inline void copy(VM vm, UnstableNode&& from);
  inline void copy(VM vm, RichNode from);

  template <typename T>
  inline void copy(VM vm, T&& from);

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
 * Base class for specializations of TypedRichNode<T>
 */
class BaseTypedRichNode {
public:
  explicit BaseTypedRichNode(RichNode self) : _self(self) {}

  operator RichNode() {
    return _self;
  }
protected:
  RichNode _self;
};

/**
 * The returned value of 'vm->protect()', a node protected from GC.
 * This really is a std::shared_ptr<StableNode*>, but for convenience the
 * * and -> operators dereference twice to get at the StableNode&.
 * A ProtectedNode can be implictly converted back and forth to a genuine
 * std::shared_ptr<StableNode*>.
 */
class ProtectedNode {
public:
  ProtectedNode() {}
  ProtectedNode(std::nullptr_t): _node(nullptr) {}

  ProtectedNode(std::shared_ptr<StableNode*>&& from): _node(std::move(from)) {}
  ProtectedNode(const std::shared_ptr<StableNode*>& from): _node(from) {}

  operator std::shared_ptr<StableNode*>() const {
    return { _node };
  }

  StableNode& operator*() const {
    return **_node;
  }

  StableNode* operator->() const {
    return *_node;
  }

  explicit operator bool() const {
    return (bool) _node;
  }

  void reset() {
    _node.reset();
  }

private:
  std::shared_ptr<StableNode*> _node;
};

}

#endif // __STORE_DECL_H
