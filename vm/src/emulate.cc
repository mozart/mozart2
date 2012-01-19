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
#include "coreinterfaces.hh"
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
  VM vm = this->vm;

  EnlargeableArray<UnstableNode>* xregs = &this->xregs;
  StaticArray<UnstableNode>* yregs = this->yregs;
  StaticArray<StableNode>* gregs = this->gregs;
  StaticArray<StableNode>* kregs = this->kregs;

  ProgramCounter PC = this->PC;

#define advancePC(argCount) do { PC += (argCount) + 1; } while (0)

#define IntPC(offset) PC[offset]

#define XPC(offset) (*xregs)[PC[offset]]
#define YPC(offset) (*yregs)[PC[offset]]
#define GPC(offset) (*gregs)[PC[offset]]
#define KPC(offset) (*kregs)[PC[offset]]

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
        XPC(1).make<Unbound>(vm);
        advancePC(1); break;
      }

      // Control

      case OpCallBuiltin: {
        int argc = PC[2];
        UnstableNode* args[argc];
        for (int i = 0; i < argc; i++)
          args[i] = &XPC(3 + i);

        BuiltinCallable x = KPC(1).node;
        BuiltinResult result = x.callBuiltin(vm, argc, args);

        if (result == BuiltinResultContinue)
          advancePC(2 + argc);
        else
          waitFor(result->node);

        break;
      }

      case OpCallX:
        call(XPC(1).node, IntPC(2), false,
             vm, PC, xregs, yregs, gregs, kregs);
        break;

      case OpCallG:
        call(GPC(1).node, IntPC(2), false,
             vm, PC, xregs, yregs, gregs, kregs);
        break;

      case OpTailCallX:
        call(XPC(1).node, IntPC(2), true,
             vm, PC, xregs, yregs, gregs, kregs);
        break;

      case OpTailCallG:
        call(GPC(1).node, IntPC(2), true,
             vm, PC, xregs, yregs, gregs, kregs);
        break;

      case OpReturn: {
        // pop frame
        assert(!stack.empty());
        StackEntry& entry = stack.top();
        area = entry.area;
        PC = entry.PC;
        yregs = entry.yregs;
        gregs = entry.gregs;
        kregs = area ? &area->getKs() : nullptr;
        stack.pop();

        if (PC == NullPC)
          return;

        break;
      }

      case OpBranch: {
        int distance = IntPC(1);
        advancePC(1 + distance);
        break;
      }

      case OpCondBranch: {
        UnstableNode& test = XPC(1);
        BoolOrNotBool testValue;

        BooleanValue testBoolValue = test.node;
        BuiltinResult result = testBoolValue.valueOrNotBool(vm, &testValue);

        if (result == BuiltinResultContinue) {
          int distance;

          switch (testValue) {
            case bFalse: distance = IntPC(2); break;
            case bTrue:  distance = IntPC(3); break;
            default:     distance = IntPC(4);
          }

          advancePC(4 + distance);
        } else {
          waitFor(result->node);
        }

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

      case OpPrint: {
        Node& arg = Reference::dereference(XPC(1).node);
        if (arg.type == SmallInt::type) {
          nativeint value = IMPLNOSELF(nativeint, SmallInt, value, &arg);
          printf("%ld\n", value);
        } else if (arg.type == Boolean::type) {
          bool value = IMPLNOSELF(bool, Boolean, value, &arg);
          printf("%s\n", value ? "True" : "False");
        } else {
          const string typeName = arg.type->getName();
          cout << "SmallInt or Boolean expected but " << typeName << " found\n";
        }
        advancePC(1); break;
      }

      // Inlines for some builtins

      case OpInlineEqualsInteger: {
        IntegerValue x = XPC(1).node;
        nativeint right = IntPC(2);
        bool resultValue;

        BuiltinResult result = x.equalsInteger(vm, right, &resultValue);

        if (result == BuiltinResultContinue) {
          if (resultValue)
            advancePC(3);
          else
            advancePC(3 + IntPC(3));
        } else {
          waitFor(result->node);
        }

        break;
      }

      case OpInlineAdd: {
        Addable x = XPC(1).node;
        BuiltinResult result = x.add(vm, &XPC(2), &XPC(3));

        if (result == BuiltinResultContinue)
          advancePC(3);
        else
          waitFor(result->node);

        break;
      }

      case OpInlineMinus1: {
        IntegerValue x = XPC(1).node;
        BuiltinResult result = x.addValue(vm, -1, &XPC(2));

        if (result == BuiltinResultContinue)
          advancePC(2);
        else
          waitFor(result->node);

        break;
      }
    }
  }

#undef advancePC
#undef IntPC
#undef XPC
#undef YPC
#undef GPC
#undef KPC
}

void Thread::call(Node& target, int actualArity, bool isTailCall,
                  VM vm, ProgramCounter& PC,
                  EnlargeableArray<UnstableNode>* xregs,
                  StaticArray<UnstableNode>*& yregs,
                  StaticArray<StableNode>*& gregs,
                  StaticArray<StableNode>*& kregs) {
  int formalArity;
  CodeArea* body;
  StaticArray<StableNode>* Gs;

  Callable x = target;
  BuiltinResult result = x.getCallInfo(vm, &formalArity, &body, &Gs);

  if (result == BuiltinResultContinue) {
    if (actualArity != formalArity) {
      cout << "Illegal arity: " << formalArity << " expected but ";
      cout << actualArity << " found" << endl;
      // TODO Raise illegal arity exception
    }

    // advancePC(2);
    PC += (2 + 1); // 1 for opcode

    if (!isTailCall) {
      // push frame
      StackEntry entry(area, PC, yregs, gregs);
      stack.push(entry);
    }

    area = body;
    PC = body->getStart();
    xregs->ensureSize(body->getXCount());
    yregs = nullptr;
    kregs = &body->getKs();
    gregs = Gs;
  } else {
    waitFor(result->node);
  }
}

void Thread::unify(Node& l, Node& r) {
  Node& left = Reference::dereference(l);
  Node& right = Reference::dereference(r);

  if (left.type == Unbound::type)
    IMPL(void, Unbound, bind, &left, vm, &right);
  else if (right.type == Unbound::type)
    IMPL(void, Unbound, bind, &right, vm, &left);
  else {
    // TODO Non-trivial unify
  }
}

void Thread::waitFor(Node& node) {
  // TODO
}
