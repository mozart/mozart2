#include <iostream>
#include "../main/emulate.hh"
#include "../main/vm.hh"
#include "../main/smallint.hh"
#include "../main/callables.hh"
#include "../main/variables.hh"
#include "../main/corebuiltins.hh"
#include "stdint.h"
#include <gtest/gtest.h>

bool simplePreemption(void* data) {
  static int count = 3;

  if (--count == 0) {
    count = 3;
    return true;
  } else {
    return false;
  }
}


TEST(FactorialTests, SmallIntTest) {
  VirtualMachine virtualMachine(simplePreemption);
  VM vm = &virtualMachine;

  // Arguments of the program

  const nativeint N = 35; // time of the order of seconds on a 2-3 GHz CPU

  // Define the builtins

  UnstableNode builtinCreateThread;
  builtinCreateThread.make<BuiltinProcedure>(
					     vm, 1, (OzBuiltin) &builtins::createThread);

  // Define immediate constants

  UnstableNode zero, one, minusOne, minusTwo, nnode;
  zero.make<SmallInt>(vm, 0);
  one.make<SmallInt>(vm, 1);
  minusOne.make<SmallInt>(vm, -1);
  minusTwo.make<SmallInt>(vm, -2);
  nnode.make<SmallInt>(vm, N);

  // Define Fibonacci function

  /*
   * proc {Fibonacci N Res}
   *    if N == 0 then
   *       Res = 0
   *    elseif N == 1 then
   *       Res = 1
   *    else
   *       Left Right
   *    in
   *       thread
   *          {Fibonacci N-1 Left}
   *       end
   *
   *       {Fibonacci N-2 Right}
   *       Res = Left + Right
   *    end
   * end
   */

  /*
   * The bytecode below is equivalent to the one produced by the old compiler,
   * with the exception that AllocateY is done only in the recursive case
   * (our allocation for Y registers is still a standard malloc/free).
   *
   * X0 = N
   * X1 = Res
   *
   * K0 = 0
   * K1 = 1
   * K2 = -2
   * K3 = <CodeArea P>
   * K4 = <Thread.create>
   *
   * G0 = Fibonacci
   *
   * Y0 = N then Right
   * Y1 = Res
   * Y2 = Left
   */

  ByteCode fibonacciInnerCodeBlock[] = {
    OpMoveGX, 0, 0,
    OpInlineMinus1, 0, 2,
    OpMoveXX, 2, 0,
    OpMoveGX, 2, 1,
    OpTailCallG, 1, 2
  };

  UnstableNode fibonacciInnerCodeArea;
  fibonacciInnerCodeArea.make<CodeArea>(vm, 0, fibonacciInnerCodeBlock,
                                        sizeof(fibonacciInnerCodeBlock), 3);

  ByteCode fibonacciCodeBlock[] = {
    // if N == 0
    OpInlineEqualsInteger, 0, 0, 4,

    // then
    //    Res = 0
    OpUnifyXK, 1, 0,
    OpReturn,

    // elseif N == 1
    OpInlineEqualsInteger, 0, 1, 4,

    // then
    //    Res = 1
    OpUnifyXK, 1, 1,
    OpReturn,

    // else

    OpAllocateY, 3,

    OpCreateVarY, 0,

    OpCreateAbstractionK, 0, 3, 3, 2,
    OpArrayInitElementX, 2, 0, 0,
    OpArrayInitElementG, 2, 1, 0,
    OpArrayInitElementY, 2, 2, 0,

    //OpCallBuiltin, 4, 1, 2,
    OpMoveMoveXYXY, 0, 1, 1, 2,
    OpCallX, 2, 0,
    OpMoveMoveYXYX, 1, 0, 2, 1,

    OpMoveKX, 2, 2,
    OpInlineAdd, 0, 2, 3,
    OpMoveXY, 1, 1,
    OpMoveXX, 3, 0,
    OpCreateVarMoveY, 2, 1,
    OpCallG, 0, 2,

    OpMoveMoveYXYX, 0, 0, 2, 1,
    OpInlineAdd, 0, 1, 2,
    OpUnifyXY, 2, 1,

    OpDeallocateY,
    OpReturn,
  };

  UnstableNode fibonacciCodeArea;
  fibonacciCodeArea.make<CodeArea>(vm, 5, fibonacciCodeBlock,
                                   sizeof(fibonacciCodeBlock), 4);

  ArrayInitializer initFibonacciCodeArea = fibonacciCodeArea.node;
  initFibonacciCodeArea.initElement(vm, 0, &zero);
  initFibonacciCodeArea.initElement(vm, 1, &one);
  initFibonacciCodeArea.initElement(vm, 2, &minusTwo);
  initFibonacciCodeArea.initElement(vm, 3, &fibonacciInnerCodeArea);
  initFibonacciCodeArea.initElement(vm, 4, &builtinCreateThread);

  UnstableNode abstractionFibonacci;
  abstractionFibonacci.make<Abstraction>(vm, 1, 2, &fibonacciCodeArea);

  ArrayInitializer initAbstractionFibonacci = abstractionFibonacci.node;
  initAbstractionFibonacci.initElement(vm, 0, &abstractionFibonacci);

  // Define Main procedure

  /*
   * {Fibonacci N R}
   * {Print R}
   */

  /*
   * K0 = N
   *
   * G0 = Fibonacci
   *
   * Y0 = R
   */

  ByteCode mainCodeBlock[] = {
    // Allocate Y0 and create R
    OpAllocateY, 1,
    OpCreateVarMoveY, 0, 1,

    // {Fibonacci N R}
    OpMoveKX, 0, 0,
    OpCallG, 0, 2,

    // {Print R}
    OpMoveYX, 0, 0,
    OpPrint, 0,

    // end
    OpDeallocateY,
    OpReturn,
  };

  UnstableNode mainCodeArea;
  mainCodeArea.make<CodeArea>(vm, 1, mainCodeBlock,
                              sizeof(mainCodeBlock), 2);

  ArrayInitializer initMainCodeArea = mainCodeArea.node;
  initMainCodeArea.initElement(vm, 0, &nnode);

  UnstableNode abstractionMain;
  abstractionMain.make<Abstraction>(vm, 1, 0, &mainCodeArea);

  ArrayInitializer initAbstractionMain = abstractionMain.node;
  initAbstractionMain.initElement(vm, 0, &abstractionFibonacci);

  UnstableNode* initialThreadParams[] = { &abstractionMain };
  builtins::createThread(vm, initialThreadParams);

  vm->run();

}

