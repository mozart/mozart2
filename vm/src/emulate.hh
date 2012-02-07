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
#include <assert.h>

#include "arrays.hh"
#include "opcodes.hh"
#include "store.hh"
#include "ozlimits.hh"
#include "codearea.hh"
#include "suspendable.hh"

/**
 * Entry of a thread stack
 */
struct StackEntry {
  StackEntry(StableNode* abstraction, ProgramCounter PC,
    StaticArray<UnstableNode>* yregs, StaticArray<StableNode>* gregs,
    StaticArray<StableNode>* kregs) :
    abstraction(abstraction),  PC(PC),
    yregs(yregs), gregs(gregs), kregs(kregs) {}

  StableNode* abstraction;
  ProgramCounter PC;
  StaticArray<UnstableNode>* yregs;
  StaticArray<StableNode>* gregs;
  StaticArray<StableNode>* kregs;
};

/** Thread stack */
typedef stack<StackEntry> ThreadStack;

/**
 * Lightweight thread.
 * The Thread class contains the information about the execution of a
 * lightweight thread. It contains the main emulator loop.
 */
class Thread : public Suspendable {
public:
  Thread(VM vm, StableNode* abstraction);

  void run();
private:
  inline
  void pushFrame(VM vm, StableNode* abstraction,
                 ProgramCounter PC,
                 StaticArray<UnstableNode>* yregs,
                 StaticArray<StableNode>* gregs,
                 StaticArray<StableNode>* kregs);

  inline
  void popFrame(VM vm, StableNode*& abstraction,
                ProgramCounter& PC,
                StaticArray<UnstableNode>*& yregs,
                StaticArray<StableNode>*& gregs,
                StaticArray<StableNode>*& kregs);

  inline
  void call(StableNode* target, int actualArity, bool isTailCall,
            VM vm, StableNode*& abstraction,
            ProgramCounter& PC,
            EnlargeableArray<UnstableNode>* xregs,
            StaticArray<UnstableNode>*& yregs,
            StaticArray<StableNode>*& gregs,
            StaticArray<StableNode>*& kregs,
            bool& preempted);

  inline
  void unify(Node& l, Node& r);

  void waitFor(Node& node);

  VM vm;

  EnlargeableArray<UnstableNode> xregs;
  ThreadStack stack;
};

#endif // __EMULATE_H
