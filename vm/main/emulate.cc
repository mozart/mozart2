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

#include <iostream>
#include <cassert>

namespace mozart {

const ProgramCounter NullPC = nullptr;

////////////////
// StackEntry //
////////////////

StackEntry::StackEntry(GR gr, StackEntry& from) {
  gr->copyStableRef(abstraction, from.abstraction);
  PCOffset = from.PCOffset;
  yregCount = from.yregCount;

  if (yregCount == 0)
    yregs = nullptr;
  else {
    yregs = gr->vm->newStaticArray<UnstableNode>(yregCount);
    for (size_t i = 0; i < yregCount; i++)
      gr->copyUnstableNode(yregs[i], from.yregs[i]);
  }

  // gregs and kregs are irrelevant
}

void StackEntry::beforeGR(VM vm) {
  int arity;
  StableNode* body;
  ProgramCounter start = nullptr;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  UnstableNode temp(vm, *abstraction);
  Callable(temp).getCallInfo(vm, &arity, &body, &start, &Xcount, &Gs, &Ks);

  PCOffset = PC - start;
}

void StackEntry::afterGR(VM vm) {
  int arity;
  StableNode* body;
  ProgramCounter start = nullptr;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  UnstableNode temp(vm, *abstraction);
  Callable(temp).getCallInfo(vm, &arity, &body, &start, &Xcount, &Gs, &Ks);

  PC = start + PCOffset;
  gregs = Gs;
  kregs = Ks;
}

////////////
// Thread //
////////////

Thread::Thread(VM vm, Space* space, StableNode* abstraction,
               bool createSuspended): Runnable(vm, space) {
  constructor(vm, abstraction, 0, nullptr, createSuspended);
}

Thread::Thread(VM vm, Space* space, StableNode* abstraction,
               size_t argc, UnstableNode* args[],
               bool createSuspended): Runnable(vm, space) {
  constructor(vm, abstraction, argc, args, createSuspended);
}

void Thread::constructor(VM vm, StableNode* abstraction,
                         size_t argc, UnstableNode* args[],
                         bool createSuspended) {
  // getCallInfo

  int arity;
  StableNode* body;
  ProgramCounter start = nullptr;
  int Xcount = 0;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  UnstableNode temp(vm, *abstraction);
  MOZART_ASSERT_PROCEED(Callable(temp).getCallInfo(
    vm, &arity, &body, &start, &Xcount, &Gs, &Ks));

  assert(arity == argc);

  // Set up

  xregs.init(vm, std::max(Xcount, InitXRegisters));

  for (size_t i = 0; i < argc; i++)
    xregs[i].copy(vm, *args[i]);

  pushFrame(vm, abstraction, start, 0, nullptr, Gs, Ks);

  // Resume the thread unless createSuspended
  if (!createSuspended)
    resume();
}

Thread::Thread(GR gr, Thread& from): Runnable(gr, from) {
  // X registers

  size_t Xcount = from.xregs.size();
  xregs.init(vm, Xcount);
  for (size_t i = 0; i < Xcount; i++)
    gr->copyUnstableNode(xregs[i], from.xregs[i]);

  // Stack frame

  for (auto iterator = from.stack.begin();
       iterator != from.stack.end(); iterator++) {
    stack.push_back_new(vm, gr, *iterator);
  }
}

#define CHECK_OPRESULT_BREAK(operation) \
  { \
    ::mozart::OpResult macroTempOpResult = (operation); \
    if (!macroTempOpResult.isProceed()) { \
      applyOpResult(vm, macroTempOpResult, preempted); \
      break; \
    } \
  }

void Thread::run() {
  // Local variable cache of fields

  VM const vm = this->vm;
  XRegArray* const xregs = &this->xregs;

  // Where were we left?

  StableNode* abstraction;
  ProgramCounter PC;
  size_t yregCount;
  StaticArray<UnstableNode> yregs;
  StaticArray<StableNode> gregs;
  StaticArray<StableNode> kregs;

  popFrame(vm, abstraction, PC, yregCount, yregs, gregs, kregs);

  // Some helpers

#define advancePC(argCount) do { PC += (argCount) + 1; } while (0)

#define IntPC(offset) PC[offset]

#define XPC(offset) (*xregs)[PC[offset]]
#define YPC(offset) (yregs)[PC[offset]]
#define GPC(offset) (gregs)[PC[offset]]
#define KPC(offset) (kregs)[PC[offset]]

  // Preemption

  bool preempted = false;

  // The big loop

  while (!preempted) {
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

      // Double moves

      case OpMoveMoveXYXY:
        YPC(2).copy(vm, XPC(1));
        YPC(4).copy(vm, XPC(3));
        advancePC(4); break;

      case OpMoveMoveYXYX:
        XPC(2).copy(vm, YPC(1));
        XPC(4).copy(vm, YPC(3));
        advancePC(4); break;

      case OpMoveMoveYXXY:
        XPC(2).copy(vm, YPC(1));
        YPC(4).copy(vm, XPC(3));
        advancePC(4); break;

      case OpMoveMoveXYYX:
        YPC(2).copy(vm, XPC(1));
        XPC(4).copy(vm, YPC(3));
        advancePC(4); break;

      // Y allocations

      case OpAllocateY: {
        size_t count = IntPC(1);
        assert(count != 0);
        assert(yregs == nullptr); // Duplicate AllocateY
        yregCount = count;
        yregs = vm->newStaticArray<UnstableNode>(count);
        for (size_t i = 0; i < count; i++)
          yregs[i].make<SmallInt>(vm, 0);
        advancePC(1); break;
      }

      case OpDeallocateY: {
        assert(yregs != nullptr); // Duplicate DeallocateY
        vm->deleteStaticArray<UnstableNode>(yregs, yregCount);
        yregCount = 0;
        yregs = nullptr;
        advancePC(0); break;
      }

      // Variable allocation

      case OpCreateVarX: {
        XPC(1).make<Unbound>(vm);
        advancePC(1); break;
      }

      case OpCreateVarY: {
        YPC(1).make<Unbound>(vm);
        advancePC(1); break;
      }

      case OpCreateVarMoveX: {
        StableNode* stable = new (vm) StableNode;
        stable->make<Unbound>(vm);
        XPC(1).make<Reference>(vm, stable);
        XPC(2).make<Reference>(vm, stable);
        advancePC(2); break;
      }

      case OpCreateVarMoveY: {
        StableNode* stable = new (vm) StableNode;
        stable->make<Unbound>(vm);
        YPC(1).make<Reference>(vm, stable);
        XPC(2).make<Reference>(vm, stable);
        advancePC(2); break;
      }

      // Control

      case OpCallBuiltin: {
        int argc = PC[2];
        UnstableNode* args[argc];
        for (int i = 0; i < argc; i++)
          args[i] = &XPC(3 + i);

        UnstableNode temp(vm, KPC(1));
        CHECK_OPRESULT_BREAK(BuiltinCallable(temp).callBuiltin(vm, argc, args));

        advancePC(2 + argc);
        break;
      }

      case OpCallX: {
        call(XPC(1), IntPC(2), false,
             vm, abstraction, PC, yregCount,
             xregs, yregs, gregs, kregs, preempted);
        break;
      }

      case OpCallG: {
        UnstableNode temp(vm, GPC(1));
        call(temp, IntPC(2), false,
             vm, abstraction, PC, yregCount,
             xregs, yregs, gregs, kregs, preempted);
        break;
      }

      case OpTailCallX: {
        call(XPC(1), IntPC(2), true,
             vm, abstraction, PC, yregCount,
             xregs, yregs, gregs, kregs, preempted);
        break;
      }

      case OpTailCallG: {
        UnstableNode temp(vm, GPC(1));
        call(temp, IntPC(2), true,
             vm, abstraction, PC, yregCount,
             xregs, yregs, gregs, kregs, preempted);
        break;
      }

      case OpReturn: {
        if (stack.empty()) {
          terminate();
          return;
        }

        popFrame(vm, abstraction, PC, yregCount, yregs, gregs, kregs);

        // Do NOT advancePC() here!
        break;
      }

      case OpBranch: {
        int distance = IntPC(1);
        advancePC(1 + distance);
        break;
      }

      case OpCondBranch: {
        BoolOrNotBool testValue = bNotBool;

        CHECK_OPRESULT_BREAK(
          BooleanValue(XPC(1)).valueOrNotBool(vm, &testValue));

        int distance;

        switch (testValue) {
          case bFalse: distance = IntPC(2); break;
          case bTrue:  distance = IntPC(3); break;
          default:     distance = IntPC(4);
        }

        advancePC(4 + distance);
        break;
      }

      // Unification

      case OpUnifyXX: {
        CHECK_OPRESULT_BREAK(unify(vm, XPC(1), XPC(2)));

        advancePC(2);
        break;
      }

      case OpUnifyXY: {
        CHECK_OPRESULT_BREAK(unify(vm, XPC(1), YPC(2)));

        advancePC(2);
        break;
      }

      case OpUnifyXK: {
        UnstableNode rhs(vm, KPC(2));
        CHECK_OPRESULT_BREAK(unify(vm, XPC(1), rhs));

        advancePC(2);
        break;
      }

      case OpUnifyXG: {
        UnstableNode rhs(vm, GPC(2));
        CHECK_OPRESULT_BREAK(unify(vm, XPC(1), rhs));

        advancePC(2);
        break;
      }

      // Creation of data structures

      case OpArrayInitElementX: {
        CHECK_OPRESULT_BREAK(
          ArrayInitializer(XPC(1)).initElement(vm, IntPC(2), &XPC(3)));

        advancePC(3);
        break;
      }

      case OpArrayInitElementY: {
        CHECK_OPRESULT_BREAK(
          ArrayInitializer(XPC(1)).initElement(vm, IntPC(2), &YPC(3)));

        advancePC(3);
        break;
      }

      case OpArrayInitElementG: {
        UnstableNode value(vm, GPC(3));
        CHECK_OPRESULT_BREAK(
          ArrayInitializer(XPC(1)).initElement(vm, IntPC(2), &value));

        advancePC(3);
        break;
      }

      case OpArrayInitElementK: {
        UnstableNode value(vm, KPC(3));
        CHECK_OPRESULT_BREAK(
          ArrayInitializer(XPC(1)).initElement(vm, IntPC(2), &value));

        advancePC(3);
        break;
      }

      case OpCreateAbstractionX: {
        int arity = IntPC(1);
        UnstableNode& body = XPC(2);
        size_t Gc = IntPC(3);

        XPC(4).make<Abstraction>(vm, Gc, arity, &body);

        advancePC(4);
        break;
      }

      case OpCreateAbstractionK: {
        int arity = IntPC(1);
        UnstableNode body(vm, KPC(2));
        size_t Gc = IntPC(3);

        XPC(4).make<Abstraction>(vm, Gc, arity, &body);

        advancePC(4);
        break;
      }

      case OpCreateTupleX: {
        UnstableNode label(vm, XPC(1));
        size_t width = IntPC(2);

        XPC(3).make<Tuple>(vm, width, &label);

        advancePC(3);
        break;
      }

      case OpCreateTupleK: {
        UnstableNode label(vm, KPC(1));
        size_t width = IntPC(2);

        XPC(3).make<Tuple>(vm, width, &label);

        advancePC(3);
        break;
      }

      // Inlines for some builtins

      case OpInlineEqualsInteger: {
        bool resultValue = false;

        CHECK_OPRESULT_BREAK(IntegerValue(XPC(1)).equalsInteger(
          vm, IntPC(2), &resultValue));

        if (resultValue)
          advancePC(3);
        else
          advancePC(3 + IntPC(3));

        break;
      }

      case OpInlineAdd: {
        CHECK_OPRESULT_BREAK(Numeric(XPC(1)).add(vm, &XPC(2), &XPC(3)));

        advancePC(3);
        break;
      }

      case OpInlineSubtract: {
        CHECK_OPRESULT_BREAK(Numeric(XPC(1)).subtract(vm, &XPC(2), &XPC(3)));

        advancePC(3);
        break;
      }

      case OpInlinePlus1: {
        CHECK_OPRESULT_BREAK(IntegerValue(XPC(1)).addValue(vm, 1, &XPC(2)));

        advancePC(2);
        break;
      }

      case OpInlineMinus1: {
        CHECK_OPRESULT_BREAK(IntegerValue(XPC(1)).addValue(vm, -1, &XPC(2)));

        advancePC(2);
        break;
      }
    }
  }

#undef IntPC
#undef XPC
#undef YPC
#undef GPC
#undef KPC

