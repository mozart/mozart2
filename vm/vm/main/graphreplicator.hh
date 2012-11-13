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

#ifndef __GRAPHREPLICATOR_H
#define __GRAPHREPLICATOR_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

/////////////////////
// GraphReplicator //
/////////////////////

GraphReplicator::GraphReplicator(VM vm, Kind kind):
  vm(vm), _kind(kind), secondMM(vm->getSecondMemoryManager()) {

  todos.stableNodes = nullptr;
  todos.unstableNodes = nullptr;
}

void GraphReplicator::copySpace(SpaceRef& to, SpaceRef from) {
  to = from;
  todos.spaces.push_front(secondMM, &to);
}

void GraphReplicator::copyThread(Runnable*& to, Runnable* from) {
  to = from;
  todos.threads.push_front(secondMM, &to);
}

void GraphReplicator::copyStableNode(StableNode& to, StableNode& from) {
  to.grNext = todos.stableNodes;
  to.grFrom = &from;
  todos.stableNodes = &to;
}

void GraphReplicator::copyUnstableNode(UnstableNode& to, UnstableNode& from) {
  to.grNext = todos.unstableNodes;
  to.grFrom = &from;
  todos.unstableNodes = &to;
}

void GraphReplicator::copyStableRef(StableNode*& to, StableNode* from) {
  to = from;
  todos.stableRefs.push_front(secondMM, &to);
}

void GraphReplicator::copyStableNodes(StaticArray<StableNode> to,
                                      StaticArray<StableNode> from,
                                      size_t count) {
  for (size_t i = 0; i < count; ++i)
    copyStableNode(to[i], from[i]);
}

void GraphReplicator::copyUnstableNodes(StaticArray<UnstableNode> to,
                                        StaticArray<UnstableNode> from,
                                        size_t count) {
  for (size_t i = 0; i < count; ++i)
    copyUnstableNode(to[i], from[i]);
}

atom_t GraphReplicator::copyAtom(atom_t from) {
  if (kind() == grkGarbageCollection)
    return vm->getAtom(from.length(), from.contents());
  else
    return from;
}

template <class Self>
void GraphReplicator::runCopyLoop() {
  while (!todos.spaces.empty() ||
         !todos.threads.empty() ||
         todos.stableNodes != nullptr ||
         todos.unstableNodes != nullptr ||
         !todos.stableRefs.empty()) {

    if (!todos.spaces.empty()) {
      processSpaceInternal<Self>(
        *todos.spaces.pop_front(secondMM));
    } else if (!todos.threads.empty()) {
      processThreadInternal<Self>(
        *todos.threads.pop_front(secondMM));
    } else if (todos.stableNodes != nullptr) {
      processNodeInternal<Self, StableNode, GRedToStable>(
        todos.stableNodes);
    } else if (todos.unstableNodes != nullptr) {
      processNodeInternal<Self, UnstableNode, GRedToUnstable>(
        todos.unstableNodes);
    } else {
      processStableRefInternal<Self>(
        *todos.stableRefs.pop_front(secondMM));
    }
  }
}

template <class Self>
void GraphReplicator::processSpaceInternal(SpaceRef& space) {
  static_cast<Self*>(this)->processSpace(space, space);
}

template <class Self>
void GraphReplicator::processThreadInternal(Runnable*& thread) {
  static_cast<Self*>(this)->processThread(thread, thread);
}

template <class Self, class NodeType, class GCedType>
void GraphReplicator::processNodeInternal(Node*& list) {
  NodeType* to = static_cast<NodeType*>(list);
  list = to->grNext;

  RichNode from = *static_cast<NodeType*>(to->grFrom);

  static_cast<Self*>(this)->template processNode<NodeType, GCedType>(to, from);
}

template <class Self>
void GraphReplicator::processStableRefInternal(StableNode*& ref) {
  RichNode from = *ref;

  if (from.is<GRedToStable>()) {
    StableNode* dest = from.as<GRedToStable>().dest();
    ref = RichNode(*dest).getStableRef(vm);
  } else if (from.is<GRedToUnstable>()) {
    UnstableNode* dest = from.as<GRedToUnstable>().dest();
    ref = RichNode(*dest).getStableRef(vm);
  } else {
    ref = new (vm) StableNode;
    static_cast<Self*>(this)->template processNode<StableNode, GRedToStable>(
      ref, from);
  }
}

}

#endif // MOZART_GENERATOR

#endif // __GRAPHREPLICATOR_H
