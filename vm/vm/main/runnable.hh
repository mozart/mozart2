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

#include "runnable-decl.hh"
#include "vm-decl.hh"
#include "space-decl.hh"

namespace mozart {

Runnable::Runnable(VM vm, Space* space, ThreadPriority priority) :
  vm(vm), _space(space), _priority(priority),
  _runnable(false), _terminated(false), _dead(false) {

  _space->notifyThreadCreated();

  vm->aliveThreads.insert(this);
}

Runnable::Runnable(GC gc, Runnable& from) :
  vm(gc->vm) {

  gc->gcSpace(from._space, _space);
  _priority = from._priority;
  _runnable = from._runnable;
  _terminated = from._terminated;
  _dead = from._dead;

  vm->aliveThreads.insert(this);
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

void Runnable::kill() {
  dispose();
}

void Runnable::terminate() {
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

#endif // __RUNNABLE_H
