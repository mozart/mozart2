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

#ifndef __VM_H
#define __VM_H

#include <stdlib.h>

#include "store.hh"
#include "threadpool.hh"

typedef bool (*PreemptionTest)(void* data);

class VirtualMachine {
public:
  VirtualMachine(PreemptionTest preemptionTest,
                 void* preemptionTestData = nullptr) :
    _preemptionTest(preemptionTest), _preemptionTestData(preemptionTestData) {}

  StableNode* newVariable();

  void run();

  inline
  bool testPreemption();

  ThreadPool& getThreadPool() { return threadPool; }
private:
  friend class Thread;

  VirtualMachine(const VirtualMachine& src) {}

  friend void* operator new (size_t size, VM vm);
  friend void* operator new[] (size_t size, VM vm);

  void* malloc(size_t size) {
    return ::malloc(size);
  }

  // Called from the constructor of Thread
  void scheduleThread(Thread* thread);

  ThreadPool threadPool;

  PreemptionTest _preemptionTest;
  void* _preemptionTestData;
};

void* operator new (size_t size, VM vm) {
  return vm->malloc(size);
}

void* operator new[] (size_t size, VM vm) {
  return vm->malloc(size);
}

///////////////////////////
// Inline VirtualMachine //
///////////////////////////

bool VirtualMachine::testPreemption() {
  return _preemptionTest(_preemptionTestData);
}

#endif // __VM_H
