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
#include <cassert>

#include "coreinterfaces.hh"
#include "corebuiltins.hh"
#include "variables.hh"

const ProgramCounter NullPC = nullptr;

////////////////
// StackEntry //
////////////////

StackEntry::StackEntry(GC gc, StackEntry& from) {
  gc->gcStableRef(from.abstraction, abstraction);
  PCOffset = from.PCOffset;
  yregCount = from.yregCount;

  if (yregCount == 0)
    yregs = nullptr;
  else {
    yregs = gc->vm->newStaticArray<UnstableNode>(yregCount);
    for (size_t i = 0; i < yregCount; i++)
      gc->gcUnstableNode(from.yregs[i], yregs[i]);
  }

  // gregs and kregs are irrelevant
}

void StackEntry::beforeGC(VM vm) {
  int arity;
  StableNode* body;
  ProgramCounter start = nullptr;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  UnstableNode temp(vm, *abstraction);
  Callable callable = temp;
  callable.getCallInfo(vm, &arity, &body, &start, &Xcount, &Gs, &Ks);

  PCOffset = PC - start;
}

void StackEntry::afterGC(VM vm) {
  int arity;
  StableNode* body;
  ProgramCounter start = nullptr;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  UnstableNode temp(vm, *abstraction);
  Callable callable = temp;
  callable.getCallInfo(vm, &arity, &body, &start, &Xcount, &Gs, &Ks);

  PC = start + PCOffset;
  gregs = Gs;
  kregs = Ks;
}

////////////
// Thread //
////////////

Thread::Thread(VM vm, StableNode* abstraction) : Runnable(vm) {
  // getCallInfo

  int arity;
  StableNode* body;
  ProgramCounter start = nullptr;
  int Xcount = 0;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  UnstableNode temp(vm, *abstraction);
  Callable callable = temp;
#ifndef NDEBUG
  BuiltinResult result =
#endif
  callable.getCallInfo(vm, &arity, &body, &start, &Xcount, &Gs, &Ks);

#ifndef NDEBUG
  assert(result.isProceed() && arity == 0);
#endif

  // Set up

  xregs.init(vm, std::max(Xcount, InitXRegisters));

  pushFrame(vm, abstraction, start, 0, nullptr, Gs, Ks);

  vm->scheduleThread(this);
}

