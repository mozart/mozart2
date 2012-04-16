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

#ifndef __EMULATE_H
#define __EMULATE_H

#include "mozartcore.hh"

#include "ozlimits.hh"

#include <utility>
#include <stack>
#include <cassert>

namespace mozart {

/**
 * Entry of a thread stack
 */
struct StackEntry {
  StackEntry(StableNode* abstraction, ProgramCounter PC, size_t yregCount,
    StaticArray<UnstableNode> yregs, StaticArray<StableNode> gregs,
    StaticArray<StableNode> kregs) :
    abstraction(abstraction), PC(PC), yregCount(yregCount),
    yregs(yregs), gregs(gregs), kregs(kregs) {}

  inline
  StackEntry(GR gr, StackEntry& from);

  inline
  void beforeGR(VM vm);

  inline
  void afterGR(VM vm);

  StableNode* abstraction;

  union {
    ProgramCounter PC;       // Normal
    std::ptrdiff_t PCOffset; // During GR
  };

  size_t yregCount;
  StaticArray<UnstableNode> yregs;

  StaticArray<StableNode> gregs; // Irrelevant during GR
  StaticArray<StableNode> kregs; // Irrelevant during GR
};

class XRegArray {
public:
  XRegArray() : _array(nullptr, 0), _size(0) {}

  void init(VM vm, size_t initialSize) {
    assert(_array == nullptr);
    allocArray(vm, initialSize);

    for (size_t i = 0; i < initialSize; i++)
      _array[i].make<SmallInt>(vm, 0);
  }

  void grow(VM vm, size_t newSize, size_t elemsToKeep) {
    if (newSize <= _size)
      return;

    StaticArray<UnstableNode> oldArray = _array;
    size_t oldSize = _size;

    allocArray(vm, newSize);

    for (size_t i = 0; i < elemsToKeep; i++)
      _array[i] = std::move(oldArray[i]); // freed just below, so that's OK

    freeArray(vm, oldArray, oldSize);

    for (size_t i = elemsToKeep; i < newSize; i++)
      _array[i].make<SmallInt>(vm, 0);
  }

  void release(VM vm) {
    freeArray(vm, _array, _size);
    _array = nullptr;
    _size = 0;
  }

  size_t size() {
    return _size;
  }

  UnstableNode& operator[](size_t index) {
    return _array[index];
  }
private:
  void allocArray(VM vm, size_t size) {
    _array = vm->newStaticArray<UnstableNode>(size);
    _size = size;
  }

  void freeArray(VM vm, StaticArray<UnstableNode> array, size_t size) {
    vm->deleteStaticArray<UnstableNode>(array, size);
  }

  StaticArray<UnstableNode> _array;
  size_t _size;
};

/**
 * Lightweight thread.
 * The Thread class contains the information about the execution of a
 * lightweight thread. It contains the main emulator loop.
 */
class Thread : public Runnable {
private:
  typedef Runnable Super;
public:
  Thread(VM vm, Space* space, StableNode* abstraction,
         bool createSuspended = false);

  Thread(VM vm, Space* space, StableNode* abstraction,
         size_t argc, UnstableNode* args[],
         bool createSuspended = false);

  inline
  Thread(GR gr, Thread& from);

  void run();

  void kill() {
    Super::kill();
  }

  void beforeGR();
  void afterGR();

  Runnable* gCollect(GC gc);
  Runnable* sClone(SC sc);
protected:
  void terminate() {
    Super::terminate();
  }

  void dispose() {
    xregs.release(vm);

    while (!stack.empty()) {
      StackEntry& entry = stack.front();
      if (entry.yregCount != 0)
        vm->deleteStaticArray<UnstableNode>(entry.yregs, entry.yregCount);
      stack.remove_front(vm);
    }

    Super::dispose();
  }
private:
  inline
  void constructor(VM vm, StableNode* abstraction,
                   size_t argc, UnstableNode* args[],
                   bool createSuspended);

  inline
  void pushFrame(VM vm, StableNode* abstraction,
                 ProgramCounter PC, size_t yregCount,
                 StaticArray<UnstableNode> yregs,
                 StaticArray<StableNode> gregs,
                 StaticArray<StableNode> kregs);

  inline
  void popFrame(VM vm, StableNode*& abstraction,
                ProgramCounter& PC, size_t& yregCount,
                StaticArray<UnstableNode>& yregs,
                StaticArray<StableNode>& gregs,
                StaticArray<StableNode>& kregs);

  __attribute__((always_inline))
  inline
  void call(RichNode target, int actualArity, bool isTailCall,
            VM vm, StableNode*& abstraction,
            ProgramCounter& PC, size_t& yregCount,
            XRegArray* xregs,
            StaticArray<UnstableNode>& yregs,
            StaticArray<StableNode>& gregs,
            StaticArray<StableNode>& kregs,
            bool& preempted);

  void applyOpResult(VM vm, OpResult result, bool& preempted);

  XRegArray xregs;
  VMAllocatedList<StackEntry> stack;
};

}

#endif // __EMULATE_H
