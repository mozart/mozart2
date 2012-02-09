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

#include <iostream>

#include "emulate.hh"
#include "vm.hh"
#include "smallint.hh"
#include "callables.hh"
#include "variables.hh"
#include "corebuiltins.hh"
#include "stdint.h"

bool simplePreemption(void* data) {
  static int count = 3;

  if (--count == 0) {
    count = 3;
    return true;
  } else {
    return false;
  }
}

int main(int argc, char **argv) {
  VirtualMachine virtualMachine(simplePreemption);
  VM vm = &virtualMachine;

  // Arguments of the program

  const nativeint N1 = 30; // time of the order of seconds on a 2-3 GHz CPU
  const nativeint N2 = 35;

  // Define the builtins

  UnstableNode builtinEquals;
  builtinEquals.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::equals);
  Reference::makeFor(vm, builtinEquals);

  UnstableNode builtinAdd;
  builtinAdd.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::add);
  Reference::makeFor(vm, builtinAdd);

  // Define immediate constants

  UnstableNode zero, one, minusOne, minusTwo, n1node, n2node;
  zero.make<SmallInt>(vm, 0);
  one.make<SmallInt>(vm, 1);
  minusOne.make<SmallInt>(vm, -1);
  minusTwo.make<SmallInt>(vm, -2);
  n1node.make<SmallInt>(vm, N1);
  n2node.make<SmallInt>(vm, N2);

  // Define Fibonacci function

  /*
   * proc {Fibonacci N Res}
   *    if N == 0 then
   *       Res = 0
   *    elseif N == 1 then
   *       Res = 1
   *    else
   *       {Fibonacci N-1 Left}
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
   * K2 = -1
   * K3 = -2
   * K4 = builtin ==
   * K5 = builtin +
   *
   * G0 = Fibonacci
   *
   * Y0 = N then Right
   * Y1 = Res
   * Y2 = Left
   */

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

    OpInlineMinus1, 0, 2,
    OpMoveMoveXYXY, 0, 0, 1, 1,
    OpMoveXX, 2, 0,
    OpCreateVarMoveY, 2, 1,
    OpCallG, 0, 2,

    OpMoveYX, 0, 0,
    OpMoveKX, 3, 2,
    OpInlineAdd, 0, 2, 3,
    OpMoveXX, 3, 0,
    OpCreateVarMoveY, 0, 1,
    OpCallG, 0, 2,

    OpMoveMoveYXYX, 2, 0, 0, 1,
    OpInlineAdd, 0, 1, 2,
    OpUnifyXY, 2, 1,

    OpDeallocateY,
    OpReturn
  };

  UnstableNode fibonacciCodeArea;
  fibonacciCodeArea.make<CodeArea>(vm, 6, vm, fibonacciCodeBlock,
                                   sizeof(fibonacciCodeBlock), 4);

  ArrayInitializer initFibonacciCodeArea = fibonacciCodeArea.node;
  initFibonacciCodeArea.initElement(vm, 0, &zero);
  initFibonacciCodeArea.initElement(vm, 1, &one);
  initFibonacciCodeArea.initElement(vm, 2, &minusOne);
  initFibonacciCodeArea.initElement(vm, 3, &minusTwo);
  initFibonacciCodeArea.initElement(vm, 4, &builtinEquals);
  initFibonacciCodeArea.initElement(vm, 5, &builtinAdd);

  UnstableNode abstractionFibonacci;
  abstractionFibonacci.make<Abstraction>(vm, 1, vm, 2, &fibonacciCodeArea);

  ArrayInitializer initAbstractionFibonacci = abstractionFibonacci.node;
  initAbstractionFibonacci.initElement(vm, 0, &abstractionFibonacci);

  // The dataflows

  UnstableNode dataflow1, dataflow2;
  dataflow1.make<Unbound>(vm);
  dataflow2.make<Unbound>(vm);

  // Define Main1 procedure

  /*
   * {Fibonacci N1 0 1 R}
   * {Print R}
   * Dataflow1 = R
   */

  /*
   * K0 = N1
   * K1 = 0
   * K2 = 1
   *
   * G0 = Fibonacci
   * G1 = Dataflow1
   *
   * Y0 = R
   */

  ByteCode main1CodeBlock[] = {
    // Allocate Y0 and create R
    OpAllocateY, 1,
    OpCreateVarX, 1,
    OpMoveXY, 1, 0,

    // {Fibonacci N R}
    OpMoveKX, 0, 0,
    OpCallG, 0, 2,

    // {Print R}
    OpMoveYX, 0, 0,
    OpPrint, 0,

    // Dataflow1 = R
    OpUnifyXG, 0, 1,

    // end
    OpDeallocateY,
    OpReturn,
  };

  UnstableNode main1CodeArea;
  main1CodeArea.make<CodeArea>(vm, 3, vm, main1CodeBlock,
                               sizeof(main1CodeBlock), 5);

  ArrayInitializer initMain1CodeArea = main1CodeArea.node;
  initMain1CodeArea.initElement(vm, 0, &n1node);
  initMain1CodeArea.initElement(vm, 1, &zero);
  initMain1CodeArea.initElement(vm, 2, &one);

  UnstableNode abstractionMain1;
  abstractionMain1.make<Abstraction>(vm, 2, vm, 0, &main1CodeArea);

  ArrayInitializer initAbstractionMain1 = abstractionMain1.node;
  initAbstractionMain1.initElement(vm, 0, &abstractionFibonacci);
  initAbstractionMain1.initElement(vm, 1, &dataflow1);

  new (vm) Thread(vm, Reference::getStableRefFor(vm, abstractionMain1));

  // Define Main2 procedure

  /*
   * {Fibonacci N2 0 1 R}
   * {Print R}
   * Dataflow2 = R
   */

  /*
   * K0 = N2
   * K1 = 0
   * K2 = 1
   *
   * G0 = Fibonacci
   * G1 = Dataflow2
   *
   * Y0 = R
   */

  ByteCode main2CodeBlock[] = {
    // Allocate Y0 and create R
    OpAllocateY, 1,
    OpCreateVarX, 1,
    OpMoveXY, 1, 0,

    // {Fibonacci N R}
    OpMoveKX, 0, 0,
    OpCallG, 0, 2,

    // {Print R}
    OpMoveYX, 0, 0,
    OpPrint, 0,

    // Dataflow2 = R
    OpUnifyXG, 0, 1,

    // end
    OpDeallocateY,
    OpReturn,
  };

  UnstableNode main2CodeArea;
  main2CodeArea.make<CodeArea>(vm, 3, vm, main2CodeBlock,
                               sizeof(main2CodeBlock), 5);

  ArrayInitializer initMain2CodeArea = main2CodeArea.node;
  initMain2CodeArea.initElement(vm, 0, &n2node);
  initMain2CodeArea.initElement(vm, 1, &zero);
  initMain2CodeArea.initElement(vm, 2, &one);

  UnstableNode abstractionMain2;
  abstractionMain2.make<Abstraction>(vm, 2, vm, 0, &main2CodeArea);

  ArrayInitializer initAbstractionMain2 = abstractionMain2.node;
  initAbstractionMain2.initElement(vm, 0, &abstractionFibonacci);
  initAbstractionMain2.initElement(vm, 1, &dataflow2);

  new (vm) Thread(vm, Reference::getStableRefFor(vm, abstractionMain2));

  // Define Main3 procedure

  /*
   * R = Dataflow1 + Dataflow2
   * {Print R}
   */

  /*
   * G0 = Dataflow1
   * G1 = Dataflow2
   *
   * X0 = R
   */

  ByteCode main3CodeBlock[] = {
    OpMoveGX, 0, 1,
    OpMoveGX, 1, 2,
    OpInlineAdd, 1, 2, 0,
    OpPrint, 0,

    OpReturn,
  };

  UnstableNode main3CodeArea;
  main3CodeArea.make<CodeArea>(vm, 0, vm, main3CodeBlock,
                               sizeof(main3CodeBlock), 3);

  UnstableNode abstractionMain3;
  abstractionMain3.make<Abstraction>(vm, 2, vm, 0, &main3CodeArea);

  ArrayInitializer initAbstractionMain3 = abstractionMain3.node;
  initAbstractionMain3.initElement(vm, 0, &dataflow1);
  initAbstractionMain3.initElement(vm, 1, &dataflow2);

  new (vm) Thread(vm, Reference::getStableRefFor(vm, abstractionMain3));

  std::cout << "Initialized" << std::endl;

  vm->run();

  std::cout << "Finished" << std::endl;

  return 0;
}
