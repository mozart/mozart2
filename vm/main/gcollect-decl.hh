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

#ifndef __GCOLLECT_DECL_H
#define __GCOLLECT_DECL_H

#include "core-forward-decl.hh"
#include "memmanager.hh"
#include "memmanlist.hh"
#include "suspendable-decl.hh"

// Set this to true to print debug info about the GC
#ifdef OZ_DEBUG_GC
const bool OzDebugGC = true;
#else
const bool OzDebugGC = false;
#endif

//////////////////////
// GarbageCollector //
//////////////////////

class GarbageCollector {
public:
  GarbageCollector(VM vm) :
    vm(vm), stableNodesToGC(nullptr), unstableNodesToGC(nullptr) {}

  inline
  MemoryManager& getMemoryManager();

  bool isGCRequired() {
    return getMemoryManager().isGCRequired();
  }

  void doGC();

  inline
  void gcThread(Suspendable* from, Suspendable*& to);

  inline
  void gcStableNode(StableNode& from, StableNode& to);

  inline
  void gcUnstableNode(UnstableNode& from, UnstableNode& to);

  inline
  void gcStableRef(StableNode* from, StableNode*& to);

  VM vm;
private:
  inline
  void gcOneThread(Suspendable*& thread);

  template <class NodeType, class GCedType>
  inline
  void gcOneNode(NodeType*& list);

  inline
  void gcOneStableRef(StableNode*& ref);

  MemoryManager secondMemManager;

  MemManagedList<Suspendable**> threadsToGC;
  StableNode* stableNodesToGC;
  UnstableNode* unstableNodesToGC;
  MemManagedList<StableNode**> stableRefsToGC;
};

#endif // __GCOLLECT_DECL_H
