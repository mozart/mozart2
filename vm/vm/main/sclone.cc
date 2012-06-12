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

namespace mozart {

/////////////////
// SpaceCloner //
/////////////////

Space* SpaceCloner::doCloneSpace(Space* space) {
  // Mark the ancestors of space as not-to-be-cloned
  space->getParent()->setShouldNotBeCloned();

  // Before GR
  vm->beforeGR(this);

  // Initialize the MM
  getSecondMM().init();

  // Root of SC is the given space
  SpaceRef spaceRef = space;
  SpaceRef copy;
  copySpace(copy, spaceRef);

  // SC loop
  runCopyLoop<SpaceCloner>();

  // Restore spaces
  while (!spaceBackups.empty()) {
    spaceBackups.front()->restoreAfterGR();
    spaceBackups.remove_front(getSecondMM());
  }

  // Restore threads
  while (!threadBackups.empty()) {
    threadBackups.front()->restoreAfterGR();
    threadBackups.remove_front(getSecondMM());
  }

  // Restore nodes
  while (!nodeBackups.empty()) {
    nodeBackups.front().restore();
    nodeBackups.remove_front(getSecondMM());
  }

  // After GR
  vm->afterGR(this);

  // Clear shouldBeCloned
  space->getParent()->unsetShouldNotBeCloned();

  return copy;
}

void SpaceCloner::processThread(Runnable*& to, Runnable* from) {
  to = from->sCloneOuter(this);

  if (to != from)
    threadBackups.push_back(getSecondMM(), from);
}

template <class NodeType, class GCedType>
void SpaceCloner::processNode(NodeType*& to, RichNode from) {
  from.type()->sClone(this, from, *to);

  if ((from.type() != GCedToStable::type()) &&
      (from.type() != GCedToUnstable::type())) {
    nodeBackups.push_front(getSecondMM(), from.makeBackup());
    from.remake<GCedType>(vm, to);
  }
}

}