  // Store the current state in the stack frame, for next invocation of run()
  pushFrame(vm, abstraction, PC, yregCount, yregs, gregs, kregs);
}

void Thread::pushFrame(VM vm, StableNode* abstraction,
                       ProgramCounter PC, size_t yregCount,
                       StaticArray<UnstableNode> yregs,
                       StaticArray<StableNode> gregs,
                       StaticArray<StableNode> kregs) {
  stack.push_front_new(vm, abstraction, PC, yregCount, yregs, gregs, kregs);
}

void Thread::popFrame(VM vm, StableNode*& abstraction,
                      ProgramCounter& PC, size_t& yregCount,
                      StaticArray<UnstableNode>& yregs,
                      StaticArray<StableNode>& gregs,
                      StaticArray<StableNode>& kregs) {
  StackEntry& entry = stack.front();

  abstraction = entry.abstraction;
  PC = entry.PC;
  yregCount = entry.yregCount;
  yregs = entry.yregs;
  gregs = entry.gregs;
  kregs = entry.kregs;

  stack.remove_front(vm);
}

#define CHECK_OPRESULT_RETURN(operation) \
  do { \
    ::mozart::OpResult macroTempOpResult = (operation); \
    if (!macroTempOpResult.isProceed()) { \
      applyOpResult(vm, macroTempOpResult, preempted); \
      return; \
    } \
  } while (false)

