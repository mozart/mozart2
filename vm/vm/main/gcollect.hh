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

#ifndef __GCOLLECT_H
#define __GCOLLECT_H

#include "gcollect-decl.hh"
#include "vm.hh"
#include "store.hh"

//////////////////////
// GarbageCollector //
//////////////////////

MemoryManager& GarbageCollector::getMemoryManager() {
  return vm->getMemoryManager();
}

void GarbageCollector::gcThread(Suspendable* from, Suspendable*& to) {
  to = from;
  threadsToGC.push_front(secondMemManager, &to);
}

void GarbageCollector::gcStableNode(StableNode& from, StableNode& to) {
  to.gcNext = stableNodesToGC;
  to.gcFrom = &from.node;
  stableNodesToGC = &to;
}

void GarbageCollector::gcUnstableNode(UnstableNode& from, UnstableNode& to) {
  to.gcNext = unstableNodesToGC;
  to.gcFrom = &from.node;
  unstableNodesToGC = &to;
}

void GarbageCollector::gcStableRef(StableNode* from, StableNode*& to) {
  to = from;
  stableRefsToGC.push_front(secondMemManager, &to);
}

#endif // __GCOLLECT_H
