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

#ifndef __SPACE_H
#define __SPACE_H

#include "space-decl.hh"

namespace mozart {

Space* SpaceRef::operator->() {
  Space* result = space;
  while (result->status() == Space::ssReference)
    result = result->_reference;
  return result;
}

Space::Space(GC gc, Space* from) {
  assert(from->_status != ssReference && from->_status != ssGCed);

  if (from->_isTopLevel)
    _parent = nullptr;
  else
    gc->gcSpace(from->_parent, _parent);

  _isTopLevel = from->_isTopLevel;
  _status = from->_status;

  for (auto iter = from->script.begin(); iter != from->script.end(); ++iter) {
    ScriptEntry& entry = script.append(gc->vm);
    gc->gcUnstableNode(iter->left, entry.left);
    gc->gcUnstableNode(iter->right, entry.right);
  }
}

// Status

bool Space::isAlive() {
  for (Space* s = this; !s->isTopLevel(); s = s->getParent())
    if (s->isFailed())
      return false;
  return true;
}

// Admissibility

bool Space::isAdmissible(Space* currentSpace) {
  // Test the most common case first: currentSpace is the parent of this
  if (getParent() == currentSpace)
    return true;

  // Fall back on the full loop
  return !currentSpace->isAncestor(this);
}

// Relations between spaces

bool Space::isAncestor(Space* potentialAncestor) {
  for (Space* s = this; s != nullptr; s = s->getParent()) {
    if (s == potentialAncestor)
      return true;
  }

  return false;
}

// Speculative bindings

void Space::makeBackupForSpeculativeBinding(StableNode* node) {
  trail.push_back_new(vm, node, node->node);
}

// Operations

BuiltinResult Space::merge(VM vm, Space* destSpace) {
  // TODO
  return BuiltinResult::proceed();
}

// Garbage collection

Space* Space::gCollect(GC gc) {
  if (_status == ssGCed) {
    return _gced;
  } else {
    Space* result = new (gc->vm) Space(gc, this);
    _status = ssGCed;
    _gced = result;
    return result;
  }
}

// Stability detection

bool Space::isStable() {
  if (hasRunnableThreads())
    return false;

  if (!trail.empty())
    return false;

  // TODO
  return true;
}

bool Space::isBlocked() {
  return !hasRunnableThreads();
}

void Space::incSuspensionCount(int n) {
  assert(!isFailed());
  suspensionCount += n;
}

void Space::decSuspensionCount() {
  assert(!isFailed());
  assert(suspensionCount > 0);
  suspensionCount--;
}

int Space::getSuspensionCount() {
  assert(!isFailed() && suspensionCount >= 0);
  return suspensionCount;
}

void Space::incRunnableThreadCount() {
  for (Space* space = this; !space->isTopLevel();
       space = space->getParent()) {
    if ((space->cascadedRunnableThreadCount)++ > 0)
      return;
  }
}

void Space::decRunnableThreadCount() {
  for (Space* space = this; !space->isTopLevel();
       space = space->getParent()) {
    if (--(space->cascadedRunnableThreadCount) > 0)
      return;

    if (space->isStable())
      ; // TODO Inject new empty thread in space
  }
}

bool Space::hasRunnableThreads() {
  return cascadedRunnableThreadCount > 0;
}

}

#endif // __SPACE_H
