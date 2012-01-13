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

#ifndef __VARIABLES_H
#define __VARIABLES_H

#include "type.hh"
#include "smallint.hh"
#include "vm.hh"

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
  Implementation<Reference>(StableNode* dest) : _dest(dest) {}

  StableNode* dest() const { return _dest; }
private:
  StableNode* _dest;
};

/**
 * Type of a reference
 */
class Reference {
public:
  typedef Node* Self;

  static const Type* const type;

  static StableNode* build(StableNode* dest) { return dest; }

  // This is optimized for the 0- and 1-dereference paths
  // Normally it would have been only a while loop
  static Node& dereference(Node& node) {
    if (node.type != type)
      return node;
    else {
      Node* result = &IMPLNOSELF(StableNode*, Reference, dest, &node)->node;
      if (result->type != type)
        return *result;
      else
        return dereferenceLoop(result);
    }
  }

  static void makeFor(VM vm, UnstableNode& node) {
    StableNode* stable = new (vm) StableNode;
    stable->init(vm, node);
  }

  static void makeFor(VM vm, Node& node) {
    UnstableNode temp;
    temp.node = node;
    makeFor(vm, temp);
    node = temp.node;
  }
private:
  static Node& dereferenceLoop(Node* node) {
    while (node->type == type)
      node = &(IMPLNOSELF(StableNode*, Reference, dest, node)->node);
    return *node;
  }

  static const Type rawType;
};

/////////////
// Unbound //
/////////////

class Unbound;

template <>
class Storage<Unbound> {
public:
  typedef void* Type;
};

template <>
class Implementation<Unbound> {
public:
  Implementation<Unbound>() {}
  Implementation<Unbound>(void* dummy) {}

  void bind(Node* self, VM vm, Node* src);
};

/**
 * Type of an unbound variable (optimized for the no-wait case)
 */
class Unbound {
public:
  typedef Node* Self;

  static const Type* const type;

  static void* build() { return nullptr; }
private:
  static const Type rawType;
};

#endif // __VARIABLES_H