void Thread::call(RichNode target, int actualArity, bool isTailCall,
                  VM vm, StableNode*& abstraction,
                  ProgramCounter& PC, size_t& yregCount,
                  XRegArray* xregs,
                  StaticArray<UnstableNode>& yregs,
                  StaticArray<StableNode>& gregs,
                  StaticArray<StableNode>& kregs,
                  bool& preempted) {
  int formalArity;
  StableNode* body;
  ProgramCounter start;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  CHECK_OPRESULT_RETURN(Callable(target).getCallInfo(
    vm, &formalArity, &body, &start, &Xcount, &Gs, &Ks));

  if (actualArity != formalArity) {
    applyOpResult(vm, raiseIllegalArity(vm, formalArity, actualArity),
                  preempted);
    return;
  }

  advancePC(2);

  if (!isTailCall) {
    pushFrame(vm, abstraction, PC, yregCount, yregs, gregs, kregs);
  }

  // Setup new frame
  abstraction = target.getStableRef(vm);
  PC = start;
  xregs->grow(vm, Xcount, formalArity);
  yregCount = 0;
  yregs = nullptr;
  gregs = Gs;
  kregs = Ks;

  // Test for preemption
  // (there is no infinite execution path that does not traverse a call)
  if (vm->testPreemption())
    preempted = true;
}

