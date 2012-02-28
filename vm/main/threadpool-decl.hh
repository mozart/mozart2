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

#ifndef __THREADPOOL_DECL_H
#define __THREADPOOL_DECL_H

#include <queue>

#include "core-forward-decl.hh"
#include "suspendable-decl.hh"

/////////////////
// ThreadQueue //
/////////////////

class ThreadQueue : public std::queue<Suspendable*> {
public:
  void remove(Suspendable* item) {
    for (auto iterator = c.begin(); iterator != c.end(); iterator++) {
      if (*iterator == item) {
        c.erase(iterator);
        return;
      }
    }
  }

  // Implemented in gcollect.hh
  inline
  void gCollect(GC gc);
};

////////////////
// ThreadPool //
////////////////

const int HiToMiddlePriorityRatio = 10;
const int MiddleToLowPriorityRatio = 10;

class ThreadPool {
public:
  ThreadPool() {
    remainings[tpLow] = 0;
    remainings[tpMiddle] = 0;
    remainings[tpHi] = 0;
  }

  bool empty() {
    // ordered from most probably non-empty too most probably empty
    return empty(tpMiddle) && empty(tpHi) && empty(tpLow);
  }

  void schedule(Suspendable* thread) {
    queues[thread->getPriority()].push(thread);
  }

  void unschedule(Suspendable* thread) {
    queues[tpLow].remove(thread);
    queues[tpMiddle].remove(thread);
    queues[tpHi].remove(thread);
  }

  void reschedule(Suspendable* thread) {
    unschedule(thread);
    schedule(thread);
  }

  void gCollect(GC gc) {
    queues[tpLow].gCollect(gc);
    queues[tpMiddle].gCollect(gc);
    queues[tpHi].gCollect(gc);
  }

  inline
  Suspendable* popNext();
private:
  bool empty(ThreadPriority priority) {
    return queues[priority].empty();
  }

  inline
  Suspendable* popNext(ThreadPriority priority);

  ThreadQueue queues[tpCount];
  int remainings[tpCount];
};

#endif // __THREADPOOL_DECL_H
