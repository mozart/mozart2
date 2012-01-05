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

#include "arrays.hh"
#include "opcodes.hh"
#include "memword.hh"
#include "store.hh"
#include "ozlimits.hh"
#include "codearea.hh"

/**
 * Result of the call to a builtin.
 * It always represents a node that must be waited upon. The value 'nullptr' is
 * valid, and denotes that no value must be waited upon, i.e., the execution can
 * continue.
 * Throwing an exception is achieved by pointing to a failed value.
 */
typedef StableNode* BuiltinResult;

const BuiltinResult BuiltinResultContinue = nullptr;

/**
 * Lightweight thread.
 * The Thread class contains the information about the execution of a
 * lightweight thread. It contains the main emulator loop.
 */
class Thread {
public:
  Thread(VM vm, CodeArea *area, StaticArray<StableNode> &Gs,
    StaticArray<StableNode> &Ks);

  void run();
private:
  void advancePC(int argCount) { PC += argCount + 1; } // 1 for opcode

  UnstableNode &XPC(int offset) { return xregs[PC[offset]]; }
  UnstableNode &YPC(int offset) { return (*yregs)[PC[offset]]; }
  StableNode &GPC(int offset) { return (*gregs)[PC[offset]]; }
  StableNode &KPC(int offset) { return (*kregs)[PC[offset]]; }

  void waitFor(Node& node);

  VM vm;
  EnlargeableArray<UnstableNode> xregs;
  StaticArray<UnstableNode> *yregs;
  StaticArray<StableNode> *gregs;
  StaticArray<StableNode> *kregs;

  ProgramCounter PC;
};

#endif // __EMULATE_H
