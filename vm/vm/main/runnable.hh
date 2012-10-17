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

#ifndef __RUNNABLE_H
#define __RUNNABLE_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

Runnable::Runnable(VM vm, Space* space, ThreadPriority priority) :
  vm(vm), _space(space), _priority(priority),
  _runnable(false), _terminated(false), _dead(false),
  _raiseOnBlock(false),
  _replicate(nullptr) {

  _reification.init(vm, ReifiedThread::build(vm, this));

  _intermediateState.init(vm, Unit::build(vm));

  _space->notifyThreadCreated();

  vm->aliveThreads.insert(this);
}

Runnable::Runnable(GR gr, Runnable& from) :
  vm(gr->vm), _replicate(nullptr) {

  gr->copySpace(_space, from._space);
  _priority = from._priority;
  _runnable = from._runnable;
  _terminated = from._terminated;
  _dead = from._dead;

  _raiseOnBlock = from._raiseOnBlock;

  _reification.init(vm, ReifiedThread::build(vm, this));

  gr->copyUnstableNode(_intermediateState, from._intermediateState);

  if (!_dead)
    vm->aliveThreads.insert(this);
}

void Runnable::setPriority(ThreadPriority priority) {
  if (priority != _priority) {
    _priority = priority;

    if (_runnable && vm->getCurrentThread() != this)
      vm->threadPool.reschedule(this);
  }
}

void Runnable::resume(bool skipSchedule) {
  assert(!_dead && !_terminated);
  assert(!_runnable);

  _runnable = true;
  _space->notifyThreadResumed();

  if (!skipSchedule)
    vm->getThreadPool().schedule(this);
}

void Runnable::suspend(bool skipUnschedule) {
  assert(!_dead && !_terminated);
  assert(_runnable);

  _runnable = false;
  _space->notifyThreadSuspended();

  if (!skipUnschedule)
    vm->getThreadPool().unschedule(this);
}

void Runnable::suspendOnVar(VM vm, RichNode variable, bool skipUnschedule) {
  assert(variable.isTransient() && !variable.is<FailedValue>());

  suspend(skipUnschedule);

  DataflowVariable(variable).addToSuspendList(vm, _reification);
}

void Runnable::kill() {
  assert(!_dead && !_terminated);

  dispose();
}

Runnable* Runnable::gCollectOuter(GC gc) {
  if (_replicate != nullptr) {
    return _replicate;
  } else {
    _replicate = gCollect(gc);
    return _replicate;
  }
}

Runnable* Runnable::sCloneOuter(SC sc) {
  if (_replicate != nullptr) {
    return _replicate;
  } else if (getSpace()->shouldBeCloned()) {
    _replicate = sClone(sc);
    return _replicate;
  } else {
    return this;
  }
}

void Runnable::restoreAfterGR() {
  _replicate = nullptr;
}

void Runnable::terminate() {
  assert(!_dead && !_terminated);
  assert(_runnable);

  _runnable = false;
  _terminated = true;

  _space->notifyThreadTerminated();

  dispose();
}

void Runnable::dispose() {
  _runnable = false;
  _dead = true;

  vm->aliveThreads.remove(this);
}

}

#endif // MOZART_GENERATOR

#endif // __RUNNABLE_H
