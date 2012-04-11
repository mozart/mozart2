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

//////////////
// SpaceRef //
//////////////

Space* SpaceRef::operator->() {
  Space* result = space;
  while (result->status() == Space::ssReference)
    result = result->_reference;
  return result;
}

/////////////////
// DummyThread //
/////////////////

namespace internal {
  /**
   * Dummy thread that contains no code. It terminates as soon as it runs.
   * Moreover, it can be resumed several times without harm.
   */
  class DummyThread: public Runnable {
  private:
    typedef Runnable Super;
  public:
    DummyThread(VM vm, Space* space,
                bool createSuspended = false): Runnable(vm, space) {
      if (!createSuspended)
        resume();
    }

    DummyThread(GC gc, DummyThread& from): Runnable(gc, from) {}

    void run() {
      terminate();
    }

    void resume(bool skipSchedule = false) {
      if (!isRunnable() && !isTerminated())
        Super::resume(skipSchedule);
    }

    void suspend(bool skipUnschedule = false) {
      if (isRunnable() && !isTerminated())
        Super::suspend(skipUnschedule);
    }

    Runnable* gCollect(GC gc) {
      return new (gc->vm) DummyThread(gc, *this);
    }
  };
}

///////////
// Space //
///////////

Space::Space(GC gc, Space* from) {
  assert(from->_status != ssReference && from->_status != ssGCed);

  vm = from->vm;

  if (from->_isTopLevel)
    _parent = nullptr;
  else
    gc->gcSpace(from->_parent, _parent);

  _isTopLevel = from->_isTopLevel;
  _status = from->_status;

  _mark = false;

  gc->gcStableNode(from->_rootVar, _rootVar);
  gc->gcUnstableNode(from->_statusVar, _statusVar);

  if (from->_distributor == nullptr)
    _distributor = nullptr;
  else
    _distributor = from->_distributor->gCollect(gc);

  assert(from->trail.empty());

  for (auto iter = from->script.begin(); iter != from->script.end(); ++iter) {
    ScriptEntry& entry = script.append(gc->vm);
    gc->gcUnstableNode(iter->left, entry.left);
    gc->gcUnstableNode(iter->right, entry.right);
  }

  threadCount = from->threadCount;
  cascadedRunnableThreadCount = from->cascadedRunnableThreadCount;
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

BuiltinResult Space::merge(VM vm, Space* dest) {
  Space* src = this;

  assert(vm->getCurrentSpace() == dest);

  // Make the source a transparent ref to the destination
  src->setReference(dest);

  // Merge the thread counters
  if (!dest->isTopLevel()) {
    dest->incThreadCount(src->getThreadCount());

    if (src->cascadedRunnableThreadCount > 0)
      dest->cascadedRunnableThreadCount += src->cascadedRunnableThreadCount-1;
  }

  // Merge constraints
  bool res = src->installThis(/* isMerge = */ true);

  return res ? BuiltinResult::proceed() : BuiltinResult::failed();
}

nativeint Space::commit(VM vm, nativeint value) {
  nativeint commitResult = getDistributor()->commit(vm, this, value);

  if (commitResult >= 0) {
    clearStatusVar(vm);
    if (commitResult == 0)
      _distributor = nullptr;
  }

  return commitResult;
}

void Space::fail(VM vm) {
  failInternal(vm);
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

void Space::notifyThreadCreated() {
  incThreadCount();
}

void Space::notifyThreadTerminated() {
  if (isTopLevel())
    return;

  if (--cascadedRunnableThreadCount)
    getParent()->decRunnableThreadCount();

  checkStability();
}

void Space::notifyThreadResumed() {
  if (!isTopLevel())
    incRunnableThreadCount();
}

void Space::notifyThreadSuspended() {
  if (!isTopLevel())
    decRunnableThreadCount();
}

bool Space::isStable() {
  if (hasRunnableThreads())
    return false;

  if (!trail.empty())
    return false;

  // TODO Check suspension list

  return true;
}

bool Space::isBlocked() {
  return !hasRunnableThreads();
}

void Space::incThreadCount(int n) {
  assert(!isFailed());
  assert(n >= 0);
  threadCount += n;
}

void Space::decThreadCount() {
  assert(!isFailed());
  assert(threadCount > 0);
  threadCount--;
}

int Space::getThreadCount() {
  assert(!isFailed() && threadCount >= 0);
  return threadCount;
}

void Space::incRunnableThreadCount() {
  if (!isTopLevel()) {
    if (cascadedRunnableThreadCount++ == 0)
      getParent()->incRunnableThreadCount();
  }
}

void Space::decRunnableThreadCount() {
  if (!isTopLevel()) {
    if (--cascadedRunnableThreadCount == 0) {
      if (isStable())
        new (vm) internal::DummyThread(vm, this);

      getParent()->decRunnableThreadCount();
    }
  }
}

bool Space::hasRunnableThreads() {
  return cascadedRunnableThreadCount > 0;
}

}

#endif // __SPACE_H
