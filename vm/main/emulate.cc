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
  if (from.abstraction == nullptr)
    abstraction = nullptr;
  else
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

void StackEntry::beforeGR(VM vm, StableNode*& abs) {
  if (!isExceptionHandler())
    abs = abstraction;
  assert(abs != nullptr);

  int arity;
  ProgramCounter start = nullptr;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  Callable(*abs).getCallInfo(vm, arity, start, Xcount, Gs, Ks);

  PCOffset = PC - start;
}

void StackEntry::afterGR(VM vm, StableNode*& abs) {
  if (!isExceptionHandler())
    abs = abstraction;
  assert(abs != nullptr);

  int arity;
  ProgramCounter start = nullptr;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  Callable(*abs).getCallInfo(vm, arity, start, Xcount, Gs, Ks);

  PC = start + PCOffset;
  gregs = Gs;
  kregs = Ks;
}

/////////////////
// ThreadStack //
/////////////////

bool ThreadStack::findExceptionHandler(VM vm, StableNode*& abstraction,
                                       ProgramCounter& PC, size_t& yregCount,
                                       StaticArray<UnstableNode>& yregs,
                                       StaticArray<StableNode>& gregs,
                                       StaticArray<StableNode>& kregs) {
  while (!empty()) {
    StackEntry& entry = front();

    if (entry.isExceptionHandler()) {
      PC = entry.PC;
      remove_front(vm);
      return true;
    } else {
      vm->deleteStaticArray<UnstableNode>(yregs, yregCount);

      abstraction = entry.abstraction;
      yregCount = entry.yregCount;
      yregs = entry.yregs;
      gregs = entry.gregs;
      kregs = entry.kregs;
      remove_front(vm);
    }
  }

  return false;
}

////////////
// Thread //
////////////

Thread::Thread(VM vm, Space* space, RichNode abstraction,
               bool createSuspended): Runnable(vm, space) {
  constructor(vm, abstraction, 0, nullptr, createSuspended);
}

Thread::Thread(VM vm, Space* space, RichNode abstraction,
               size_t argc, UnstableNode* args[],
               bool createSuspended): Runnable(vm, space) {
  constructor(vm, abstraction, argc, args, createSuspended);
}

