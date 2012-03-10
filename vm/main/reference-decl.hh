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

#ifndef __REFERENCE_DECL_H
#define __REFERENCE_DECL_H

#include "vm-decl.hh"

///////////////
// Reference //
///////////////

class Reference;

template <>
class Storage<Reference> {
public:
  typedef StableNode* Type;
};

template <>
class Implementation<Reference> {
public:
  Implementation(StableNode* dest) : _dest(dest) {}

  static StableNode* build(VM, StableNode* dest) { return dest; }

  StableNode* dest() const { return _dest; }
private:
  StableNode* _dest;
};

/**
 * Type of a reference
 */
class Reference: public Type {
private:
  typedef SelfType<Reference>::Self Self;
  typedef SelfType<Reference>::SelfReadOnlyView SelfReadOnlyView;
public:
  Reference() : Type("Reference", true) {}

  static const Reference* const type() {
    return &RawType<Reference>::rawType;
  }

  inline
  void gCollect(GC gc, Node& from, StableNode& to) const;

  inline
  void gCollect(GC gc, Node& from, UnstableNode& to) const;

  // This is optimized for the 0- and 1-dereference paths
  // Normally it would have been only a while loop
  static Node& dereference(Node& node) {
    if (node.type != type())
      return node;
    else {
      Node* result = &destOf(&node)->node;
      if (result->type != type())
        return *result;
      else
        return dereferenceLoop(result);
    }
  }

  static StableNode* getStableRefFor(VM vm, UnstableNode& node) {
    if (node.type() != type()) {
      StableNode* stable = new (vm) StableNode;
      stable->init(vm, node);
      return stable;
    } else {
      return getStableRefFor(vm, node.node);
    }
  }

  static StableNode* getStableRefFor(VM vm, StableNode& node) {
    if (node.type() != type())
      return &node;
    else
      return getStableRefFor(vm, node.node);
  }

  static StableNode* getStableRefFor(VM vm, RichNode node) {
    return getStableRefFor(vm, node.origin());
  }
private:
  static Node& dereferenceLoop(Node* node) {
    while (node->type == type())
      node = &destOf(node)->node;
    return *node;
  }

  // This is optimized for the 1-dereference path
  // Normally it would have been only a while loop
  static StableNode* getStableRefFor(VM vm, Node& node) {
    StableNode* result = destOf(&node);
    if (result->type() != type())
      return result;
    else
      return getStableRefForLoop(result);
  }

  static StableNode* getStableRefForLoop(StableNode* node) {
    do {
      node = destOf(&node->node);
    } while (node->type() == type());

    return node;
  }

  inline
  static StableNode* destOf(Node* node);
};

#endif // __REFERENCE_DECL_H
