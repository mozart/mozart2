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

#include "emulate.hh"
#include <iostream>

#include "smallint.hh"
#include "corebuiltins.hh"

using namespace std;

Thread::Thread(VM vm, CodeArea *area, StaticArray<StableNode> &Gs) :
  vm(vm), xregs(InitXRegisters), yregs(nullptr), gregs(&Gs),
  kregs(&area->getKs()), PC(area->getStart()) {

  xregs.ensureSize(area->getXCount());
}

void Thread::run() {
  while (true) {
    OpCode op = *PC;

    switch (op) {
      // SKIP

      case OpSkip:
        advancePC(0); break;

      // MOVES

      case OpMoveXX:
        XPC(2).copy(XPC(1));
        advancePC(2); break;

      case OpMoveXY:
        YPC(2).copy(XPC(1));
        advancePC(2); break;

      case OpMoveYX:
        XPC(2).copy(YPC(1));
        advancePC(2); break;

      case OpMoveYY:
        YPC(2).copy(YPC(1));
        advancePC(2); break;

      case OpMoveGX:
        XPC(2).copy(GPC(1));
        advancePC(2); break;

      case OpMoveGY:
        YPC(2).copy(GPC(1));
        advancePC(2); break;

      case OpMoveKX:
        XPC(2).copy(KPC(1));
        advancePC(2); break;

      case OpMoveKY:
        YPC(2).copy(KPC(1));
        advancePC(2); break;

      // Control

      case OpStop:
        return;

      case OpCall: {
        UnstableNode& callable = XPC(1);
        int argc = PC[2];
        UnstableNode* args[argc];
        for (int i = 0; i < argc; i++)
          args[i] = &XPC(3 + i);

        BuiltinResult result = builtins::call(vm, callable, argc, args);
        if (result == BuiltinResultContinue)
          advancePC(2 + argc);
        else
          waitFor(result->node);
      }

      // Hard-coded stuff

      case OpPrintInt: {
        UnstableNode& arg = XPC(1);
        if (arg.node.type == SmallInt::type) {
          nativeint value = arg.node.value.get<nativeint>();
          printf("%ld\n", value);
        } else {
          const string& typeName = arg.node.type->getName();
          printf("SmallInt expected but %s found\n", typeName.c_str());
        }
        advancePC(1); break;
      }
    }
  }
}

void Thread::waitFor(Node& node) {
  // TODO
}