void Thread::applyOpResult(VM vm, OpResult result, bool& preempted) {
  switch (result.kind()) {
    case OpResult::orProceed: {
      // Do nothing
      break;
    }

    case OpResult::orWaitBefore: {
      UnstableNode waitee(vm, *result.getWaiteeNode());
      DataflowVariable(waitee).addToSuspendList(vm, this);

      if (!isRunnable())
        preempted = true;

      break;
    }

    case OpResult::orFail: {
      if (!vm->isOnTopLevel()) {
        vm->getCurrentSpace()->fail(vm);
        preempted = true;
        return;
      }

      result = raise(vm, u"failure");
      // fall through
    }

    case OpResult::orRaise: {
      // TODO Allow to catch an exception
      std::cout << "Exception" << std::endl;
      std::cout << repr(vm, *result.getExceptionNode()) << std::endl;

      terminate();
      preempted = true;
      break;
    }
  }
}

void Thread::beforeGR()
{
  VM vm = this->vm;
  for (auto iterator = stack.begin(); iterator != stack.end(); iterator++)
    (*iterator).beforeGR(vm);
}

void Thread::afterGR()
{
  VM vm = this->vm;
  for (auto iterator = stack.begin(); iterator != stack.end(); iterator++)
    (*iterator).afterGR(vm);
}

Runnable* Thread::gCollect(GC gc) {
  return new (gc->vm) Thread(gc, *this);
}

Runnable* Thread::sClone(SC sc) {
  return new (sc->vm) Thread(sc, *this);
}

}

#undef advancePC
