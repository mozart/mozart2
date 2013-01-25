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
#include "coremodules.hh"

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

  size_t arity;
  ProgramCounter start = nullptr;
  size_t Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  Callable(*abs).getCallInfo(vm, arity, start, Xcount, Gs, Ks);

  PCOffset = PC - start;
}

void StackEntry::afterGR(VM vm, StableNode*& abs) {
  if (!isExceptionHandler())
    abs = abstraction;
  assert(abs != nullptr);

  size_t arity;
  ProgramCounter start = nullptr;
  size_t Xcount;
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

namespace {
  inline
  UnstableNode buildStackTraceItem(VM vm, StableNode* abstraction,
                                   ProgramCounter PC) {
    atom_t printName;
    UnstableNode debugData;
    Callable(*abstraction).getDebugInfo(vm, printName, debugData);

    UnstableNode kind = build(vm, MOZART_STR("call"));
    UnstableNode data = build(vm, *abstraction);

    Dottable dotDebugData(debugData);
    UnstableNode file = dotDebugData.condSelect(vm, MOZART_STR("file"),
                                                vm->coreatoms.empty);
    UnstableNode line = dotDebugData.condSelect(vm, MOZART_STR("line"), unit);
    UnstableNode column = dotDebugData.condSelect(vm, MOZART_STR("column"), -1);

    UnstableNode PCNode = build(vm, reinterpret_cast<std::intptr_t>(PC));

    return buildRecord(
      vm, buildArity(vm, MOZART_STR("entry"),
                     MOZART_STR("PC"),
                     MOZART_STR("column"),
                     MOZART_STR("data"),
                     MOZART_STR("file"),
                     MOZART_STR("kind"),
                     MOZART_STR("line")),
      std::move(PCNode), std::move(column), std::move(data), std::move(file),
      std::move(kind), std::move(line)
    );
  }
}

UnstableNode ThreadStack::buildStackTrace(VM vm, StableNode* abstraction,
                                          ProgramCounter PC) {
  OzListBuilder result(vm);

  if (abstraction != nullptr)
    result.push_back(vm, buildStackTraceItem(vm, abstraction, PC));

  for (auto iter = begin(); iter != end(); ++iter) {
    StackEntry& entry = *iter;

    if (!entry.isExceptionHandler()) {
      abstraction = entry.abstraction;
      PC = entry.PC;

      result.push_back(vm, buildStackTraceItem(vm, abstraction, PC));
    }
  }

  return result.get(vm);
}

////////////
// Thread //
////////////

constexpr size_t Thread::InitXRegisters;

Thread::Thread(VM vm, Space* space, RichNode abstraction,
               bool createSuspended): Runnable(vm, space) {
  constructor(vm, abstraction, 0, nullptr, createSuspended);
}

Thread::Thread(VM vm, Space* space, RichNode abstraction,
               size_t argc, RichNode args[],
               bool createSuspended): Runnable(vm, space) {
  constructor(vm, abstraction, argc, args, createSuspended);
}

void Thread::constructor(VM vm, RichNode abstraction,
                         size_t argc, RichNode args[],
                         bool createSuspended) {
  // getCallInfo

  size_t arity = 0;
  ProgramCounter start = nullptr;
  size_t Xcount = 0;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  doGetCallInfo(vm, abstraction, arity, start, Xcount, Gs, Ks);

  if (argc != arity)
    raise(vm, MOZART_STR("illegalArity"), arity, argc);

  // Set up

  xregs.init(vm, std::max(Xcount, InitXRegisters));

  for (size_t i = 0; i < argc; i++)
    xregs[i].copy(vm, args[i]);

  pushFrame(vm, abstraction.getStableRef(vm), start, 0, nullptr, Gs, Ks);

  injectedException = nullptr;
  _terminationVar.init(vm, OptVar::build(vm, getSpace()));

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

  // Misc

  if (from.injectedException == nullptr)
    injectedException = nullptr;
  else
    gr->copyStableRef(injectedException, from.injectedException);

  gr->copyStableNode(_terminationVar, from._terminationVar);
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

  getIntermediateState().rewind(vm);

  // Some helpers

#define advancePC(argCount) do { PC += (argCount) + 1; } while (0)

#define IntPC(offset) PC[offset]

#define XPC(offset) (*xregs)[PC[offset]]
#define YPC(offset) (yregs)[PC[offset]]
#define GPC(offset) (gregs)[PC[offset]]
#define KPC(offset) (kregs)[PC[offset]]

  // Preemption

  bool preempted = false;

  // Backup of the PC for some complex opcodes

  bool hasBackupPC = false;
  ProgramCounter backupPC = NullPC;

  // The big try-catch that catches all bad things in the world
  MOZART_TRY(vm) {

    // Now's the right time to inject an exception that was thrown at us

    if (injectedException != nullptr) {
      auto temp = injectedException;
      injectedException = nullptr;
      raise(vm, *temp);
    }

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

          stack.pushExceptionHandler(vm, PC);

          PC += distance;
          break;
        }

        case OpPopExceptionHandler: {
          stack.popExceptionHandler(vm);
          advancePC(0);
          break;
        }

        // Control

        case OpCallBuiltin0: {
          BuiltinCallable(KPC(1)).callBuiltin(vm);
          advancePC(1);
          break;
        }

        case OpCallBuiltin1: {
          BuiltinCallable(KPC(1)).callBuiltin(vm, XPC(2));
          advancePC(2);
          break;
        }

        case OpCallBuiltin2: {
          BuiltinCallable(KPC(1)).callBuiltin(vm, XPC(2), XPC(3));
          advancePC(3);
          break;
        }

        case OpCallBuiltin3: {
          BuiltinCallable(KPC(1)).callBuiltin(vm, XPC(2), XPC(3), XPC(4));
          advancePC(4);
          break;
        }

        case OpCallBuiltin4: {
          BuiltinCallable(KPC(1)).callBuiltin(vm, XPC(2), XPC(3), XPC(4),
                                              XPC(5));
          advancePC(5);
          break;
        }

        case OpCallBuiltin5: {
          BuiltinCallable(KPC(1)).callBuiltin(vm, XPC(2), XPC(3), XPC(4),
                                              XPC(5), XPC(6));
          advancePC(6);
          break;
        }

        case OpCallBuiltinN: {
          size_t argc = IntPC(2);

          UnstableNode* args[argc];
          for (size_t i = 0; i < argc; i++)
            args[i] = &XPC(3 + i);

          BuiltinCallable(KPC(1)).callBuiltin(vm, argc, args);

          advancePC(2 + argc);
          break;
        }

        case OpCallX: {
          call(XPC(1), IntPC(2), false,
               vm, abstraction, PC, yregCount,
               xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpCallY: {
          call(YPC(1), IntPC(2), false,
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

        case OpCallK: {
          call(KPC(1), IntPC(2), false,
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

        case OpTailCallY: {
          call(YPC(1), IntPC(2), true,
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

        case OpTailCallK: {
          call(KPC(1), IntPC(2), true,
               vm, abstraction, PC, yregCount,
               xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpSendMsgX: {
          sendMsg(XPC(1), KPC(2), IntPC(3), false,
                  vm, abstraction, PC, yregCount,
                  xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpSendMsgY: {
          sendMsg(YPC(1), KPC(2), IntPC(3), false,
                  vm, abstraction, PC, yregCount,
                  xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpSendMsgG: {
          sendMsg(GPC(1), KPC(2), IntPC(3), false,
                  vm, abstraction, PC, yregCount,
                  xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpSendMsgK: {
          sendMsg(KPC(1), KPC(2), IntPC(3), false,
                  vm, abstraction, PC, yregCount,
                  xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpTailSendMsgX: {
          sendMsg(XPC(1), KPC(2), IntPC(3), true,
                  vm, abstraction, PC, yregCount,
                  xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpTailSendMsgY: {
          sendMsg(YPC(1), KPC(2), IntPC(3), true,
                  vm, abstraction, PC, yregCount,
                  xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpTailSendMsgG: {
          sendMsg(GPC(1), KPC(2), IntPC(3), true,
                  vm, abstraction, PC, yregCount,
                  xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpTailSendMsgK: {
          sendMsg(KPC(1), KPC(2), IntPC(3), true,
                  vm, abstraction, PC, yregCount,
                  xregs, yregs, gregs, kregs, preempted);
          break;
        }

        case OpReturn: {
          if (stack.empty()) {
            terminate();
            preempted = true;
            break;
          }

          popFrame(vm, abstraction, PC, yregCount, yregs, gregs, kregs);

          // Do NOT advancePC() here!
          break;
        }

        case OpBranch: {
          std::ptrdiff_t distance = IntPC(1);
          advancePC(1 + distance);
          break;
        }

        case OpBranchBackward: {
          std::ptrdiff_t distance = IntPC(1);
          advancePC(1 - distance);
          break;
        }

        case OpCondBranch: {
          using namespace patternmatching;

          bool test;
          if (matches(vm, XPC(1), capture(test))) {
            if (test)
              advancePC(3);
            else
              advancePC(3 + (std::ptrdiff_t) IntPC(2));
          } else {
            advancePC(3 + (std::ptrdiff_t) IntPC(3));
          }

          break;
        }

        case OpCondBranchFB: {
          using namespace patternmatching;

          bool test;
          if (matches(vm, XPC(1), capture(test))) {
            if (test)
              advancePC(3);
            else
              advancePC(3 + (std::ptrdiff_t) IntPC(2));
          } else {
            advancePC(3 - (std::ptrdiff_t) IntPC(3));
          }

          break;
        }

        case OpCondBranchBF: {
          using namespace patternmatching;

          bool test;
          if (matches(vm, XPC(1), capture(test))) {
            if (test)
              advancePC(3);
            else
              advancePC(3 - (std::ptrdiff_t) IntPC(2));
          } else {
            advancePC(3 + (std::ptrdiff_t) IntPC(3));
          }

          break;
        }

        case OpCondBranchBB: {
          using namespace patternmatching;

          bool test;
          if (matches(vm, XPC(1), capture(test))) {
            if (test)
              advancePC(3);
            else
              advancePC(3 - (std::ptrdiff_t) IntPC(2));
          } else {
            advancePC(3 - (std::ptrdiff_t) IntPC(3));
          }

          break;
        }

        case OpPatternMatchX: {
          patternMatch(vm, XPC(1), KPC(2),
                       abstraction, PC, yregCount, xregs, yregs, gregs, kregs,
                       preempted);
          break;
        }

        case OpPatternMatchY: {
          patternMatch(vm, YPC(1), KPC(2),
                       abstraction, PC, yregCount, xregs, yregs, gregs, kregs,
                       preempted);
          break;
        }

        case OpPatternMatchG: {
          patternMatch(vm, GPC(1), KPC(2),
                       abstraction, PC, yregCount, xregs, yregs, gregs, kregs,
                       preempted);
          break;
        }

        // Unification

        case OpUnifyXX: {
          unify(vm, XPC(1), XPC(2));
          advancePC(2);
          break;
        }

        case OpUnifyXY: {
          unify(vm, XPC(1), YPC(2));
          advancePC(2);
          break;
        }

        case OpUnifyXG: {
          unify(vm, XPC(1), GPC(2));
          advancePC(2);
          break;
        }

        case OpUnifyXK: {
          unify(vm, XPC(1), KPC(2));
          advancePC(2);
          break;
        }

        case OpUnifyYY: {
          unify(vm, YPC(1), YPC(2));
          advancePC(2);
          break;
        }

        case OpUnifyYG: {
          unify(vm, YPC(1), GPC(2));
          advancePC(2);
          break;
        }

        case OpUnifyYK: {
          unify(vm, YPC(1), KPC(2));
          advancePC(2);
          break;
        }

        case OpUnifyGG: {
          unify(vm, GPC(1), GPC(2));
          advancePC(2);
          break;
        }

        case OpUnifyGK: {
          unify(vm, GPC(1), KPC(2));
          advancePC(2);
          break;
        }

        case OpUnifyKK: {
          unify(vm, KPC(1), KPC(2));
          advancePC(2);
          break;
        }

        // Creation of data structures

        case OpCreateAbstractionStoreX:
        case OpCreateConsStoreX:
        case OpCreateTupleStoreX:
        case OpCreateRecordStoreX:

        case OpCreateAbstractionStoreY:
        case OpCreateConsStoreY:
        case OpCreateTupleStoreY:
        case OpCreateRecordStoreY:

        case OpCreateAbstractionUnifyX:
        case OpCreateConsUnifyX:
        case OpCreateTupleUnifyX:
        case OpCreateRecordUnifyX:

        case OpCreateAbstractionUnifyY:
        case OpCreateConsUnifyY:
        case OpCreateTupleUnifyY:
        case OpCreateRecordUnifyY:

        case OpCreateAbstractionUnifyG:
        case OpCreateConsUnifyG:
        case OpCreateTupleUnifyG:
        case OpCreateRecordUnifyG:

        {
          auto what = op & OpCreateStructWhatMask;
          auto where = op & OpCreateStructWhereMask;

          bool isStoreMode;
          UnstableNode* writeDest = nullptr;
          RichNode readDest = nullptr;

          switch (where) {
            case OpCreateStructStoreX: {
              isStoreMode = true;
              writeDest = &XPC(3);
              break;
            }

            case OpCreateStructStoreY: {
              isStoreMode = true;
              writeDest = &YPC(3);
              break;
            }

            case OpCreateStructUnifyX: {
              isStoreMode = false;
              readDest = XPC(3);
              break;
            }

            case OpCreateStructUnifyY: {
              isStoreMode = false;
              readDest = YPC(3);
              break;
            }

            case OpCreateStructUnifyG: {
              isStoreMode = false;
              readDest = GPC(3);
              break;
            }

            case OpCreateStructUnifyK: {
              isStoreMode = false;
              readDest = KPC(3);
              break;
            }

            default: {
              assert(false);
              return;
            }
          } // switch (where)

          StaticArray<StableNode> array;
          size_t length = IntPC(2);

          if (isStoreMode || readDest.isTransient()) {
            /* In all these cases, we need to create the structure */
            UnstableNode createdStruct;

            switch (what) {
              case OpCreateStructAbstraction: {
                createdStruct = Abstraction::build(vm, length, KPC(1));
                array = RichNode(createdStruct).as<Abstraction>().getElementsArray();
                break;
              }

              case OpCreateStructCons: {
                assert(length == 2);
                createdStruct = Cons::build(vm);
                array = RichNode(createdStruct).as<Cons>().getElementsArray();
                break;
              }

              case OpCreateStructTuple: {
                createdStruct = Tuple::build(vm, length, KPC(1));
                array = RichNode(createdStruct).as<Tuple>().getElementsArray();
                break;
              }

              case OpCreateStructRecord: {
                createdStruct = Record::build(vm, length, KPC(1));
                array = RichNode(createdStruct).as<Record>().getElementsArray();
                break;
              }

              default: {
                assert(false);
                return;
              }
            }

            /* In some situations, we can short-circuit unification and switch
             * to store mode. */
            if (isStoreMode) {
              *writeDest = std::move(createdStruct);
            } else if (readDest.is<OptVar>()) {
              // Make sure to give an r-value ref, to avoid stabilizing the node
              readDest.as<OptVar>().bind(vm, std::move(createdStruct));
              isStoreMode = true;
            } else if (readDest.is<Variable>()) {
              readDest.as<Variable>().bind(vm, createdStruct);
              isStoreMode = true;
            } else {
              /* In other cases, the bind() method might look at the contents
               * of the created structure (e.g., think of kinded variables).
               * Hence we have to make a true binding with an array that
               * contains meaningful values (i.e., OptVar's). And we cannot
               * switch to store mode.
               */
              for (size_t i = 0; i < length; i++)
                array[i].init(vm, OptVar::build(vm));

              DataflowVariable(readDest).bind(vm, createdStruct);
            }
          } else { // isStoreMode || readDest.isTransient()
            /* Here, we are in unify mode and the destination is not
             * transient. We check if that destination has the right type and
             * shallow structure, and if it has, we fetch its internal array
             * and continue in unify mode.
             * If it fails to meet these requirements, it is a failure.
             *
             * Note that this part of the code has some overlapping with the
             * structural equality tests of Cons, Tuple and Record.
             */

            switch (what) {
              case OpCreateStructAbstraction: {
                // Abstractions have token equality, so it's always a failure
                fail(vm);
              }

              case OpCreateStructCons: {
                if (readDest.is<Cons>()) {
                  array = readDest.as<Cons>().getElementsArray();
                  break;
                } else {
                  fail(vm);
                }
              }

              case OpCreateStructTuple: {
                if (readDest.is<Tuple>() &&
                    (readDest.as<Tuple>().getWidth() == length) &&
                    equals(vm, *readDest.as<Tuple>().getLabel(), KPC(1))) {
                  array = readDest.as<Tuple>().getElementsArray();
                  break;
                } else {
                  fail(vm);
                }
              }

              case OpCreateStructRecord: {
                // Don't test the width. It's not needed and usually it succeeds.
                if (readDest.is<Record>() &&
                    equals(vm, *readDest.as<Record>().getArity(), KPC(1))) {
                  array = readDest.as<Record>().getElementsArray();
                  break;
                } else {
                  fail(vm);
                }
              }

              default: {
                assert(false);
              }
            }
          } // isStoreMode || readDest.isTransient()

          /* Now, `length`, `array` and `isStoreMode` are set appropriately,
           * and we are sure that the shallow structures are OK.
           * We can proceed to filling the array. In store mode, the code is
           * much optimized, of course, and cannot fail.
           * In all cases, all but the three mentioned variables are still
           * needed.
           */

          if (isStoreMode) {
            /* In this mode, nothing can go wrong. We can use PC directly. */
            advancePC(3);

            for (size_t index = 0; index < length; index++) {
              auto subOpCode = *PC;

              switch (subOpCode) {
                case SubOpArrayFillX: {
                  array[index].init(vm, XPC(1));
                  advancePC(1);
                  break;
                }
                case SubOpArrayFillY: {
                  array[index].init(vm, YPC(1));
                  advancePC(1);
                  break;
                }
                case SubOpArrayFillG: {
                  array[index].init(vm, GPC(1));
                  advancePC(1);
                  break;
                }
                case SubOpArrayFillK: {
                  array[index].init(vm, KPC(1));
                  advancePC(1);
                  break;
                }

                case SubOpArrayFillNewVarX: {
                  array[index].init(vm, OptVar::build(vm));
                  XPC(1) = Reference::build(vm, &array[index]);
                  advancePC(1);
                  break;
                }
                case SubOpArrayFillNewVarY: {
                  array[index].init(vm, OptVar::build(vm));
                  YPC(1) = Reference::build(vm, &array[index]);
                  advancePC(1);
                  break;
                }

                case SubOpArrayFillNewVars: {
                  for (size_t count = IntPC(1); count > 0; count--)
                    array[index++].init(vm, OptVar::build(vm));
                  index--;
                  advancePC(1);
                  break;
                }

                default: {
                  assert(false);
                  return;
                }
              }
            }
          } else { // isStoreMode
            /* Here, things get tricky, because inner initialization can
             * suspend, fail or raise exceptions.
             * If we wait, we need to restore PC to the value it had at the
             * beginning, because everything must be replayed when we are
             * waken up.
             */

            backupPC = PC;
            hasBackupPC = true;

            advancePC(3);

            for (size_t index = 0; index < length; index++) {
              auto subOpCode = *PC;

              switch (subOpCode) {
                case SubOpArrayFillX: {
                  unify(vm, array[index], XPC(1));
                  advancePC(1);
                  break;
                }
                case SubOpArrayFillY: {
                  unify(vm, array[index], YPC(1));
                  advancePC(1);
                  break;
                }
                case SubOpArrayFillG: {
                  unify(vm, array[index], GPC(1));
                  advancePC(1);
                  break;
                }
                case SubOpArrayFillK: {
                  unify(vm, array[index], KPC(1));
                  advancePC(1);
                  break;
                }

                case SubOpArrayFillNewVarX: {
                  XPC(1).copy(vm, array[index]);
                  advancePC(1);
                  break;
                }
                case SubOpArrayFillNewVarY: {
                  YPC(1).copy(vm, array[index]);
                  advancePC(1);
                  break;
                }

                case SubOpArrayFillNewVars: {
                  index += (IntPC(1) - 1);
                  advancePC(1);
                  break;
                }

                default: {
                  assert(false);
                  return;
                }
              }
            }

            hasBackupPC = false;
          } // isStoreMode

          break;
        }

        // Inlines for some builtins

        case OpInlineEqualsInteger: {
          if (patternmatching::matches(vm, XPC(1), (nativeint) IntPC(2)))
            advancePC(3);
          else
            advancePC(3 + IntPC(3));

          break;
        }

#include "emulate-inline.cc"

        default: {
          /* We really should not come here, but raising a proper exception
           * helps in debugging. */
          raiseKernelError(vm, MOZART_STR("badOpCode"), (nativeint) op);
        }
      } // Big switch testing the opcode

      // When an opcode is successful, reset the intermediate state
      getIntermediateState().reset(vm);
    } // Big loop iterating over opcodes

  // The big catches clauses that catch all bad things in the world

  } MOZART_CATCH(vm, kind, node) {
    if (hasBackupPC)
      PC = backupPC;

    switch (kind) {
      case ExceptionKind::ekFail: {
        applyFail(vm,
                  abstraction, PC, yregCount, xregs, yregs, gregs, kregs);
        break;
      }

      case ExceptionKind::ekWaitBefore: {
        applyWaitBefore(vm, *node, false,
                        abstraction, PC, yregCount, xregs, yregs, gregs, kregs);
        break;
      }

      case ExceptionKind::ekWaitQuietBefore: {
        applyWaitBefore(vm, *node, true,
                        abstraction, PC, yregCount, xregs, yregs, gregs, kregs);
        break;
      }

      case ExceptionKind::ekRaise: {
        applyRaise(vm, *node,
                   abstraction, PC, yregCount, xregs, yregs, gregs, kregs);
        break;
      }
    }
  } MOZART_ENDTRY(vm);

#undef IntPC
#undef XPC
#undef YPC
#undef GPC
#undef KPC

  if (isTerminated())
    return;

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

void Thread::call(RichNode target, size_t actualArity, bool isTailCall,
                  VM vm, StableNode*& abstraction,
                  ProgramCounter& PC, size_t& yregCount,
                  XRegArray* xregs,
                  StaticArray<UnstableNode>& yregs,
                  StaticArray<StableNode>& gregs,
                  StaticArray<StableNode>& kregs,
                  bool& preempted,
                  std::ptrdiff_t opcodeArgCount) {
  size_t formalArity = 0;
  ProgramCounter start = nullptr;
  size_t Xcount = 0;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  doGetCallInfo(vm, target, formalArity, start, Xcount, Gs, Ks);

  if (actualArity != formalArity) {
    auto actualArgs = vm->newStaticArray<RichNode>(actualArity);
    for (size_t i = 0; i < actualArity; i++)
      actualArgs[i] = (*xregs)[i];

    auto argumentsList = buildListDynamic(vm, actualArity,
                                          (RichNode*) actualArgs);

    vm->deleteStaticArray<RichNode>(actualArgs, actualArity);

    return raiseKernelError(vm, MOZART_STR("arity"),
                            target, std::move(argumentsList));
  }

  advancePC(opcodeArgCount);

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

void Thread::sendMsg(RichNode target, RichNode labelOrArity, size_t width,
                     bool isTailCall,
                     VM vm, StableNode*& abstraction,
                     ProgramCounter& PC, size_t& yregCount,
                     XRegArray* xregs,
                     StaticArray<UnstableNode>& yregs,
                     StaticArray<StableNode>& gregs,
                     StaticArray<StableNode>& kregs,
                     bool& preempted) {
  // "Just make it work" implementation that always delegates to call()

  derefReflectiveTarget(vm, target);
  if (target.isTransient())
    waitFor(vm, target);

  /* Make it stable now, because if the target happens to be referencing x(0),
   * the overriding of x(0) with the message, below, will break the node
   * referenced by target!
   */
  target.ensureStable(vm);

  using namespace patternmatching;

  UnstableNode message;
  StaticArray<StableNode> args;

  if (width == 0) {
    // labelOrArity is the message
    message.init(vm, labelOrArity);
  } else if (labelOrArity.is<Arity>()) {
    // labelOrArity is the arity of the message, which is a record
    message = Record::build(vm, width, labelOrArity);
    args = RichNode(message).as<Record>().getElementsArray();
  } else if ((width == 2) && labelOrArity.is<Atom>() &&
             (labelOrArity.as<Atom>().value() == vm->coreatoms.pipe)) {
    // the message should be a Cons
    message = Cons::build(vm);
    args = RichNode(message).as<Cons>().getElementsArray();
  } else {
    // the message should be a Tuple
    message = Tuple::build(vm, width, labelOrArity);
    args = RichNode(message).as<Tuple>().getElementsArray();
  }

  for (size_t i = 0; i < width; i++)
    args[i].init(vm, (*xregs)[i]);

  (*xregs)[0] = std::move(message);
  call(target, 1, isTailCall,
       vm, abstraction, PC, yregCount,
       xregs, yregs, gregs, kregs, preempted, 3);
}

void Thread::doGetCallInfo(VM vm, RichNode& target, size_t& arity,
                           ProgramCounter& start, size_t& Xcount,
                           StaticArray<StableNode>& Gs,
                           StaticArray<StableNode>& Ks) {
  derefReflectiveTarget(vm, target);
  Callable(target).getCallInfo(vm, arity, start, Xcount, Gs, Ks);
}

void Thread::derefReflectiveTarget(VM vm, RichNode& target) {
  while (target.is<ReflectiveEntity>()) {
    RichNode delegate;
    if (target.as<ReflectiveEntity>().reflectiveCall(
          vm, MOZART_STR("mozart::Thread::doGetCallInfo"),
          MOZART_STR("getCallDelegate"), ozcalls::out(delegate))) {
      target = delegate;
    } else {
      break;
    }
  }
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

  assert(patterns.is<Tuple>());
  auto patternsTuple = patterns.as<Tuple>();
  size_t patternCount = patternsTuple.getWidth();
  auto patternList = patternsTuple.getElementsArray();

  for (size_t index = 0; index < patternCount; index++) {
    RichNode pattern;
    nativeint jumpOffset = 0;

    if (!matchesSharp(vm, patternList[index],
                      capture(pattern), capture(jumpOffset))) {
      assert(false);
      raiseTypeError(vm, MOZART_STR("pattern"), patternList[index]);
    }

    if (mozart::patternMatch(vm, value, pattern, xregs->getArray())) {
      advancePC(2 + jumpOffset);
      return;
    }
  }

  advancePC(2);
}

void Thread::applyFail(VM vm,
                       StableNode*& abstraction,
                       ProgramCounter& PC, size_t& yregCount,
                       XRegArray* xregs,
                       StaticArray<UnstableNode>& yregs,
                       StaticArray<StableNode>& gregs,
                       StaticArray<StableNode>& kregs) {
  if (!vm->isOnTopLevel()) {
    vm->getCurrentSpace()->fail(vm);
  } else {
    UnstableNode error = buildRecord(
      vm, buildArity(vm, vm->coreatoms.failure, vm->coreatoms.debug),
      unit);

    applyRaise(vm, error,
               abstraction, PC, yregCount, xregs, yregs, gregs, kregs);
  }
}

void Thread::applyWaitBefore(VM vm, RichNode waitee, bool isQuiet,
                             StableNode*& abstraction,
                             ProgramCounter& PC, size_t& yregCount,
                             XRegArray* xregs,
                             StaticArray<UnstableNode>& yregs,
                             StaticArray<StableNode>& gregs,
                             StaticArray<StableNode>& kregs) {
  if (getRaiseOnBlock() && (waitee.is<OptVar>() || waitee.is<Variable>())) {
    UnstableNode error = buildRecord(
      vm, buildArity(vm, vm->coreatoms.error, 1, vm->coreatoms.debug),
      buildTuple(vm, vm->coreatoms.kernel, MOZART_STR("block"), waitee), unit);

    applyRaise(vm, error,
               abstraction, PC, yregCount, xregs, yregs, gregs, kregs);
    return;
  }

  if (!isQuiet) {
    if (waitee.is<FailedValue>()) {
      applyRaise(vm, *waitee.as<FailedValue>().getUnderlying(),
                 abstraction, PC, yregCount, xregs, yregs, gregs, kregs);
      return;
    } else {
      DataflowVariable(waitee).markNeeded(vm);
    }
  }

  suspendOnVar(vm, waitee);
}

void Thread::applyRaise(VM vm, RichNode exception,
                        StableNode*& abstraction,
                        ProgramCounter& PC, size_t& yregCount,
                        XRegArray* xregs,
                        StaticArray<UnstableNode>& yregs,
                        StaticArray<StableNode>& gregs,
                        StaticArray<StableNode>& kregs) {
  // Discard any intermediate state
  getIntermediateState().reset(vm);

  UnstableNode preprocessedException = preprocessException(
    vm, exception, abstraction, PC);

  bool handlerFound = stack.findExceptionHandler(
    vm, abstraction, PC, yregCount, yregs, gregs, kregs);

  // Store the exception value in X(0)
  (*xregs)[0].copy(vm, std::move(preprocessedException));

  if (handlerFound) {
    // Nothing to do
  } else {
    RichNode handler = *vm->getPropertyRegistry().getDefaultExceptionHandler();

    // TODO Figure something better here that can cope with Mozart exceptions
    if (!handler.isTransient() && Callable(handler).isProcedure(vm) &&
        (Callable(handler).procedureArity(vm) == 1)) {
      bool dummyPreempted = false;
      call(handler, 1, true,
           vm, abstraction, PC, yregCount, xregs, yregs, gregs, kregs,
           dummyPreempted, -1);
    } else {
      // Uncaught exception
      std::cout << "Uncaught exception" << std::endl;
      std::cout << repr(vm, (*xregs)[0], 100) << std::endl;

      UnstableNode stackTrace = stack.buildStackTrace(vm, abstraction, PC);
      std::cout << repr(vm, stackTrace) << std::endl;

      terminate();
    }
  }
}

UnstableNode Thread::preprocessException(VM vm, RichNode exception,
                                         StableNode* abstraction,
                                         ProgramCounter PC) {
  if (!exception.is<Record>())
    return build(vm, exception);

  auto srcRecord = exception.as<Record>();
  auto arity = RichNode(*srcRecord.getArity()).as<Arity>();

  UnstableNode debugAtom = build(vm, vm->coreatoms.debug);
  size_t debugFeatureIndex = 0;

  if (!arity.lookupFeature(vm, debugAtom, debugFeatureIndex))
    return build(vm, exception);

  if (!RichNode(*srcRecord.getElement(debugFeatureIndex)).is<Unit>())
    return build(vm, exception);

  size_t width = srcRecord.getWidth();
  UnstableNode result = Record::build(vm, width, arity);

  auto destRecord = RichNode(result).as<Record>();
  for (size_t i = 0; i < width; i++) {
    if (i == debugFeatureIndex) {
      UnstableNode stackTrace = stack.buildStackTrace(vm, abstraction, PC);
      UnstableNode debugField = buildRecord(
        vm, buildArity(vm, MOZART_STR("d"), MOZART_STR("info"),
                       MOZART_STR("stack")),
        unit, std::move(stackTrace));
      destRecord.getElement(i)->init(vm, std::move(debugField));
    } else {
      destRecord.getElement(i)->init(vm, *srcRecord.getElement(i));
    }
  }

  return result;
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

void Thread::terminate() {
  Super::terminate();

  auto unitNode = build(vm, unit);
  DataflowVariable(_terminationVar).bind(vm, unitNode);
}

void Thread::dump() {
  std::cerr << "Thread " << this << ", runnable:" << isRunnable() << std::endl;
  UnstableNode stackTrace = stack.buildStackTrace(vm, nullptr, nullptr);
  std::cerr << repr(vm, stackTrace) << std::endl;
}

}

#undef advancePC
