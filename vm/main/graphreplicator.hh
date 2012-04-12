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
  // Spaces are copied immediately

  switch (kind()) {
    case grkGarbageCollection: {
      Space* space = from;
      to = space->gCollectOuter(static_cast<GC>(this));
      break;
    }

    case grkSpaceCloning: {
      Space* space = from;
      Space* copy = space->sCloneOuter(static_cast<SC>(this));
      to = copy;

      if (copy != space)
        static_cast<SC>(this)->spaceBackups.push_back(secondMM, space);

      break;
    }

    case grkCustom: {
      customCopySpace(to, from);
      break;
    }
  }
}

void GraphReplicator::copyThread(Runnable*& to, Runnable* from) {
  to = from;
  todos.threads.push_front(secondMM, &to);
}

void GraphReplicator::copyStableNode(StableNode& to, StableNode& from) {
  to.gcNext = todos.stableNodes;
  to.gcFrom = &from;
  todos.stableNodes = &to;
}

void GraphReplicator::copyUnstableNode(UnstableNode& to, UnstableNode& from) {
  to.gcNext = todos.unstableNodes;
  to.gcFrom = &from;
  todos.unstableNodes = &to;
}

void GraphReplicator::copyStableRef(StableNode*& to, StableNode* from) {
  to = from;
  todos.stableRefs.push_front(secondMM, &to);
}

template <class Self>
void GraphReplicator::runCopyLoop() {
  while (!todos.threads.empty() ||
         todos.stableNodes != nullptr ||
         todos.unstableNodes != nullptr ||
         !todos.stableRefs.empty()) {

    if (!todos.threads.empty()) {
      processThreadInternal<Self>(
        *todos.threads.pop_front(secondMM));
    } else if (todos.stableNodes != nullptr) {
      processNodeInternal<Self, StableNode, GCedToStable>(
        todos.stableNodes);
    } else if (todos.unstableNodes != nullptr) {
      processNodeInternal<Self, UnstableNode, GCedToUnstable>(
        todos.unstableNodes);
    } else {
      processStableRefInternal<Self>(
        *todos.stableRefs.pop_front(secondMM));
    }
  }
}

template <class Self>
void GraphReplicator::processThreadInternal(Runnable*& thread) {
  static_cast<Self*>(this)->processThread(thread, thread);
}

template <class Self, class NodeType, class GCedType>
void GraphReplicator::processNodeInternal(NodeType*& list) {
  NodeType* to = list;
  list = to->gcNext;

  UnstableNode temp(vm, *to->gcFrom);
  RichNode from = temp;

  static_cast<Self*>(this)->template processNode<NodeType, GCedType>(to, from);
}

template <class Self>
void GraphReplicator::processStableRefInternal(StableNode*& ref) {
  UnstableNode temp;
  temp.make<Reference>(vm, ref);
  RichNode from = temp;

  if (from.type() == GCedToStable::type()) {
    StableNode* dest = from.as<GCedToStable>().dest();
    UnstableNode temp2;
    temp2.make<Reference>(vm, dest);
    ref = RichNode(temp2).getStableRef(vm);
  } else if (from.type() == GCedToUnstable::type()) {
    UnstableNode* dest = from.as<GCedToUnstable>().dest();
    ref = RichNode(*dest).getStableRef(vm);
  } else {
    ref = new (vm) StableNode;
    static_cast<Self*>(this)->template processNode<StableNode, GCedToStable>(
      ref, from);
  }
}

}

#endif // MOZART_GENERATOR

#endif // __GRAPHREPLICATOR_H
