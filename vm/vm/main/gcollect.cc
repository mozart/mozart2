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

#include "mozart.hh"

#include <iostream>

namespace mozart {

//////////////////////
// GarbageCollector //
//////////////////////

void GarbageCollector::doGC() {
  if (OzDebugGC) {
    std::cerr << "Before GC: " << vm->getMemoryManager().getAllocated();
    std::cerr << " bytes used." << std::endl;
  }

  // General assumptions when running GC
  assert(vm->_currentSpace == vm->_topLevelSpace);

  // Before GR
  for (auto iterator = vm->aliveThreads.begin();
       iterator != vm->aliveThreads.end(); iterator++) {
    (*iterator)->beforeGR();
  }

  // Swap spaces
  vm->getMemoryManager().swapWith(vm->getSecondMemoryManager());
  vm->getMemoryManager().init();

  // Forget lists of things
  vm->atomTable = AtomTable();
  vm->aliveThreads = RunnableList();

  // Always keep the top-level space
  SpaceRef topLevelSpaceRef = vm->_topLevelSpace;
  copySpace(topLevelSpaceRef, topLevelSpaceRef);
  vm->_topLevelSpace = topLevelSpaceRef;
  vm->_currentSpace = vm->_topLevelSpace;

  // Root of GC are runnable threads
  vm->getThreadPool().gCollect(this);

  // GC loop
  runCopyLoop<GarbageCollector>();

  // After GR
  for (auto iterator = vm->aliveThreads.begin();
       iterator != vm->aliveThreads.end(); iterator++) {
    (*iterator)->afterGR();
  }

  if (OzDebugGC) {
    std::cerr << "After GC: " << vm->getMemoryManager().getAllocated();
    std::cerr << " bytes used." << std::endl;
  }
}

void GarbageCollector::processThread(Runnable*& to, Runnable* from) {
  to = from->gCollect(this);
}

template <class NodeType, class GCedType>
void GarbageCollector::processNode(NodeType*& to, RichNode from) {
  from.type()->gCollect(this, from, *to);
  from.remake<GCedType>(vm, to);
}

}
