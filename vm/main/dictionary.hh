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

#ifndef __DICTIONARY_H
#define __DICTIONARY_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

////////////////////
// NodeDictionary //
////////////////////

NodeDictionary::NodeDictionary(GR gr, NodeDictionary& src): root(nullptr) {
  replicate(gr->vm, src, [gr] (UnstableNode& dest, UnstableNode& src) {
    gr->copyUnstableNode(dest, src);
  });
}

bool NodeDictionary::lookup(VM vm, RichNode key, UnstableNode*& value) {
  Node* node;
  Node* parent;

  if (lookupNode(vm, key, node, parent)) {
    value = &node->value;
    return true;
  } else {
    return false;
  }
}

bool NodeDictionary::lookupOrCreate(VM vm, RichNode key, UnstableNode*& value) {
  Node* node;
  Node* parent;

  if (lookupNode(vm, key, node, parent)) {
    // Found
    value = &node->value;
    return true;
  } else {
    // Not found, create
    node = newNode(vm, parent, clRed, key);

    if (parent == nullptr)
      root = node;
    else if (compareFeatures(vm, key, parent->key) < 0)
      parent->left = node;
    else
      parent->right = node;

    fixInsert(vm, node);

    value = &node->value;
    return false;
  }
}

bool NodeDictionary::remove(VM vm, RichNode key) {
  Node* node;
  Node* parent;
  if (!lookupNode(vm, key, node, parent))
    return false;

  if ((node->left != nullptr) && (node->right != nullptr)) {
    Node* bottom = node->left->rightMost();
    node->key = std::move(bottom->key);
    node->value = std::move(bottom->value);

    node = bottom;
    parent = node->parent;
  }

  removeNodeWithAtMostOneNonLeafChild(vm, node, parent);
  return true;
}

void NodeDictionary::removeAll(VM vm) {
  if (empty())
    return;

  postOrderWalk([=] (Node* node) {
    // Do NOT free node itself, as this destroys the walk algorithm
    if (node->left != nullptr)
      freeNode(vm, node->left);
    if (node->right != nullptr)
      freeNode(vm, node->right);
  });

  freeNode(vm, root);
  root = nullptr;
}

template <class T>
inline
T NodeDictionary::foldRight(
  T init, std::function<T (UnstableNode&, UnstableNode&, T)> f) {

  T value = std::move(init);

  inOrderWalk<true>([&value, f] (Node* node) {
    value = f(node->key, node->value, std::move(value));
  });

  return value;
}

void NodeDictionary::clone(VM vm, NodeDictionary src) {
  removeAll(vm);

  replicate(vm, src, [vm] (UnstableNode& dest, UnstableNode& src) {
    dest.copy(vm, src);
  });
}

bool NodeDictionary::lookupNode(VM vm, RichNode key, Node*& node,
                                Node*& parent) {
  node = root;
  parent = nullptr;

  while (node != nullptr) {
    int comparison = compareFeatures(vm, key, node->key);

    if (comparison == 0) {
      return true;
    } else if (comparison < 0) {
      parent = node;
      node = node->left;
    } else {
      parent = node;
      node = node->right;
    }
  }

  return false;
}

void NodeDictionary::fixInsert(VM vm, Node* node) {
  // Algorithm was taken from Wikipedia. Case numbers refer to that.

  assert(node->color == clRed);

  Node* parent = node->parent;

  if (parent == nullptr) {
    // Case 1
    node->color = clBlack;
  } else if (parent->color == clBlack) {
    // Case 2: nothing to do
  } else {
    Node* grandParent = parent->parent;
    assert(grandParent != nullptr);        // because parent is red
    assert(grandParent->color == clBlack); // for the same reason

    Node* uncle = grandParent->getTheOtherChild(parent);

    if (uncle->safeIsRed()) {
      // Case 3
      parent->color = clBlack;
      uncle->color = clBlack;
      grandParent->color = clRed;
      fixInsert(vm, grandParent);
    } else {
      // Case 4
      if ((node == parent->right) && (parent == grandParent->left)) {
        rotateLeft(parent, node);
        std::swap(node, parent);
      } else if ((node == parent->left) && (parent == grandParent->right)) {
        rotateRight(parent, node);
        std::swap(node, parent);
      }

      // Case 5
      parent->color = clBlack;
      grandParent->color = clRed;
      if (parent == grandParent->left)
        rotateRight(grandParent, parent);
      else
        rotateLeft(grandParent, parent);
    }
  }
}

void NodeDictionary::removeNodeWithAtMostOneNonLeafChild(VM vm, Node* node,
                                                         Node* parent) {
  // Algorithm was taken from Wikipedia. Case numbers refer to that.

  assert((node->left == nullptr) || (node->right == nullptr));

  Color nodeColor = node->color;
  Node* child = node->getOneChild();
  replaceChild(vm, parent, node, child);

  if (nodeColor == clRed) {
    // Simple case 1 - nothing to do
  } else if (child != nullptr) {
    // Simple case 2 - just blacken the child
    assert(child->color == clRed);
    child->color = clBlack;
  } else {
    // Complex case
    fixRemove(vm, child, parent);
  }
}

