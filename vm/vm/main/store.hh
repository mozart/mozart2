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

#include "mozartcore.hh"

#include <sstream>

#ifndef MOZART_GENERATOR

namespace mozart {

//////////
// Node //
//////////

StableNode* Node::asStable() {
  return static_cast<StableNode*>(this);
}

UnstableNode* Node::asUnstable() {
  return static_cast<UnstableNode*>(this);
}

////////////////
// StableNode //
////////////////

void StableNode::init(VM vm, StableNode& from) {
  if (from.isCopyable())
    set(from);
  else
    make<Reference>(vm, &from);
}

void StableNode::init(VM vm, UnstableNode& from) {
  set(from);
  if (!isCopyable())
    from.make<Reference>(vm, this);
}

void StableNode::init(VM vm, UnstableNode&& from) {
  set(from);
}

void StableNode::init(VM vm, RichNode from) {
  if (from.isStable())
    init(vm, from.asStable());
  else
    init(vm, from.asUnstable());
}

void StableNode::init(VM vm) {
  make<Unit>(vm);
}

template <typename T>
void StableNode::init(VM vm, T&& from) {
  set(mozart::build(vm, std::forward<T>(from)));
}

//////////////////
// UnstableNode //
//////////////////

void UnstableNode::init(VM vm) {
  make<Unit>(vm);
}

void UnstableNode::copy(VM vm, StableNode& from) {
  if (from.isCopyable())
    set(from);
  else
    make<Reference>(vm, &from);
}

void UnstableNode::copy(VM vm, UnstableNode& from) {
  if (from.isCopyable()) {
    set(from);
  } else {
    StableNode* stable = new (vm) StableNode;
    stable->set(from);
    make<Reference>(vm, stable);
    from.make<Reference>(vm, stable);
  }
}

void UnstableNode::copy(VM vm, UnstableNode&& from) {
  set(from);
}

void UnstableNode::copy(VM vm, RichNode from) {
  if (from.isStable())
    copy(vm, from.asStable());
  else
    copy(vm, from.asUnstable());
}

template <typename T>
void UnstableNode::copy(VM vm, T&& from) {
  set(mozart::build(vm, std::forward<T>(from)));
}

//////////////
// NodeHole //
//////////////

NodeHole::NodeHole(StableNode* node): _node(node), _isStable(true) {}

NodeHole::NodeHole(UnstableNode* node): _node(node), _isStable(false) {}

void NodeHole::fill(VM vm, UnstableNode&& value) {
  _node->set(value);
}

bool NodeHole::operator==(StableNode* rhs) {
  return _node == rhs;
}

bool NodeHole::operator==(UnstableNode* rhs) {
  return _node == rhs;
}

//////////////
// RichNode //
//////////////

RichNode::RichNode(StableNode& origin) {
  if (origin.type() != Reference::type()) {
    _node = &origin;
    _isStable = true;
  } else {
    _node = dereference(&origin);
    _isStable = true;
  }
}

RichNode::RichNode(UnstableNode& origin) {
  if (origin.type() != Reference::type()) {
    _node = &origin;
    _isStable = false;
  } else {
    _node = dereference(&origin);
    _isStable = true;
  }
}

RichNode::RichNode(NodeHole origin) {
  if (origin.node()->type() != Reference::type()) {
    _node = origin.node();
    _isStable = origin.isStable();
  } else {
    _node = dereference(origin.node());
    _isStable = true;
  }
}

bool RichNode::isTransient() {
  return type().isTransient();
}

bool RichNode::isFeature() {
  return type().isFeature();
}

StableNode* RichNode::getStableRef(VM vm) {
  ensureStable(vm);
  return &asStable();
}

void RichNode::update() {
  if (node()->type() == Reference::type()) {
    _node = dereference(node());
    _isStable = true;
  }
}

void RichNode::ensureStable(VM vm) {
  if (!isStable()) {
    StableNode* stable = new (vm) StableNode;
    stable->init(vm, asUnstable());
    _node = stable;
    _isStable = true;
  }
}

void RichNode::reinit(VM vm, StableNode& from) {
  if (from.isCopyable()) {
    node()->set(from);
  } else {
    node()->make<Reference>(vm, &from);
  }
}

void RichNode::reinit(VM vm, UnstableNode& from) {
  if (isStable()) {
    asStable().init(vm, from);
  } else {
    asUnstable().init(vm, from);
  }
}

void RichNode::reinit(VM vm, UnstableNode&& from) {
  node()->set(from);
}

void RichNode::reinit(VM vm, RichNode from) {
  if (from.isStable())
    reinit(vm, from.asStable());
  else
    reinit(vm, from.asUnstable());
}

std::string RichNode::toDebugString() {
  std::stringstream stream;
  stream << type()->getName() << "@" << node();
  return stream.str();
}

StableNode* RichNode::dereference(Node* node) {
  assert(node->type() == Reference::type());

  /* This is optimized for the 1-dereference path.
   * Normally it would have been only a while loop. */
  StableNode* result = destOf(node);
  if (result->type() != Reference::type())
    return result;
  else
    return dereferenceLoop(result);
}

StableNode* RichNode::dereferenceLoop(StableNode* node) {
  do {
    node = destOf(node);
  } while (node->type() == Reference::type());

  return node;
}

StableNode* RichNode::destOf(Node* node) {
  return Accessor<Reference>::get(node->value()).dest();
}

}

#endif // MOZART_GENERATOR

#endif // __STORE_H
