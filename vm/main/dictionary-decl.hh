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

#ifndef __DICTIONARY_DECL_H
#define __DICTIONARY_DECL_H

#include "mozartcore-decl.hh"

#include <functional>

#include "datatypeshelpers-decl.hh"

namespace mozart {

////////////////////
// NodeDictionary //
////////////////////

class NodeDictionary {
private:
  enum Color { clBlack, clRed };

  struct Node {
    bool safeIsBlack() {
      return (this == nullptr) || (color == clBlack);
    }

    bool safeIsRed() {
      return (this != nullptr) && (color == clRed);
    }

    Node* getOneChild() {
      if (left == nullptr) {
        return right;
      } else {
        return left;
      }
    }

    Node* getTheOtherChild(Node* oneChild) {
      if (oneChild == left)
        return right;
      else
        return left;
    }

    Node* rightMost() {
      if (right == nullptr)
        return this;
      else
        return right->rightMost();
    }

    Node* parent;
    Node* left;
    Node* right;
    Color color;
    UnstableNode key;
    UnstableNode value;
  };

public:
  NodeDictionary(): root(nullptr) {}

  inline
  NodeDictionary(GR gr, NodeDictionary& src);

  bool empty() {
    return root == nullptr;
  }

  bool contains(VM vm, RichNode key) {
    UnstableNode* dummy;
    return lookup(vm, key, dummy);
  }

  inline
  bool lookup(VM vm, RichNode key, UnstableNode*& value);

  inline
  bool lookupOrCreate(VM vm, RichNode key, UnstableNode*& value);

  inline
  bool remove(VM vm, RichNode key);

  inline
  void removeAll(VM vm);

  template <class T>
  inline
  T foldRight(T init, std::function<T (UnstableNode&, UnstableNode&, T)> f);

  inline
  void clone(VM vm, NodeDictionary src);

private:
  inline
  bool lookupNode(VM vm, RichNode key, Node*& node, Node*& parent);

  inline
  void fixInsert(VM vm, Node* node);

  inline
  void removeNodeWithAtMostOneNonLeafChild(VM vm, Node* node, Node* parent);

  inline
  void replaceChild(VM vm, Node* parent, Node* child, Node* newChild);

  inline
  void fixRemove(VM vm, Node* node, Node* parent);

private:
  inline
  void replicate(VM vm, NodeDictionary& src,
                 std::function<void (UnstableNode&, UnstableNode&)> copy);

  inline
  void replicate(VM vm, Node*& dest, Node* src, Node* parent,
                 std::function<void (UnstableNode&, UnstableNode&)> copy);

private:
  enum WalkOrder { wkPreOrder, wkInOrder, wkPostOrder };

  template <bool reversed = false>
  void preOrderWalk(std::function<void (Node*)> f) {
    walk<wkPreOrder, reversed>(f);
  }

  template <bool reversed = false>
  void inOrderWalk(std::function<void (Node*)> f) {
    walk<wkInOrder, reversed>(f);
  }

  template <bool reversed = false>
  void postOrderWalk(std::function<void (Node*)> f) {
    walk<wkPostOrder, reversed>(f);
  }

  template <WalkOrder order, bool reversed>
  inline
  void walk(std::function<void (Node*)> f);

  template <WalkOrder order, bool reversed>
  inline
  void walkInternal(std::function<void (Node*)> f, Node* node);

private:
  inline
  Node* newNode(VM vm, Node* parent, Color color, RichNode key);

  Node* mallocNode(VM vm) {
    return static_cast<Node*>(vm->malloc(sizeof(Node)));
  }

  void freeNode(VM vm, Node* node) {
    vm->free(static_cast<void*>(node), sizeof(Node));
  }

  inline
  void rotateLeft(Node* parent, Node* child);

  inline
  void rotateRight(Node* parent, Node* child);

private:
  Node* root;
};

////////////////
// Dictionary //
////////////////

class Dictionary;

#ifndef MOZART_GENERATOR
#include "Dictionary-implem-decl.hh"
#endif

/**
 * Dictionary
 */
template <>
class Implementation<Dictionary>: public WithHome,
  public DottableHelper<Dictionary> {
public:
  typedef SelfType<Dictionary>::Self Self;
public:
  Implementation(VM vm): WithHome(vm) {}

  Implementation(VM vm, NodeDictionary& src): WithHome(vm) {
    dict.clone(vm, src);
  }

  inline
  Implementation(VM vm, GR gr, Self from);

public:
  // Dottable interface

  inline
  OpResult dot(Self self, VM vm, RichNode feature, UnstableNode& result);

  inline
  OpResult hasFeature(Self self, VM vm, RichNode feature, bool& result);

public:
  // DotAssignable interface

  OpResult dotAssign(Self self, VM vm, RichNode feature, RichNode newValue) {
    return dictPut(self, vm, feature, newValue);
  }

  OpResult dotExchange(Self self, VM vm, RichNode feature,
                       RichNode newValue, UnstableNode& oldValue) {
    return dictExchange(self, vm, feature, newValue, oldValue);
  }

public:
  // DictionaryLike interface

  inline
  OpResult isDictionary(Self self, VM vm, bool& result);

  inline
  OpResult dictIsEmpty(Self self, VM vm, bool& result);

  inline
  OpResult dictMember(Self self, VM vm, RichNode feature, bool& result);

  inline
  OpResult dictGet(Self self, VM vm, RichNode feature, UnstableNode& result);

  inline
  OpResult dictCondGet(Self self, VM vm, RichNode feature,
                       RichNode defaultValue, UnstableNode& result);

  inline
  OpResult dictPut(Self self, VM vm, RichNode feature, RichNode newValue);

  inline
  OpResult dictExchange(Self self, VM vm, RichNode feature,
                        RichNode newValue, UnstableNode& oldValue);

  inline
  OpResult dictCondExchange(Self self, VM vm, RichNode feature,
                            RichNode defaultValue,
                            RichNode newValue, UnstableNode& oldValue);

  inline
  OpResult dictRemove(Self self, VM vm, RichNode feature);

  inline
  OpResult dictRemoveAll(Self self, VM vm);

  inline
  OpResult dictKeys(Self self, VM vm, UnstableNode& result);

  inline
  OpResult dictEntries(Self self, VM vm, UnstableNode& result);

  inline
  OpResult dictItems(Self self, VM vm, UnstableNode& result);

  inline
  OpResult dictClone(Self self, VM vm, UnstableNode& result);

public:
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  NodeDictionary dict;
};

#ifndef MOZART_GENERATOR
#include "Dictionary-implem-decl-after.hh"
#endif

}

#endif // __DICTIONARY_DECL_H