Thread::Thread(GC gc, Thread& from) : Runnable(gc, from) {
  // X registers

  size_t Xcount = from.xregs.size();
  xregs.init(vm, Xcount);
  for (size_t i = 0; i < Xcount; i++)
    gc->gcUnstableNode(from.xregs[i], xregs[i]);

  // Stack frame

  for (auto iterator = from.stack.begin();
       iterator != from.stack.end(); iterator++) {
    stack.push_back_new(vm, gc, *iterator);
  }
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
        BuiltinCallable x = temp;
        BuiltinResult result = x.callBuiltin(vm, argc, args);

        if (result.isProceed())
          advancePC(2 + argc);
        else
          applyBuiltinResult(vm, result, preempted);

        break;
      }

      case OpCallX:
        call(Reference::getStableRefFor(vm, XPC(1)), IntPC(2), false,
             vm, abstraction, PC, yregCount,
             xregs, yregs, gregs, kregs, preempted);
        break;

      case OpCallG:
        call(Reference::getStableRefFor(vm, GPC(1)), IntPC(2), false,
             vm, abstraction, PC, yregCount,
             xregs, yregs, gregs, kregs, preempted);
        break;

      case OpTailCallX:
        call(Reference::getStableRefFor(vm, XPC(1)), IntPC(2), true,
             vm, abstraction, PC, yregCount,
             xregs, yregs, gregs, kregs, preempted);
        break;

      case OpTailCallG:
        call(Reference::getStableRefFor(vm, GPC(1)), IntPC(2), true,
             vm, abstraction, PC, yregCount,
             xregs, yregs, gregs, kregs, preempted);
        break;

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
        UnstableNode& test = XPC(1);
        BoolOrNotBool testValue;

        BooleanValue testBoolValue = test;
        BuiltinResult result = testBoolValue.valueOrNotBool(vm, &testValue);

        if (result.isProceed()) {
          int distance;

          switch (testValue) {
            case bFalse: distance = IntPC(2); break;
            case bTrue:  distance = IntPC(3); break;
            default:     distance = IntPC(4);
          }

          advancePC(4 + distance);
        } else {
          applyBuiltinResult(vm, result, preempted);
        }

        break;
      }

      // Unification

      case OpUnifyXX: {
        BuiltinResult result = unify(vm, XPC(1), XPC(2));
        if (result.isProceed())
          advancePC(2);
        else
          applyBuiltinResult(vm, result, preempted);
        break;
      }

      case OpUnifyXY: {
        BuiltinResult result = unify(vm, XPC(1), YPC(2));
        if (result.isProceed())
          advancePC(2);
        else
          applyBuiltinResult(vm, result, preempted);
        break;
      }

      case OpUnifyXK: {
        UnstableNode rhs(vm, KPC(2));
        BuiltinResult result = unify(vm, XPC(1), rhs);
        if (result.isProceed())
          advancePC(2);
        else
          applyBuiltinResult(vm, result, preempted);
        break;
      }

      case OpUnifyXG: {
        UnstableNode rhs(vm, GPC(2));
        BuiltinResult result = unify(vm, XPC(1), rhs);
        if (result.isProceed())
          advancePC(2);
        else
          applyBuiltinResult(vm, result, preempted);
        break;
      }

      // Creation of data structures

      case OpArrayInitElementX: {
        arrayInitElement(XPC(1), IntPC(2), &XPC(3),
                         vm, PC, preempted);
        break;
      }

      case OpArrayInitElementY: {
        arrayInitElement(XPC(1), IntPC(2), &YPC(3),
                         vm, PC, preempted);
        break;
      }

      case OpArrayInitElementG: {
        UnstableNode value(vm, GPC(3));
        arrayInitElement(XPC(1), IntPC(2), &value,
                         vm, PC, preempted);
        break;
      }

      case OpArrayInitElementK: {
        UnstableNode value(vm, KPC(3));
        arrayInitElement(XPC(1), IntPC(2), &value,
                         vm, PC, preempted);
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
        IntegerValue x = XPC(1);
        nativeint right = IntPC(2);
        bool resultValue;

        BuiltinResult result = x.equalsInteger(vm, right, &resultValue);

        if (result.isProceed()) {
          if (resultValue)
            advancePC(3);
          else
            advancePC(3 + IntPC(3));
        } else {
          applyBuiltinResult(vm, result, preempted);
        }

        break;
      }

      case OpInlineAdd: {
        Numeric x = XPC(1);
        BuiltinResult result = x.add(vm, &XPC(2), &XPC(3));

        if (result.isProceed())
          advancePC(3);
        else
          applyBuiltinResult(vm, result, preempted);

        break;
      }

      case OpInlineSubtract: {
        Numeric x = XPC(1);
        BuiltinResult result = x.subtract(vm, &XPC(2), &XPC(3));

        if (result.isProceed())
          advancePC(3);
        else
          applyBuiltinResult(vm, result, preempted);

        break;
      }

      case OpInlinePlus1: {
        IntegerValue x = XPC(1);
        BuiltinResult result = x.addValue(vm, 1, &XPC(2));

        if (result.isProceed())
          advancePC(2);
        else
          applyBuiltinResult(vm, result, preempted);

        break;
      }

      case OpInlineMinus1: {
        IntegerValue x = XPC(1);
        BuiltinResult result = x.addValue(vm, -1, &XPC(2));

        if (result.isProceed())
          advancePC(2);
        else
          applyBuiltinResult(vm, result, preempted);

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

void Thread::call(StableNode* target, int actualArity, bool isTailCall,
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

  UnstableNode temp(vm, *target);
  Callable x = temp;
  BuiltinResult result = x.getCallInfo(vm, &formalArity, &body, &start,
                                       &Xcount, &Gs, &Ks);

  if (result.isProceed()) {
    if (actualArity != formalArity) {
      applyBuiltinResult(vm, raiseAtom(vm, u"illegalArity"), preempted);
      return;
    }

    advancePC(2);

    if (!isTailCall) {
      pushFrame(vm, abstraction, PC, yregCount, yregs, gregs, kregs);
    }

    // Setup new frame
    abstraction = target;
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
  } else {
    applyBuiltinResult(vm, result, preempted);
  }
}

BuiltinResult Thread::unify(VM vm, RichNode left, RichNode right) {
  if (left.type() == Unbound::type())
    return IMPL(BuiltinResult, Unbound, bind, left, vm, right);
  else if (right.type() == Unbound::type())
    return IMPL(BuiltinResult, Unbound, bind, right, vm, left);
  else if (left.type() == Variable::type())
    return IMPL(BuiltinResult, Variable, bind, left, vm, right);
  else if (right.type() == Variable::type())
    return IMPL(BuiltinResult, Variable, bind, right, vm, left);
  else {
    // TODO Non-trivial unify
    return BuiltinResult::proceed();
  }
}

void Thread::arrayInitElement(RichNode node, size_t index, UnstableNode* value,
                              VM vm, ProgramCounter& PC, bool& preempted) {
  ArrayInitializer x = node;
  BuiltinResult result = x.initElement(vm, index, value);

  if (result.isProceed())
    advancePC(3);
  else
    applyBuiltinResult(vm, result, preempted);
}

void Thread::applyBuiltinResult(VM vm, BuiltinResult result, bool& preempted) {
  switch (result.status()) {
    case BuiltinResult::brProceed: {
      // Do nothing
      break;
    }

    case BuiltinResult::brWaitBefore: {
      UnstableNode waitee(vm, *result.getWaiteeNode());
      DataflowVariable var = waitee;
      var.wait(vm, this);

      if (!isRunnable())
        preempted = true;

      break;
    }

    case BuiltinResult::brRaise: {
      // TODO Allow to catch an exception
      UnstableNode exception(vm, *result.getExceptionNode());
      std::cout << "Exception" << std::endl;

      UnstableNode* showArgs[] = { &exception };
      builtins::show(vm, showArgs);

      terminate();
      preempted = true;
      break;
    }
  }
}

void Thread::beforeGC()
{
  VM vm = this->vm;
  for (auto iterator = stack.begin(); iterator != stack.end(); iterator++)
    (*iterator).beforeGC(vm);
}

void Thread::afterGC()
{
  VM vm = this->vm;
  for (auto iterator = stack.begin(); iterator != stack.end(); iterator++)
    (*iterator).afterGC(vm);
}

Runnable* Thread::gCollect(GC gc) {
  return new (gc->vm) Thread(gc, *this);
}

#undef advancePC
