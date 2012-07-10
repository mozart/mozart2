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

////////////////
// StableNode //
////////////////

void StableNode::init(VM vm, StableNode& from) {
  if (from.isCopyable())
    node = from.node;
  else
    node.make<Reference>(vm, &from);
}

void StableNode::init(VM vm, UnstableNode& from) {
  node = from.node;
  if (!isCopyable())
    from.node.make<Reference>(vm, this);
}

void StableNode::init(VM vm, UnstableNode&& from) {
  node = from.node;
}

void StableNode::init(VM vm, RichNode from) {
  if (from.isStable())
    init(vm, *from._stable);
  else
    init(vm, *from._unstable);
}

void StableNode::init(VM vm) {
  node.make<Unit>(vm);
}

bool StableNode::isCopyable() {
  return node.type->isCopyable();
}

//////////////////
// UnstableNode //
//////////////////

void UnstableNode::init(VM vm, StableNode& from) {
  copy(vm, from);
}

void UnstableNode::init(VM vm, UnstableNode& from) {
  copy(vm, from);
}

void UnstableNode::init(VM vm, UnstableNode&& from) {
  copy(vm, std::move(from));
}

void UnstableNode::init(VM vm, RichNode from) {
  copy(vm, from);
}

void UnstableNode::init(VM vm) {
  node.make<Unit>(vm);
}

void UnstableNode::copy(VM vm, StableNode& from) {
  if (from.isCopyable())
    node = from.node;
  else
    node.make<Reference>(vm, &from);
}

void UnstableNode::copy(VM vm, UnstableNode& from) {
  if (from.isCopyable()) {
    node = from.node;
  } else {
    StableNode* stable = new (vm) StableNode;
    stable->node = from.node;
    node.make<Reference>(vm, stable);
    from.node.make<Reference>(vm, stable);
  }
}

void UnstableNode::copy(VM vm, UnstableNode&& from) {
  node = from.node;
}

void UnstableNode::copy(VM vm, RichNode from) {
  if (from.isStable())
    copy(vm, *from._stable);
  else
    copy(vm, *from._unstable);
}

void UnstableNode::swap(UnstableNode& from) {
  std::swap(node, from.node);
}

bool UnstableNode::isCopyable() {
  return node.type->isCopyable();
}

//////////////
// RichNode //
//////////////

RichNode::RichNode(StableNode& origin) {
  if (origin.node.type != Reference::type()) {
    _stable = &origin;
    _isStable = true;
  } else {
    _stable = dereference(&origin.node);
    _isStable = true;
  }
}

RichNode::RichNode(UnstableNode& origin) {
  if (origin.node.type != Reference::type()) {
    _unstable = &origin;
    _isStable = false;
  } else {
    _stable = dereference(&origin.node);
    _isStable = true;
  }
}

bool RichNode::isTransient() {
  return type()->isTransient();
}

bool RichNode::isFeature() {
  return type()->isFeature();
}

StableNode* RichNode::getStableRef(VM vm) {
  ensureStable(vm);
  return _stable;
}

void RichNode::update() {
  if (node()->type == Reference::type()) {
    _stable = dereference(node());
    _isStable = true;
  }
}

void RichNode::ensureStable(VM vm) {
  if (!isStable()) {
    StableNode* stable = new (vm) StableNode;
    stable->init(vm, *_unstable);
    _stable = stable;
    _isStable = true;
  }
}

void RichNode::reinit(VM vm, StableNode& from) {
  if (from.isCopyable()) {
    *node() = from.node;
  } else {
    node()->make<Reference>(vm, &from);
  }
}

void RichNode::reinit(VM vm, UnstableNode& from) {
  if (from.isCopyable()) {
    *node() = from.node;
  } else if (isStable()) {
    _stable->init(vm, from);
  } else {
    _unstable->init(vm, from);
  }
}

void RichNode::reinit(VM vm, UnstableNode&& from) {
  *node() = from.node;
}

void RichNode::reinit(VM vm, RichNode from) {
  if (from.isStable())
    reinit(vm, *from._stable);
  else
    reinit(vm, *from._unstable);
}

std::string RichNode::toDebugString() {
  std::stringstream stream;
  stream << type()->getName() << "@" << node();
  return stream.str();
}

StableNode* RichNode::dereference(Node* node) {
  assert(node->type == Reference::type());

  /* This is optimized for the 1-dereference path.
   * Normally it would have been only a while loop. */
  StableNode* result = destOf(node);
  if (result->node.type != Reference::type())
    return result;
  else
    return dereferenceLoop(result);
}

StableNode* RichNode::dereferenceLoop(StableNode* node) {
  do {
    node = destOf(&node->node);
  } while (node->node.type == Reference::type());

  return node;
}

StableNode* RichNode::destOf(Node* node) {
  // TODO Can we get away without this ugly thing?
  typedef typename Storage<Reference>::Type StorageType;
  typedef Accessor<Reference, StorageType> Access;

  return Access::get(node->value).dest();
}

Node* RichNode::node() {
  return _isStable ? &_stable->node : &_unstable->node;
}

}

#endif // MOZART_GENERATOR

#endif // __STORE_H
