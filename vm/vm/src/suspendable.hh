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

#ifndef __SUSPENDABLE_HH
#define __SUSPENDABLE_HH

// This enum is often used for indexing in arrays
// tpCount reflects the number of valid ThreadPriority's
// And you probably don't want to add or remove existing ThreadPriority's
enum ThreadPriority {
  tpLow, tpMiddle, tpHi,
  tpCount
};

class Thread;

class Suspendable {
public:
  Suspendable(ThreadPriority priority = tpMiddle) :
    _priority(priority), _runnable(true), _terminated(false) {}

  ThreadPriority getPriority() { return _priority; }

  virtual void run() = 0;

  bool isTerminated() { return _terminated; }
  bool isRunnable() { return _runnable; }

  void setRunnable() { _runnable = true; }
  void unsetRunnable() { _runnable = false; }
protected:
  void terminate() {
    _runnable = false;
    _terminated = true;
  }
private:
  ThreadPriority _priority;

  bool _runnable;
  bool _terminated;
};

#endif /* __SUSPENDABLE_HH */
