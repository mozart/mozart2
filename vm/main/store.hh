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

#include "reference-decl.hh"

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
  if (!from.node.type->isCopiable())
    Reference::makeFor(vm, from);
  node = from.node;
}

void UnstableNode::reset(VM vm) {
  node.reset(vm);
}

void UnstableNode::swap(UnstableNode& from) {
  Node temp = node;
  node = from.node;
  from.node = temp;
}

#endif // __STORE_H
