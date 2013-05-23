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

#ifndef __GRAPHREPLICATOR_DECL_H
#define __GRAPHREPLICATOR_DECL_H

#include "core-forward-decl.hh"

#include "memmanager.hh"
#include "memmanlist.hh"

#include "store-decl.hh"
#include "runnable-decl.hh"

namespace mozart {

/////////////////////
// GraphReplicator //
/////////////////////

class GraphReplicator {
public:
  enum Kind {
    grkGarbageCollection, grkSpaceCloning, grkCustom
  };
public:
  inline
  GraphReplicator(VM vm, Kind kind);

  Kind kind() {
    return _kind;
  }

  inline
  void copySpace(SpaceRef& to, SpaceRef from);

  inline
  void copyThread(Runnable*& to, Runnable* from);

  inline
  void copyStableNode(StableNode& to, StableNode& from);

  inline
  void copyUnstableNode(UnstableNode& to, UnstableNode& from);

  inline
  void copyStableRef(StableNode*& to, StableNode* from);

  inline
  void copyWeakStableRef(StableNode*& to, StableNode* from);

  inline
  void copyStableNodes(StaticArray<StableNode> to,
                       StaticArray<StableNode> from,
                       size_t count);

  inline
  void copyUnstableNodes(StaticArray<UnstableNode> to,
                         StaticArray<UnstableNode> from,
                         size_t count);

  inline
  void copyGNode(GlobalNode*& to, GlobalNode* from);

  inline
  atom_t copyAtom(atom_t from);
protected:
  template <class Self>
  void runCopyLoop();

  MemoryManager& getSecondMM() {
    return secondMM;
  }
private:
  template <class Self>
  inline
  void processSpaceInternal(SpaceRef& space);

  template <class Self>
  inline
  void processThreadInternal(Runnable*& thread);

  template <class Self, class NodeType, class GCedType>
  inline
  void processNodeInternal(Node*& list);

  template <class Self, bool weak = false>
  inline
  void processStableRefInternal(StableNode*& ref);
public:
  VM vm;
private:
  Kind _kind;

  MemoryManager& secondMM;

  struct {
    MemManagedList<SpaceRef*> spaces;
    MemManagedList<Runnable**> threads;
    Node* stableNodes;
    Node* unstableNodes;
    MemManagedList<StableNode**> stableRefs;
    MemManagedList<StableNode**> weakStableRefs; // only for GC
  } todos;
};

}

#endif // __GRAPHREPLICATOR_DECL_H
