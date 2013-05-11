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

void ReifiedThread::create(Runnable*& self, VM vm, GR gr, ReifiedThread from) {
  gr->copyThread(self, from._runnable);
}

bool ReifiedThread::equals(VM vm, RichNode right) {
  return value() == right.as<ReifiedThread>().value();
}

void ReifiedThread::wakeUp(VM vm) {
  if (!_runnable->isRunnable())
    _runnable->resume();
}

bool ReifiedThread::shouldWakeUpUnderSpace(VM vm, Space* space) {
  return _runnable->getSpace()->isAncestor(space);
}

ThreadPriority ReifiedThread::getThreadPriority(VM vm) {
  return _runnable->getPriority();
}

void ReifiedThread::setThreadPriority(VM vm, ThreadPriority priority) {
  _runnable->setPriority(priority);
}

void ReifiedThread::injectException(VM vm, RichNode exception) {
  _runnable->injectException(exception.getStableRef(vm));
}

}

#endif // MOZART_GENERATOR

#endif // __REIFIEDTHREAD_H