void Thread::constructor(VM vm, RichNode abstraction,
                         size_t argc, UnstableNode* args[],
                         bool createSuspended) {
  // getCallInfo

  int arity = 0;
  ProgramCounter start = nullptr;
  int Xcount = 0;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  MOZART_ASSERT_PROCEED(Callable(abstraction).getCallInfo(
    vm, arity, start, Xcount, Gs, Ks));

  assert(arity >= 0 && (size_t) arity == argc);

  // Set up

  auto initXRegisters = InitXRegisters; // work around for limitation of clang
  xregs.init(vm, std::max(Xcount, initXRegisters));

  for (size_t i = 0; i < argc; i++)
    xregs[i].copy(vm, *args[i]);

  pushFrame(vm, abstraction.getStableRef(vm), start, 0, nullptr, Gs, Ks);

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
      applyOpResult(vm, macroTempOpResult, preempted, \
                    abstraction, PC, yregCount, xregs, yregs, gregs, kregs); \
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
          yregs[i].init(vm);
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
        XPC(1) = OptVar::build(vm);
        advancePC(1); break;
      }

      case OpCreateVarY: {
        YPC(1) = OptVar::build(vm);
        advancePC(1); break;
      }

      case OpCreateVarMoveX: {
        StableNode* stable = new (vm) StableNode;
        stable->init(vm, OptVar::build(vm));
        XPC(1) = Reference::build(vm, stable);
        XPC(2) = Reference::build(vm, stable);
        advancePC(2); break;
      }

      case OpCreateVarMoveY: {
        StableNode* stable = new (vm) StableNode;
        stable->init(vm, OptVar::build(vm));
        YPC(1) = Reference::build(vm, stable);
        XPC(2) = Reference::build(vm, stable);
        advancePC(2); break;
      }

      // Exception handlers

      case OpSetupExceptionHandler: {
        int distance = IntPC(1);
        advancePC(1);

        ProgramCounter handlerPC = PC + distance;
        stack.pushExceptionHandler(vm, handlerPC);

        break;
      }

      case OpPopExceptionHandler: {
        stack.popExceptionHandler(vm);
        advancePC(0);
        break;
      }

      // Control

      case OpCallBuiltin0: {
        CHECK_OPRESULT_BREAK(BuiltinCallable(KPC(1)).callBuiltin(vm));

        advancePC(1);
        break;
      }

      case OpCallBuiltin1: {
        CHECK_OPRESULT_BREAK(BuiltinCallable(KPC(1)).callBuiltin(
          vm, XPC(2)));

        advancePC(2);
        break;
      }

      case OpCallBuiltin2: {
        CHECK_OPRESULT_BREAK(BuiltinCallable(KPC(1)).callBuiltin(
          vm, XPC(2), XPC(3)));

        advancePC(3);
        break;
      }

      case OpCallBuiltin3: {
        CHECK_OPRESULT_BREAK(BuiltinCallable(KPC(1)).callBuiltin(
          vm, XPC(2), XPC(3), XPC(4)));

        advancePC(4);
        break;
      }

      case OpCallBuiltin4: {
        CHECK_OPRESULT_BREAK(BuiltinCallable(KPC(1)).callBuiltin(
          vm, XPC(2), XPC(3), XPC(4), XPC(5)));

        advancePC(5);
        break;
      }

      case OpCallBuiltin5: {
        CHECK_OPRESULT_BREAK(BuiltinCallable(KPC(1)).callBuiltin(
          vm, XPC(2), XPC(3), XPC(4), XPC(5), XPC(6)));

        advancePC(6);
        break;
      }

      case OpCallBuiltinN: {
        size_t argc = IntPC(2);

        UnstableNode* args[argc];
        for (size_t i = 0; i < argc; i++)
          args[i] = &XPC(3 + i);

        CHECK_OPRESULT_BREAK(BuiltinCallable(KPC(1)).callBuiltin(
          vm, argc, args));

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
        call(GPC(1), IntPC(2), false,
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
        call(GPC(1), IntPC(2), true,
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
          BooleanValue(XPC(1)).valueOrNotBool(vm, testValue));

        int distance;

        switch (testValue) {
          case bFalse: distance = IntPC(2); break;
          case bTrue:  distance = IntPC(3); break;
          default:     distance = IntPC(4);
        }

        advancePC(4 + distance);
        break;
      }

      case OpPatternMatch: {
        patternMatch(vm, XPC(1), KPC(2),
                     abstraction, PC, yregCount, xregs, yregs, gregs, kregs,
                     preempted);
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
        CHECK_OPRESULT_BREAK(unify(vm, XPC(1), KPC(2)));

        advancePC(2);
        break;
      }

      case OpUnifyXG: {
        CHECK_OPRESULT_BREAK(unify(vm, XPC(1), GPC(2)));

        advancePC(2);
        break;
      }

      // Creation of data structures

      case OpArrayInitElementX: {
        CHECK_OPRESULT_BREAK(
          ArrayInitializer(XPC(1)).initElement(vm, IntPC(2), XPC(3)));

        advancePC(3);
        break;
      }

      case OpArrayInitElementY: {
        CHECK_OPRESULT_BREAK(
          ArrayInitializer(XPC(1)).initElement(vm, IntPC(2), YPC(3)));

        advancePC(3);
        break;
      }

      case OpArrayInitElementG: {
        CHECK_OPRESULT_BREAK(
          ArrayInitializer(XPC(1)).initElement(vm, IntPC(2), GPC(3)));

        advancePC(3);
        break;
      }

      case OpArrayInitElementK: {
        CHECK_OPRESULT_BREAK(
          ArrayInitializer(XPC(1)).initElement(vm, IntPC(2), KPC(3)));

        advancePC(3);
        break;
      }

      case OpCreateAbstractionX: {
        XPC(4) = Abstraction::build(vm, IntPC(3), IntPC(1), XPC(2));

        advancePC(4);
        break;
      }

      case OpCreateAbstractionK: {
        XPC(4) = Abstraction::build(vm, IntPC(3), IntPC(1), KPC(2));

        advancePC(4);
        break;
      }

      case OpCreateTupleK: {
        XPC(3) = Tuple::build(vm, IntPC(2), KPC(1));

        advancePC(3);
        break;
      }

      case OpCreateRecordK: {
        XPC(3) = Record::build(vm, IntPC(2), KPC(1));

        advancePC(3);
        break;
      }

      case OpCreateConsXX: {
        XPC(3) = Cons::build(vm, XPC(1), XPC(2));

        advancePC(3);
        break;
      }

      // Inlines for some builtins

      case OpInlineEqualsInteger: {
        bool resultValue = false;

        CHECK_OPRESULT_BREAK(IntegerValue(XPC(1)).equalsInteger(
          vm, IntPC(2), resultValue));

        if (resultValue)
          advancePC(3);
        else
          advancePC(3 + IntPC(3));

        break;
      }

#include "emulate-inline.cc"
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

  assert(!entry.isExceptionHandler());

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
      applyOpResult(vm, macroTempOpResult, preempted, \
                    abstraction, PC, yregCount, xregs, yregs, gregs, kregs); \
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
  int formalArity = 0;
  ProgramCounter start = nullptr;
  int Xcount = 0;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  CHECK_OPRESULT_RETURN(Callable(target).getCallInfo(
    vm, formalArity, start, Xcount, Gs, Ks));

  if (actualArity != formalArity) {
    CHECK_OPRESULT_RETURN(raiseIllegalArity(vm, formalArity, actualArity));
  }

  advancePC(2);

  if (!isTailCall) {
    pushFrame(vm, abstraction, PC, yregCount, yregs, gregs, kregs);
  } else {
    assert(stack.empty() || !stack.front().isExceptionHandler());
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

void Thread::patternMatch(VM vm, RichNode value, RichNode patterns,
                          StableNode*& abstraction,
                          ProgramCounter& PC, size_t& yregCount,
                          XRegArray* xregs,
                          StaticArray<UnstableNode>& yregs,
                          StaticArray<StableNode>& gregs,
                          StaticArray<StableNode>& kregs,
                          bool& preempted) {
  using namespace patternmatching;

  OpResult res = OpResult::proceed();
  size_t patternCount = 0;
  std::unique_ptr<UnstableNode[]> patternList;

  if (!matchesVariadicSharp(vm, res, patterns, patternCount, patternList))
    CHECK_OPRESULT_RETURN(matchTypeError(vm, res, patterns,
                                         MOZART_STR("patterns")));

  for (size_t index = 0; index < patternCount; index++) {
    UnstableNode pattern;
    nativeint jumpOffset = 0;

    if (!matchesSharp(vm, res, patternList[index],
                      capture(pattern), capture(jumpOffset))) {
      CHECK_OPRESULT_RETURN(matchTypeError(vm, res, patternList[index],
                                           MOZART_STR("pattern")));
    }

    assert(jumpOffset >= 0);

    bool matchResult = false;
    CHECK_OPRESULT_RETURN(mozart::patternMatch(
      vm, value, pattern, xregs->getArray(), matchResult));

    if (matchResult) {
      advancePC(2 + jumpOffset);
      return;
    }
  }

  advancePC(2);
}

void Thread::applyOpResult(VM vm, OpResult result, bool& preempted,
                           StableNode*& abstraction,
                           ProgramCounter& PC, size_t& yregCount,
                           XRegArray* xregs,
                           StaticArray<UnstableNode>& yregs,
                           StaticArray<StableNode>& gregs,
                           StaticArray<StableNode>& kregs) {
  switch (result.kind()) {
    case OpResult::orProceed: {
      // Do nothing
      break;
    }

    case OpResult::orWaitBefore:
    case OpResult::orWaitQuietBefore: {
      RichNode waitee = *result.getWaiteeNode();

      if (getRaiseOnBlock() && (waitee.is<OptVar>() || waitee.is<Variable>())) {
        OpResult blockError = raiseKernelError(vm, MOZART_STR("block"), waitee);
        return applyOpResult(vm, blockError, preempted,
                             abstraction, PC, yregCount,
                             xregs, yregs, gregs, kregs);
      }

      if (result.kind() != OpResult::orWaitQuietBefore) {
        if (waitee.is<FailedValue>()) {
          return applyOpResult(vm, waitee.as<FailedValue>().raiseUnderlying(vm),
                               preempted, abstraction, PC, yregCount,
                               xregs, yregs, gregs, kregs);
        } else {
          DataflowVariable(waitee).markNeeded(vm);
        }
      }

      suspendOnVar(vm, waitee);

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

      result = raise(vm, vm->coreatoms.failure);
      // fall through
    }

    case OpResult::orRaise: {
      bool handlerFound = stack.findExceptionHandler(
        vm, abstraction, PC, yregCount, yregs, gregs, kregs);

      if (handlerFound) {
        // Store the exception value in X(0)
        (*xregs)[0].copy(vm, *result.getExceptionNode());
      } else {
        // Uncaught exception
        std::cout << "Uncaught exception" << std::endl;
        std::cout << repr(vm, *result.getExceptionNode()) << std::endl;

        terminate();
        preempted = true;
      }

      break;
    }
  }
}

void Thread::beforeGR()
{
  VM vm = this->vm;
  StableNode* abstraction = nullptr;
  for (auto iterator = stack.begin(); iterator != stack.end(); iterator++)
    (*iterator).beforeGR(vm, abstraction);
}

void Thread::afterGR()
{
  VM vm = this->vm;
  StableNode* abstraction = nullptr;
  for (auto iterator = stack.begin(); iterator != stack.end(); iterator++)
    (*iterator).afterGR(vm, abstraction);
}

Runnable* Thread::gCollect(GC gc) {
  return new (gc->vm) Thread(gc, *this);
}

Runnable* Thread::sClone(SC sc) {
  return new (sc->vm) Thread(sc, *this);
}

}

#undef advancePC
