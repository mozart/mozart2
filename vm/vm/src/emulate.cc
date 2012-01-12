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
#include <assert.h>

#include "smallint.hh"
#include "corebuiltins.hh"
#include "vm.hh"
#include "variables.hh"

using namespace std;

const ProgramCounter NullPC = nullptr;

Thread::Thread(VM vm, CodeArea *area, StaticArray<StableNode> &Gs) :
  vm(vm), area(area), xregs(InitXRegisters), yregs(nullptr), gregs(&Gs),
  kregs(&area->getKs()), PC(area->getStart()) {

  xregs.ensureSize(area->getXCount());

  StackEntry stopEntry(nullptr, NullPC, nullptr, nullptr);
  stack.push(stopEntry);
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
        XPC(2).copy(vm, XPC(1));
        advancePC(2); break;

      case OpMoveXY:
        YPC(2).copy(vm, XPC(1));
        advancePC(2); break;

      case OpMoveYX:
        XPC(2).copy(vm, YPC(1));
        advancePC(2); break;

      case OpMoveYY:
        YPC(2).copy(vm, YPC(1));
        advancePC(2); break;

      case OpMoveGX:
        XPC(2).copy(vm, GPC(1));
        advancePC(2); break;

      case OpMoveGY:
        YPC(2).copy(vm, GPC(1));
        advancePC(2); break;

      case OpMoveKX:
        XPC(2).copy(vm, KPC(1));
        advancePC(2); break;

      case OpMoveKY:
        YPC(2).copy(vm, KPC(1));
        advancePC(2); break;

      // Y allocations

      case OpAllocateY: {
        int count = IntPC(1);
        assert(count > 0);
        assert(yregs == nullptr); // Duplicate AllocateY
        yregs = new StaticArray<UnstableNode>(count);
        advancePC(1); break;
      }

      case OpDeallocateY: {
        assert(yregs != nullptr); // Duplicate DeallocateY
        delete yregs;
        yregs = nullptr;
        advancePC(0); break;
      }

      // Variable allocation

      case OpCreateVar: {
        XPC(1).make<Unbound::Repr>(vm, Unbound::type, Unbound::value);
        advancePC(1); break;
      }

      // Control

      case OpStop:
        return;

      case OpCallBuiltin: {
        UnstableNode& callable = XPC(1);
        int argc = PC[2];
        UnstableNode* args[argc];
        for (int i = 0; i < argc; i++)
          args[i] = &XPC(3 + i);

        BuiltinResult result = builtins::callBuiltin(vm, callable, argc, args);
        if (result == BuiltinResultContinue)
          advancePC(2 + argc);
        else
          waitFor(result->node);

        break;
      }

      case OpCall:
      case OpTailCall: {
        UnstableNode& callable = XPC(1);
        int actualArity = IntPC(2);

        int formalArity;
        CodeArea* body;
        StaticArray<StableNode>* Gs;

        BuiltinResult result = builtins::getCallInfo(vm, callable,
          formalArity, body, Gs);

        if (result == BuiltinResultContinue) {
          if (actualArity != formalArity) {
            // TODO Raise illegal arity exception
          }

          advancePC(2);

          if (op != OpTailCall)
            pushFrame();

          area = body;
          PC = body->getStart();
          xregs.ensureSize(body->getXCount());
          yregs = nullptr;
          kregs = &body->getKs();
          gregs = Gs;
        } else {
          waitFor(result->node);
        }

        break;
      }

      case OpReturn: {
        popFrame();
        if (PC == NullPC)
          return;

        break;
      }

      // Unification

      case OpUnifyXX:
        unify(XPC(1).node, XPC(2).node);
        advancePC(2); break;

      case OpUnifyXY:
        unify(XPC(1).node, YPC(2).node);
        advancePC(2); break;

      case OpUnifyXK:
        unify(XPC(1).node, KPC(2).node);
        advancePC(2); break;

      case OpUnifyXG:
        unify(XPC(1).node, GPC(2).node);
        advancePC(2); break;

      // Hard-coded stuff

      case OpPrintInt: {
        Node& arg = Reference::dereference(XPC(1).node);
        if (arg.type == SmallInt::type) {
          nativeint value = arg.value.get<nativeint>();
          printf("%ld\n", value);
        } else {
          const string typeName = arg.type->getName();
          cout << "SmallInt expected but " << typeName << " found\n";
        }
        advancePC(1); break;
      }
    }
  }
}

void Thread::waitFor(Node& node) {
  // TODO
}
