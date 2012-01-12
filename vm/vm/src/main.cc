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
#include "corebuiltins.hh"
#include "stdint.h"

int main(int argc, char **argv) {
  VirtualMachine vm;
  UnstableNode temp;

  // Define the Add builtin

  BuiltinProcedureValue builtinAdd(3, &builtins::add);

  // Define PrintAdd function

  ByteCode printAddCodeBlock[] = {
    OpMoveGX, 0, 3,
    OpCallBuiltin, 3, 3, 0, 1, 4,
    OpUnifyXX, 2, 4,
    OpPrintInt, 2,
    OpReturn
  };

  CodeArea printAddCodeArea(printAddCodeBlock, sizeof(printAddCodeBlock),
    5, 0, nullptr);

  temp.make(vm, BuiltinProcedure::type, &builtinAdd);
  UnstableNode* printAddGs[1] = { &temp };

  AbstractionValue printAdd(3, &printAddCodeArea, 1, printAddGs);

  // Define Main procedure

  ByteCode mainCodeBlock[] = {
    OpMoveKX, 0, 0,
    OpMoveXX, 0, 1,
    OpPrintInt, 1,
    OpAllocateY, 2,
    OpMoveXY, 1, 0,
    OpMoveKX, 1, 0,
    OpCreateVar, 2,
    OpMoveXY, 2, 1,
    OpMoveGX, 0, 3,
    OpCall, 3, 3,
    OpMoveYX, 0, 0,
    OpPrintInt, 0,
    OpMoveYX, 1, 0,
    OpPrintInt, 0,
    OpDeallocateY,
    OpReturn
  };

  UnstableNode five, two;
  five.make<nativeint>(vm, SmallInt::type, 5);
  two.make<nativeint>(vm, SmallInt::type, 2);

  UnstableNode* mainKs[] = { &five, &two };
  CodeArea mainCodeArea(mainCodeBlock, sizeof(mainCodeBlock), 5, 2, mainKs);

  StaticArray<StableNode> mainGs(1);
  temp.make<Abstraction::Repr>(vm, Abstraction::type, &printAdd);
  mainGs[0].init(temp);

  Thread thread(vm, &mainCodeArea, mainGs);

  std::cout << "Initialized" << std::endl;

  thread.run();

  std::cout << "Finished" << std::endl;

  return 0;
}