void NodeDictionary::replaceChild(VM vm, Node* parent, Node* child,
                                  Node* newChild) {
  if (parent == nullptr)
    root = newChild;
  else if (parent->left == child)
    parent->left = newChild;
  else
    parent->right = newChild;

  if (newChild != nullptr)
    newChild->parent = parent;

  freeNode(vm, child);
}

void NodeDictionary::fixRemove(VM vm, Node* node, Node* parent) {
  if (parent == nullptr) {
    // Case 1 - nothing to do
  } else {
    Node* sibling = parent->getTheOtherChild(node);
    assert(sibling != nullptr);

    if (sibling->color == clRed) {
      // Case 2
      parent->color = clRed;
      sibling->color = clBlack;
      if (node == parent->left)
        rotateLeft(parent, sibling);
      else
        rotateRight(parent, sibling);
      parent = sibling;
      sibling = parent->getTheOtherChild(node);
    }

    assert(sibling->color == clBlack);
    Node* siblingLeft = sibling->left;
    Node* siblingRight = sibling->right;

    if (siblingLeft->safeIsBlack() && siblingRight->safeIsBlack()) {
      if (parent->color == clBlack) {
        // Case 3
        sibling->color = clRed;
        fixRemove(vm, parent, parent->parent);
      } else {
        // Case 4
        sibling->color = clRed;
        parent->color = clBlack;
      }
    } else {
      // Case 5
      if ((node == parent->left) && siblingRight->safeIsBlack()) {
        assert(siblingLeft->safeIsRed());
        rotateRight(sibling, siblingLeft);
        std::swap(sibling, siblingLeft);
      } else if ((node == parent->right) && siblingLeft->safeIsBlack()) {
        assert(siblingRight->safeIsRed());
        rotateLeft(sibling, siblingRight);
        std::swap(sibling, siblingRight);
      }

      // Case 6
      sibling->color = parent->color;
      parent->color = clBlack;
      if (node == parent->left) {
        sibling->right->color = clBlack;
        rotateLeft(parent, sibling);
      } else {
        sibling->left->color = clBlack;
        rotateRight(parent, sibling);
      }
    }
  }
}

void NodeDictionary::replicate(
  VM vm, NodeDictionary& src,
  std::function<void (UnstableNode&, UnstableNode&)> copy) {

  assert(empty());
  replicate(vm, root, src.root, nullptr, copy);
}

void NodeDictionary::replicate(
  VM vm, Node*& dest, Node* src, Node* parent,
  std::function<void (UnstableNode&, UnstableNode&)> copy) {

  if (src == nullptr) {
    dest = nullptr;
  } else {
    dest = mallocNode(vm);
    dest->parent = parent;
    dest->color = src->color;
    copy(dest->key, src->key);
    copy(dest->value, src->value);
    replicate(vm, dest->left, src->left, dest, copy);
    replicate(vm, dest->right, src->right, dest, copy);
  }
}

template <NodeDictionary::WalkOrder order, bool reversed>
void NodeDictionary::walk(std::function<void (Node*)> f) {
  walkInternal<order, reversed>(f, root);
}

template <NodeDictionary::WalkOrder order, bool reversed>
void NodeDictionary::walkInternal(std::function<void (Node*)> f, Node* node) {
  if (node == nullptr)
    return;

  if (order == wkPreOrder)
    f(node);

  if (reversed)
    walkInternal<order, reversed>(f, node->right);
  else
    walkInternal<order, reversed>(f, node->left);

  if (order == wkInOrder)
    f(node);

  if (reversed)
    walkInternal<order, reversed>(f, node->left);
  else
    walkInternal<order, reversed>(f, node->right);

  if (order == wkPostOrder)
    f(node);
}

auto NodeDictionary::newNode(VM vm, Node* parent, Color color,
                             RichNode key) -> Node* {
  Node* node = mallocNode(vm);
  node->parent = parent;
  node->left = nullptr;
  node->right = nullptr;
  node->color = color;
  node->key.copy(vm, key);
  node->value.make<Unit>(vm);

  return node;
}

void NodeDictionary::rotateLeft(Node* parent, Node* child) {
  assert(parent->right == child);

  Node* grandParent = parent->parent;

  parent->right = child->left;
  if (child->left != nullptr)
    child->left->parent = parent;

  child->left = parent;
  child->parent = grandParent;
  parent->parent = child;

  if (grandParent == nullptr)
    root = child;
  else if (grandParent->left == parent)
    grandParent->left = child;
  else
    grandParent->right = child;
}

void NodeDictionary::rotateRight(Node* parent, Node* child) {
  assert(parent->left == child);

  Node* grandParent = parent->parent;

  parent->left = child->right;
  if (child->right != nullptr)
    child->right->parent = parent;

  child->right = parent;
  child->parent = grandParent;
  parent->parent = child;

  if (grandParent == nullptr)
    root = child;
  else if (grandParent->left == parent)
    grandParent->left = child;
  else
    grandParent->right = child;
}

