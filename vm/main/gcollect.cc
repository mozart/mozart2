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

#include "mozartcore.hh"

#include <iostream>

//////////////////////
// GarbageCollector //
//////////////////////

void GarbageCollector::doGC() {
  if (OzDebugGC) {
    std::cerr << "Before GC: " << getMemoryManager().getAllocated();
    std::cerr << " bytes used." << std::endl;
  }

  // Before GC
  for (auto iterator = vm->aliveThreads.begin();
       iterator != vm->aliveThreads.end(); iterator++) {
    (*iterator)->beforeGC();
  }

  // Swap spaces
  getMemoryManager().swapWith(secondMemManager);
  getMemoryManager().init();

  // Forget the list of alive threads
  vm->aliveThreads = RunnableList();

  // Root of GC are runnable threads
  vm->getThreadPool().gCollect(this);

  // GC loop
  while (!threadsToGC.empty() ||
         stableNodesToGC != nullptr ||
         unstableNodesToGC != nullptr ||
         !stableRefsToGC.empty()) {

    if (!threadsToGC.empty()) {
      gcOneThread(*threadsToGC.pop_front(secondMemManager));
    } else if (stableNodesToGC != nullptr) {
      gcOneNode<StableNode, GCedToStable>(stableNodesToGC);
    } else if (unstableNodesToGC != nullptr) {
      gcOneNode<UnstableNode, GCedToUnstable>(unstableNodesToGC);
    } else {
      gcOneStableRef(*stableRefsToGC.pop_front(secondMemManager));
    }
  }

  // After GC
  for (auto iterator = vm->aliveThreads.begin();
       iterator != vm->aliveThreads.end(); iterator++) {
    (*iterator)->afterGC();
  }

  if (OzDebugGC) {
    std::cerr << "After GC: " << getMemoryManager().getAllocated();
    std::cerr << " bytes used." << std::endl;
  }
}

void GarbageCollector::gcOneThread(Runnable*& thread) {
  thread = thread->gCollect(this);
}

template <class NodeType, class GCedType>
void GarbageCollector::gcOneNode(NodeType*& list) {
  NodeType* node = list;
  list = node->gcNext;

  Node* from = node->gcFrom;

  if (OzDebugGC) {
    std::cerr << "gc node " << from << " of type " << from->type->getName();
    std::cerr << "   \tto node " << node << std::endl;
  }

  from->type->gCollect(this, *from, *node);
  from->make<GCedType>(vm, node);
}

void GarbageCollector::gcOneStableRef(StableNode*& ref) {
  if (OzDebugGC)
    std::cerr << "gc stable ref from " << ref << " to " << &ref << std::endl;

  Node& from = Reference::dereference(ref->node);

  if (from.type == GCedToStable::type()) {
    StableNode* dest = IMPLNOSELF(StableNode*, GCedToStable, dest, &from);
    ref = Reference::getStableRefFor(vm, *dest);
  } else if (from.type == GCedToUnstable::type()) {
    UnstableNode* dest = IMPLNOSELF(UnstableNode*, GCedToUnstable, dest, &from);
    ref = Reference::getStableRefFor(vm, *dest);
  } else {
    ref = new (vm) StableNode;
    from.type->gCollect(this, from, *ref);
  }
}
