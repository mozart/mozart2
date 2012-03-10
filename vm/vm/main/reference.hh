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

#ifndef __REFERENCE_H
#define __REFERENCE_H

#include "reference-decl.hh"

#include "gctypes-decl.hh"

#include <iostream>

///////////////
// Reference //
///////////////

#ifndef MOZART_GENERATOR
#include "Reference-implem.hh"
#endif

#ifndef MOZART_GENERATOR

const Reference* ReferenceBase::type() {
  return Reference::type();
}

void ReferenceBase::gCollect(GC gc, Node& from, StableNode& to) const {
  Node& destNode = dereference(from);

  if (OzDebugGC) {
    std::cerr << " \\-> gc " << &destNode << " of type ";
    std::cerr << destNode.type->getName();
    std::cerr << "   \tto node " << &to << std::endl;
  }

  destNode.type->gCollect(gc, destNode, to);
  destNode.make<GCedToStable>(gc->vm, &to);
}

void ReferenceBase::gCollect(GC gc, Node& from, UnstableNode& to) const {
  Node& destNode = dereference(from);

  if (OzDebugGC) {
    std::cerr << " \\-> gc " << &destNode << " of type ";
    std::cerr << destNode.type->getName();
    std::cerr << "   \tto node " << &to << std::endl;
  }

  destNode.type->gCollect(gc, destNode, to);
  destNode.make<GCedToUnstable>(gc->vm, &to);
}

// This is optimized for the 0- and 1-dereference paths
// Normally it would have been only a while loop
Node& ReferenceBase::dereference(Node& node) {
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

StableNode* ReferenceBase::getStableRefFor(VM vm, UnstableNode& node) {
  if (node.type() != type()) {
    StableNode* stable = new (vm) StableNode;
    stable->init(vm, node);
    return stable;
  } else {
    return getStableRefFor(vm, node.node);
  }
}

StableNode* ReferenceBase::getStableRefFor(VM vm, StableNode& node) {
  if (node.type() != type())
    return &node;
  else
    return getStableRefFor(vm, node.node);
}

StableNode* ReferenceBase::getStableRefFor(VM vm, RichNode node) {
  return getStableRefFor(vm, node.origin());
}

Node& ReferenceBase::dereferenceLoop(Node* node) {
  while (node->type == type())
    node = &destOf(node)->node;
  return *node;
}

// This is optimized for the 1-dereference path
// Normally it would have been only a while loop
StableNode* ReferenceBase::getStableRefFor(VM vm, Node& node) {
  StableNode* result = destOf(&node);
  if (result->type() != type())
    return result;
  else
    return getStableRefForLoop(result);
}

StableNode* ReferenceBase::getStableRefForLoop(StableNode* node) {
  do {
    node = destOf(&node->node);
  } while (node->type() == type());

  return node;
}

StableNode* ReferenceBase::destOf(Node* node) {
  return Implementation<Reference>::SelfReadOnlyView(node).get().dest();
}

#endif // MOZART_GENERATOR

#endif // __REFERENCE_H