////////////////
// Dictionary //
////////////////

#include "Dictionary-implem.hh"

Implementation<Dictionary>::Implementation(VM vm, GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  // TODO
}

OpResult Implementation<Dictionary>::isDictionary(Self self, VM vm,
                                                  bool& result) {
  result = true;
  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictIsEmpty(Self self, VM vm,
                                                 bool& result) {
  result = dict.empty();
  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictMember(
  Self self, VM vm, RichNode feature, bool& result) {

  MOZART_REQUIRE_FEATURE(feature);

  result = dict.contains(vm, feature);
  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictGet(
  Self self, VM vm, RichNode feature, UnstableNode& result) {

  MOZART_REQUIRE_FEATURE(feature);

  UnstableNode* value;
  if (dict.lookup(vm, feature, value)) {
    result.copy(vm, *value);
    return OpResult::proceed();
  } else {
    return raise(vm, u"dictKeyNotFound", self, feature);
  }
}

OpResult Implementation<Dictionary>::dictCondGet(
  Self self, VM vm, RichNode feature, RichNode defaultValue,
  UnstableNode& result) {

  MOZART_REQUIRE_FEATURE(feature);

  UnstableNode* value;
  if (dict.lookup(vm, feature, value)) {
    result.copy(vm, *value);
  } else {
    result.copy(vm, defaultValue);
  }

  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictPut(
  Self self, VM vm, RichNode feature, RichNode newValue) {

  if (!isHomedInCurrentSpace(vm))
    return raise(vm, u"globalState", "dictionary");

  MOZART_REQUIRE_FEATURE(feature);

  UnstableNode* value;
  dict.lookupOrCreate(vm, feature, value);

  value->copy(vm, newValue);
  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictExchange(
  Self self, VM vm, RichNode feature, RichNode newValue,
  UnstableNode& oldValue) {

  if (!isHomedInCurrentSpace(vm))
    return raise(vm, u"globalState", "dictionary");

  UnstableNode* value;
  if (dict.lookup(vm, feature, value)) {
    oldValue.copy(vm, *value);
    value->copy(vm, newValue);
    return OpResult::proceed();
  } else {
    return raise(vm, u"dictKeyNotFound", self, feature);
  }
}

OpResult Implementation<Dictionary>::dictCondExchange(
  Self self, VM vm, RichNode feature, RichNode defaultValue,
  RichNode newValue, UnstableNode& oldValue) {

  if (!isHomedInCurrentSpace(vm))
    return raise(vm, u"globalState", "dictionary");

  UnstableNode* value;
  if (dict.lookupOrCreate(vm, feature, value)) {
    oldValue.copy(vm, *value);
  } else {
    oldValue.copy(vm, defaultValue);
  }

  value->copy(vm, newValue);

  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictRemove(
  Self self, VM vm, RichNode feature) {

  if (!isHomedInCurrentSpace(vm))
    return raise(vm, u"globalState", "dictionary");

  MOZART_REQUIRE_FEATURE(feature);

  dict.remove(vm, feature);
  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictRemoveAll(Self self, VM vm) {
  if (!isHomedInCurrentSpace(vm))
    return raise(vm, u"globalState", "dictionary");

  dict.removeAll(vm);
  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictKeys(
  Self self, VM vm, UnstableNode& result) {

  result = dict.foldRight<UnstableNode>(trivialBuild(vm, vm->coreatoms.nil),
    [vm] (UnstableNode& key, UnstableNode& value, UnstableNode previous) {
      return buildCons(vm, key, std::move(previous));
    }
  );

  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictEntries(
  Self self, VM vm, UnstableNode& result) {

  result = dict.foldRight<UnstableNode>(trivialBuild(vm, vm->coreatoms.nil),
    [vm] (UnstableNode& key, UnstableNode& value, UnstableNode previous) {
      return buildCons(vm,
                       buildTuple(vm, vm->coreatoms.sharp, key, value),
                       std::move(previous));
    }
  );

  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictItems(
  Self self, VM vm, UnstableNode& result) {

  result = dict.foldRight<UnstableNode>(trivialBuild(vm, vm->coreatoms.nil),
    [vm] (UnstableNode& key, UnstableNode& value, UnstableNode previous) {
      return buildCons(vm, value, std::move(previous));
    }
  );

  return OpResult::proceed();
}

OpResult Implementation<Dictionary>::dictClone(
  Self self, VM vm, UnstableNode& result) {

  result = Dictionary::build(vm, dict);
  return OpResult::proceed();
}

void Implementation<Dictionary>::printReprToStream(
  Self self, VM vm, std::ostream& out, int depth) {

  out << "<Dictionary>";
}

}

#endif // MOZART_GENERATOR

#endif // __DICTIONARY_H