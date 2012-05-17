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

#ifndef __REIFIEDTHREAD_H
#define __REIFIEDTHREAD_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

///////////////////
// ReifiedThread //
///////////////////

#include "ReifiedThread-implem.hh"

void ReifiedThreadBase::gCollect(GC gc, RichNode from, StableNode& to) const {
  Runnable* runnable = from.as<ReifiedThread>().getRunnable();
  to.make<ReifiedThread>(gc->vm, runnable->gCollectOuter(gc));
}

void ReifiedThreadBase::gCollect(GC gc, RichNode from, UnstableNode& to) const {
  Runnable* runnable = from.as<ReifiedThread>().getRunnable();
  to.make<ReifiedThread>(gc->vm, runnable->gCollectOuter(gc));
}

void ReifiedThreadBase::sClone(SC sc, RichNode from, StableNode& to) const {
  Runnable* runnable = from.as<ReifiedThread>().getRunnable();
  to.make<ReifiedThread>(sc->vm, runnable->sCloneOuter(sc));
}

void ReifiedThreadBase::sClone(SC sc, RichNode from, UnstableNode& to) const {
  Runnable* runnable = from.as<ReifiedThread>().getRunnable();
  to.make<ReifiedThread>(sc->vm, runnable->sCloneOuter(sc));
}

bool Implementation<ReifiedThread>::equals(VM vm, Self right) {
  return _runnable == right.get()._runnable;
}

OpResult Implementation<ReifiedThread>::wakeUp(VM vm) {
  _runnable->resume();
  return OpResult::proceed();
}

bool Implementation<ReifiedThread>::shouldWakeUpUnderSpace(VM vm,
                                                           Space* space) {
  return _runnable->getSpace()->isAncestor(space);
}

OpResult Implementation<ReifiedThread>::isThread(VM vm, UnstableNode& result) {
  result.make<Boolean>(vm, true);
  return OpResult::proceed();
}

OpResult Implementation<ReifiedThread>::getThreadPriority(
  VM vm, ThreadPriority& result) {

  result = _runnable->getPriority();
  return OpResult::proceed();
}

OpResult Implementation<ReifiedThread>::setThreadPriority(
  VM vm, ThreadPriority priority) {

  _runnable->setPriority(priority);
  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __REIFIEDTHREAD_H
