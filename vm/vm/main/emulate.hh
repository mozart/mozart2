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

#include <stack>
#include <cassert>

#include "mozartcore.hh"

#include "arrays.hh"
#include "opcodes.hh"
#include "ozlimits.hh"
#include "codearea.hh"
#include "runnable.hh"
#include "smallint.hh"

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
  StackEntry(GC gc, StackEntry& from);

  inline
  void beforeGC(VM vm);

  inline
  void afterGC(VM vm);

  StableNode* abstraction;

  union {
    ProgramCounter PC;       // Normal
    std::ptrdiff_t PCOffset; // During GC
  };

  size_t yregCount;
  StaticArray<UnstableNode> yregs;

  StaticArray<StableNode> gregs; // Irrelevant during GC
  StaticArray<StableNode> kregs; // Irrelevant during GC
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
      _array[i] = oldArray[i];

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
public:
  Thread(VM vm, StableNode* abstraction);

  inline
  Thread(GC gc, Thread& from);

  void run();

  void beforeGC();
  void afterGC();

  Runnable* gCollect(GC gc);
protected:
  void terminate() {
    Runnable::terminate();
    xregs.release(vm);
  }
private:
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

  inline
  void call(StableNode* target, int actualArity, bool isTailCall,
            VM vm, StableNode*& abstraction,
            ProgramCounter& PC, size_t& yregCount,
            XRegArray* xregs,
            StaticArray<UnstableNode>& yregs,
            StaticArray<StableNode>& gregs,
            StaticArray<StableNode>& kregs,
            bool& preempted);

  inline
  BuiltinResult unify(VM vm, Node& l, Node& r);

  inline
  void arrayInitElement(Node& node, size_t index, UnstableNode* value,
                        VM vm, ProgramCounter& PC, bool& preempted);

  void waitFor(VM vm, Node* node, bool& preempted);

  XRegArray xregs;
  VMAllocatedList<StackEntry> stack;
};

#endif // __EMULATE_H
