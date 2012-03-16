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

#include "store-decl.hh"

#include "reference.hh"

#include <sstream>

#ifndef MOZART_GENERATOR

namespace mozart {

/////////////////////////
// Node implementation //
/////////////////////////

void Node::reset(VM vm) {
  type = nullptr;
  value.init<void*>(vm, nullptr);
}

void StableNode::init(VM vm, StableNode& from) {
  if (from.node.type->isCopiable())
    node = from.node;
  else
    node.make<Reference>(vm, &from);
}

void StableNode::init(VM vm, UnstableNode& from) {
  node = from.node;
  if (!node.type->isCopiable())
    from.make<Reference>(vm, this);
}

void UnstableNode::copy(VM vm, StableNode& from) {
  if (from.node.type->isCopiable())
    node = from.node;
  else
    make<Reference>(vm, &from);
}

void UnstableNode::copy(VM vm, UnstableNode& from) {
  if (from.type()->isCopiable()) {
    node = from.node;
  } else {
    StableNode* stable = new (vm) StableNode;
    stable->node = from.node;
    make<Reference>(vm, stable);
    from.make<Reference>(vm, stable);
  }
}

void UnstableNode::reset(VM vm) {
  node.reset(vm);
}

void UnstableNode::swap(UnstableNode& from) {
  Node temp = node;
  node = from.node;
  from.node = temp;
}

//////////////
// RichNode //
//////////////

RichNode::RichNode(UnstableNode& origin) :
  _node(dereference(&origin.node)), _origin(origin) {
}

StableNode* RichNode::getStableRef(VM vm) {
  return getStableRefFor(vm, _origin);
}

void RichNode::update() {
  _node = dereference(_node);
}

void RichNode::reinit(VM vm, StableNode& from) {
  if (from.type()->isCopiable()) {
    *_node = from.node;
  } else {
    _node->make<Reference>(vm, &from);
    _origin.node = *_node;
  }
}

void RichNode::reinit(VM vm, UnstableNode& from) {
  if (from.type()->isCopiable()) {
    *_node = from.node;
  } else if (_origin.type() == Reference::type()) {
    StableNode* stable = getStableRefFor(vm, _origin);
    stable->init(vm, from);
  } else {
    StableNode* stable = getStableRefFor(vm, from);
    _node->make<Reference>(vm, stable);
    _origin.node = *_node;
  }
}

void RichNode::reinit(VM vm, RichNode from) {
  reinit(vm, from.origin());
}

std::string RichNode::toDebugString() {
  std::stringstream stream;
  stream << type()->getName() << "@" << _node;
  return stream.str();
}

Node* RichNode::dereference(Node* node) {
  /* This is optimized for the 0- and 1-dereference paths.
   * Normally it would have been only a while loop. */
  if (node->type != Reference::type())
    return node;
  else {
    Node* result = &destOf(node)->node;
    if (result->type != Reference::type())
      return result;
    else
      return dereferenceLoop(result);
  }
}

Node* RichNode::dereferenceLoop(Node* node) {
  do {
    node = &destOf(node)->node;
  } while (node->type == Reference::type());

  return node;
}

StableNode* RichNode::getStableRefFor(VM vm, UnstableNode& node) {
  /* This is optimized for the 0- and 1-dereference paths.
   * Normally the else part would have been only a while loop. */
  if (node.type() != Reference::type()) {
    StableNode* stable = new (vm) StableNode;
    stable->init(vm, node);
    return stable;
  } else {
    StableNode* result = destOf(&node.node);
    if (result->type() != Reference::type())
      return result;
    else
      return getStableRefForLoop(result);
  }
}

StableNode* RichNode::getStableRefForLoop(StableNode* node) {
  do {
    node = destOf(&node->node);
  } while (node->type() == Reference::type());

  return node;
}

StableNode* RichNode::destOf(Node* node) {
  // TODO Can we get away without this ugly thing?
  typedef typename Storage<Reference>::Type StorageType;
  typedef Accessor<Reference, StorageType> Access;

  return Access::get(node->value).dest();
}

///////////////////
// BuiltinResult //
///////////////////

BuiltinResult BuiltinResult::proceed() {
  return BuiltinResult(nullptr, brProceed);
}

BuiltinResult BuiltinResult::waitFor(VM vm, RichNode node) {
  return BuiltinResult(node.getStableRef(vm), brWaitBefore);
}

BuiltinResult BuiltinResult::raise(VM vm, RichNode node) {
  return BuiltinResult(node.getStableRef(vm), brRaise);
}

}

#endif // MOZART_GENERATOR

#endif // __STORE_H