TEST(FactorialTests, FloatTest) {

 VirtualMachine virtualMachine(simplePreemption);
  VM vm = &virtualMachine;

  // Arguments of the program

  const nativeint N = 35; // time of the order of seconds on a 2-3 GHz CPU

  // Define the builtins

  UnstableNode builtinCreateThread;
  builtinCreateThread.make<BuiltinProcedure>(
					     vm, 1, (OzBuiltin) &builtins::createThread);

  // Define immediate constants

  UnstableNode zero, one, minusOne, minusTwo, nnode;
  zero.make<Float>(vm, 0.0f);
  one.make<Float>(vm, 1.0f);
  minusOne.make<Float>(vm, -1.0f);
  minusTwo.make<Float>(vm, -2.0f);
  nnode.make<SmallInt>(vm, N);

  // Define Fibonacci function

  /*
   * proc {Fibonacci N Res}
   *    if N == 0 then
   *       Res = 0
   *    elseif N == 1 then
   *       Res = 1
   *    else
   *       Left Right
   *    in
   *       thread
   *          {Fibonacci N-1 Left}
   *       end
   *
   *       {Fibonacci N-2 Right}
   *       Res = Left + Right
   *    end
   * end
   */

  /*
   * The bytecode below is equivalent to the one produced by the old compiler,
   * with the exception that AllocateY is done only in the recursive case
   * (our allocation for Y registers is still a standard malloc/free).
   *
   * X0 = N
   * X1 = Res
   *
   * K0 = 0
   * K1 = 1
   * K2 = -2
   * K3 = <CodeArea P>
   * K4 = <Thread.create>
   *
   * G0 = Fibonacci
   *
   * Y0 = N then Right
   * Y1 = Res
   * Y2 = Left
   */

  ByteCode fibonacciInnerCodeBlock[] = {
    OpMoveGX, 0, 0,
    OpInlineMinus1, 0, 2,
    OpMoveXX, 2, 0,
    OpMoveGX, 2, 1,
    OpTailCallG, 1, 2
  };

  UnstableNode fibonacciInnerCodeArea;
  fibonacciInnerCodeArea.make<CodeArea>(vm, 0, fibonacciInnerCodeBlock,
                                        sizeof(fibonacciInnerCodeBlock), 3);

  ByteCode fibonacciCodeBlock[] = {
    // if N == 0
    OpInlineEqualsInteger, 0, 0, 4,

    // then
    //    Res = 0
    OpUnifyXK, 1, 0,
    OpReturn,

    // elseif N == 1
    OpInlineEqualsInteger, 0, 1, 4,

    // then
    //    Res = 1
    OpUnifyXK, 1, 1,
    OpReturn,

    // else

    OpAllocateY, 3,

    OpCreateVarY, 0,

    OpCreateAbstractionK, 0, 3, 3, 2,
    OpArrayInitElementX, 2, 0, 0,
    OpArrayInitElementG, 2, 1, 0,
    OpArrayInitElementY, 2, 2, 0,

    //OpCallBuiltin, 4, 1, 2,
    OpMoveMoveXYXY, 0, 1, 1, 2,
    OpCallX, 2, 0,
    OpMoveMoveYXYX, 1, 0, 2, 1,

    OpMoveKX, 2, 2,
    OpInlineAdd, 0, 2, 3,
    OpMoveXY, 1, 1,
    OpMoveXX, 3, 0,
    OpCreateVarMoveY, 2, 1,
    OpCallG, 0, 2,

    OpMoveMoveYXYX, 0, 0, 2, 1,
    OpInlineAdd, 0, 1, 2,
    OpUnifyXY, 2, 1,

    OpDeallocateY,
    OpReturn,
  };

  UnstableNode fibonacciCodeArea;
  fibonacciCodeArea.make<CodeArea>(vm, 5, fibonacciCodeBlock,
                                   sizeof(fibonacciCodeBlock), 4);

  ArrayInitializer initFibonacciCodeArea = fibonacciCodeArea.node;
  initFibonacciCodeArea.initElement(vm, 0, &zero);
  initFibonacciCodeArea.initElement(vm, 1, &one);
  initFibonacciCodeArea.initElement(vm, 2, &minusTwo);
  initFibonacciCodeArea.initElement(vm, 3, &fibonacciInnerCodeArea);
  initFibonacciCodeArea.initElement(vm, 4, &builtinCreateThread);

  UnstableNode abstractionFibonacci;
  abstractionFibonacci.make<Abstraction>(vm, 1, 2, &fibonacciCodeArea);

  ArrayInitializer initAbstractionFibonacci = abstractionFibonacci.node;
  initAbstractionFibonacci.initElement(vm, 0, &abstractionFibonacci);

  // Define Main procedure

  /*
   * {Fibonacci N R}
   * {Print R}
   */

  /*
   * K0 = N
   *
   * G0 = Fibonacci
   *
   * Y0 = R
   */

  ByteCode mainCodeBlock[] = {
    // Allocate Y0 and create R
    OpAllocateY, 1,
    OpCreateVarMoveY, 0, 1,

    // {Fibonacci N R}
    OpMoveKX, 0, 0,
    OpCallG, 0, 2,

    // {Print R}
    OpMoveYX, 0, 0,
    OpPrint, 0,

    // end
    OpDeallocateY,
    OpReturn,
  };

  UnstableNode mainCodeArea;
  mainCodeArea.make<CodeArea>(vm, 1, mainCodeBlock,
                              sizeof(mainCodeBlock), 2);

  ArrayInitializer initMainCodeArea = mainCodeArea.node;
  initMainCodeArea.initElement(vm, 0, &nnode);

  UnstableNode abstractionMain;
  abstractionMain.make<Abstraction>(vm, 1, 0, &mainCodeArea);

  ArrayInitializer initAbstractionMain = abstractionMain.node;
  initAbstractionMain.initElement(vm, 0, &abstractionFibonacci);

  UnstableNode* initialThreadParams[] = { &abstractionMain };
  builtins::createThread(vm, initialThreadParams);

  vm->run();
}
