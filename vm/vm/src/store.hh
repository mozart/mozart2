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

#ifndef __STORE_H
#define __STORE_H

#include "memword.hh"
#include "type.hh"

class UnstableNode;
class Node;

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
  friend class UnstableNode;

  template<class T, class... Args>
  void make(VM vm, const Type* type, T value) {
    this->type = type;
    this->value.set(vm, value);
  }

  void reset(VM vm);

  union {
    // Regular structure of a node
    struct {
      const Type* type;
      MemWord value;
    };

    // Garbage collector hack
    struct {
      Node* gcNext;
      Node* gcFrom;
    };
  };
};

/**
 * Stable node, which is guaranteed never to change
 */
class StableNode {
public:
  void init(UnstableNode& from);
private:
  friend class UnstableNode;
public: // TODO make it private once the development has been bootstrapped
  Node node;
};

/**
 * Unstable node, which is allowed to change over time
 */
class UnstableNode {
public:
  void copy(VM vm, StableNode& from);
  void copy(VM vm, UnstableNode& from);
  void swap(UnstableNode& from);
  void reset(VM vm);

  template<class T, class... Args>
  void make(VM vm, const Type* type, T value) {
    node.make(vm, type, value);
  }
private:
  friend class StableNode;
public: // TODO make it private once the development has been bootstrapped
  Node node;
};

template<class H, class E>
class ArrayWithHeader{
  char* p;
public:
  H* operator->() { return static_cast<H*>(p); }
  E& operator[](size_t i) { return static_cast<E*>(p+sizeof(H))[i]; }
};

/**
 * Result of the call to a builtin.
 * It always represents a node that must be waited upon. The value 'nullptr' is
 * valid, and denotes that no value must be waited upon, i.e., the execution can
 * continue.
 * Throwing an exception is achieved by pointing to a failed value.
 */
typedef StableNode* BuiltinResult;

const BuiltinResult BuiltinResultContinue = nullptr;

#endif // __STORE_H
