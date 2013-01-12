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

#ifndef __THREADPOOL_H
#define __THREADPOOL_H

#include "mozartcore.hh"

namespace mozart {

/////////////////
// ThreadQueue //
/////////////////

void ThreadQueue::gCollect(GC gc) {
  for (auto iterator = c.begin(); iterator != c.end(); iterator++) {
    Runnable*& thread = *iterator;
    gc->copyThread(thread, thread);
  }
}

void ThreadQueue::dump() {
  for (auto iterator = c.begin(); iterator != c.end(); iterator++) {
    Runnable* runnable = *iterator;
    runnable->dump();
  }
}

////////////////
// ThreadPool //
////////////////

Runnable* ThreadPool::popNext() {
  do {
    // While remainings[tpHi] > 0, return the first Hi-priority thread
    if (!queues[tpHi].empty() && remainings[tpHi] > 0) {
      remainings[tpHi]--;
      return popNext(tpHi);
    }

    // Reset remainings[tpHi] for subsequent calls
    remainings[tpHi] = HiToMiddlePriorityRatio;

    // While remainings[tpMiddle] > 0, return the first Middle-priority thread
    if (!queues[tpMiddle].empty() && remainings[tpMiddle] > 0) {
      remainings[tpMiddle]--;
      return popNext(tpMiddle);
    }

    // Reset remainings[tpMiddle] for subsequent calls
    remainings[tpMiddle] = MiddleToLowPriorityRatio;

    // remainings[tpLow] is not used, always return the first Low-priority thread
    if (!queues[tpLow].empty()) {
      return popNext(tpLow);
    }
  } while (!empty()); // might not be empty if all remainings were 0

  return nullptr;
}

Runnable* ThreadPool::popNext(ThreadPriority priority) {
  Runnable* result = queues[priority].front();
  queues[priority].pop();
  return result;
}

}

#endif // __THREADPOOL_H
