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

int main(int argc, char **argv) {
  VirtualMachine virtualMachine;
  VM vm = &virtualMachine;

  // Arguments of the program

  const nativeint N = 35; // time of the order of seconds on a 2-3 GHz CPU

  // Define the builtins

  UnstableNode builtinEquals;
  builtinEquals.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::equals);
  Reference::makeFor(vm, builtinEquals);

  UnstableNode builtinAdd;
  builtinAdd.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::add);
  Reference::makeFor(vm, builtinAdd);

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

  UnstableNode* fibonacciKs[] =
    { &zero, &one, &minusOne, &minusTwo, &builtinEquals, &builtinAdd };
  CodeArea fibonacciCodeArea(vm, fibonacciCodeBlock, sizeof(fibonacciCodeBlock),
    4, 6, fibonacciKs);

  UnstableNode recursiveFibonacci;
  recursiveFibonacci.make<Unbound>(vm);

  UnstableNode* fibonacciGs[1] = { &recursiveFibonacci };

  UnstableNode abstractionFibonacci;
  abstractionFibonacci.make<Abstraction>(vm, vm, 2, &fibonacciCodeArea,
                                         1, fibonacciGs);
  Reference::makeFor(vm, abstractionFibonacci);
  IMPL(void, Unbound, bind, &Reference::dereference(recursiveFibonacci.node),
       vm, &Reference::dereference(abstractionFibonacci.node));

  // Define Main procedure

  /*
   * {Fibonacci N 0 1 R}
   * {Print R}
   */

  /*
   * K0 = N
   * K1 = 0
   * K2 = 1
   *
   * G0 = Fibonacci
   *
   * Y0 = R
   */

  ByteCode mainCodeBlock[] = {
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

    // end
    OpDeallocateY,
    OpReturn,
  };

  UnstableNode* mainKs[] = { &nnode, &zero, &one };
  CodeArea mainCodeArea(vm, mainCodeBlock, sizeof(mainCodeBlock), 5, 3, mainKs);

  StaticArray<StableNode> mainGs(1);
  mainGs[0].init(vm, abstractionFibonacci);

  Thread thread(vm, &mainCodeArea, mainGs);

  std::cout << "Initialized" << std::endl;

  thread.run();

  std::cout << "Finished" << std::endl;

  return 0;
}
