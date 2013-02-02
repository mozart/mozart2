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

////////////////////
// VirtualMachine //
////////////////////

VirtualMachine::run_return_type VirtualMachine::run() {
  while (!(_exitRunRequested ||
      (_envUseDynamicPreemption && environment.testDynamicExitRun()))) {

    if (_gcRequested || gc.isGCRequired()) {
      getTopLevelSpace()->install();
      doGC();
      _gcRequested = false;
    }

    // Trigger alarms
    std::int64_t now = _referenceTime;
    while (!_alarms.empty() && (_alarms.front().expiration <= now)) {
      getTopLevelSpace()->install();

      Wakeable(*_alarms.front().wakeable).wakeUp(this);

      _alarms.remove_front(this);
    }

    // Select a thread
    Runnable* currentThread;
    do {
      currentThread = threadPool.popNext();
    } while (currentThread != nullptr && currentThread->isTerminated());

    // When there is no runnable thread left, return to the external world
    if (currentThread == nullptr)
      break;

    // Install the thread's space
    if (!currentThread->getSpace()->install()) {
      // The space is failed, kill the thread now
      currentThread->kill();
      continue;
    }

    // Run the thread
    assert(currentThread->isRunnable());
    _currentThread = currentThread;
    currentThread->run();
    _currentThread = nullptr;

    _preemptRequested = false;

    // Schedule the thread anew if it is still runnable
    if (currentThread->isRunnable())
      threadPool.schedule(currentThread);
  }

  _exitRunRequested = false;

  // Before giving control to the external world, restore the top-level space
  getTopLevelSpace()->install();

  // Tell the external world in how much time I would like to be invoked again
  if (!threadPool.empty())
    return run_return_type(recInvokeAgainNow, 0);
  else if (_alarms.empty())
    return run_return_type(recNeverInvokeAgain, 0);
  else
    return run_return_type(recInvokeAgainLater, _alarms.front().expiration);
}

}
