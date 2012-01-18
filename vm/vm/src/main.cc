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
  VirtualMachine vm;

  // Arguments of the program

  const nativeint N = sizeof(nativeint) == 8 ? 92 : 46; // max without overflow

  // Define the builtins

  UnstableNode builtinEquals;
  builtinEquals.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::equals);
  Reference::makeFor(vm, builtinEquals);

  UnstableNode builtinAdd;
  builtinAdd.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::add);
  Reference::makeFor(vm, builtinAdd);

  // Define immediate constants

  UnstableNode zero, minusOne, one, nnode;
  zero.make<SmallInt>(vm, 0);
  minusOne.make<SmallInt>(vm, -1);
  one.make<SmallInt>(vm, 1);
  nnode.make<SmallInt>(vm, N);

  // Define Fibonacci function

  /*
   * proc {Fibonacci N Acc1 Acc2 Res}
   *    if N == 0 then
   *       Res = Acc1
   *    else
   *       NewN = N - 1
   *       NewAcc1 = Acc2
   *       NewAcc2 = Acc1 + Acc2
   *       {Fibonacci NewN NewAcc1 NewAcc2}
   *    end
   * end
   */

  /*
   * X0 = N
   * X1 = Acc1
   * X2 = Acc2
   * X3 = Res
   *
   * K0 = 0
   * K1 = -1
   * K2 = builtin ==
   * K3 = builtin +
   *
   * G0 = Fibonacci
   *
   * X4 = N == 0
   * X5 = NewN
   * X6 = NewAcc1
   * X7 = NewAcc2
   *
   * X8 = Temp
   */

  ByteCode fibonacciCodeBlock[] = {
    // if N == 0
    OpMoveKX, 0, 8,
    OpCallBuiltin, 2, 3, 0, 8, 4,
    OpCondBranch, 4, 9, 5, 0,

    // error
    OpMoveKX, 1, 8,
    OpPrintInt, 8,

    // then
    //    Res = Acc1
    OpUnifyXX, 3, 1,
    OpReturn,

    // else
    OpMoveKX, 1, 8,
    OpCallBuiltin, 3, 3, 0, 8, 5, // NewN = N - 1
    OpMoveXX, 2, 6,               // NewAcc1 = Acc2
    OpCallBuiltin, 3, 3, 1, 2, 7, // NewAcc2 = Acc1 + Acc2

    // {Fibonacci NewN NewAcc1 NewAcc2 Res}
    OpMoveXX, 5, 0,
    OpMoveXX, 6, 1,
    OpMoveXX, 7, 2,
    OpMoveGX, 0, 8,
    OpTailCall, 8, 4
  };

  UnstableNode* fibonacciKs[] =
    { &zero, &minusOne, &builtinEquals, &builtinAdd };
  CodeArea fibonacciCodeArea(vm, fibonacciCodeBlock, sizeof(fibonacciCodeBlock),
    9, 4, fibonacciKs);

  UnstableNode recursiveFibonacci;
  recursiveFibonacci.make<Unbound>(vm);

  UnstableNode* fibonacciGs[1] = { &recursiveFibonacci };

  UnstableNode abstractionFibonacci;
  abstractionFibonacci.make<Abstraction>(vm, vm, 4, &fibonacciCodeArea,
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
    OpCreateVar, 3,
    OpMoveXY, 3, 0,

    // {Fibonacci N 0 1 R}
    OpMoveKX, 0, 0,
    OpMoveKX, 1, 1,
    OpMoveKX, 2, 2,
    OpMoveGX, 0, 4,
    OpCall, 4, 4,

    // {Print R}
    OpMoveYX, 0, 0,
    OpPrintInt, 0,

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
