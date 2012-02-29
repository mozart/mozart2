
#include <iostream>

#include "mozartcore.hh"
#include "emulate.hh"
#include "coreinterfaces.hh"
#include "corebuiltins.hh"

bool simplePreemption(void* data) {
  static int count = 3;

  if (--count == 0) {
    count = 3;
    return true;
  } else {
    return false;
  }
}

class Program {
public:
  Program();

  void run();
private:
  VirtualMachine virtualMachine;
  VM vm;
  UnstableNode* topLevelAbstraction;

  UnstableNode* codeArea2;
  void createCodeArea2();

  UnstableNode* codeArea3;
  void createCodeArea3();

  UnstableNode* codeArea4;
  void createCodeArea4();

};

int main(int argc, char** argv) {
  Program program;
  program.run();
}

Program::Program() : virtualMachine(simplePreemption),
  vm(&virtualMachine) {

  createCodeArea4();
  createCodeArea3();
  createCodeArea2();

}

void Program::run() {
  UnstableNode topLevelAbstraction;
  topLevelAbstraction.make<Abstraction>(vm, 0, 0, codeArea2);

  UnstableNode* initialThreadParams[] = { &topLevelAbstraction };
  builtins::createThread(vm, initialThreadParams);

  vm->run();
}

/*
<TopLevel>: P/0
  formals:
  locals: Fibonacci~16 `x$32`~32 `x$33`~33
  globals:

Fibonacci = {CreateAbstraction '<TopLevel>::Fibonacci' [Fibonacci]}
`x$33` = 10
{Fibonacci `x$33`
           `x$32`}
{Show `x$32`}

constants: <CodeArea <TopLevel>::Fibonacci> 10 Show~15

OpAllocateY, 3
OpCreateVarY, 0
OpCreateVarY, 1
OpCreateVarY, 2
OpCreateAbstractionK, 2, 0, 1, 0
OpArrayInitElementY, 0, 0, 0
OpUnifyXY, 0, 0
OpMoveKX, 1, 0
OpUnifyXY, 0, 2
OpMoveYX, 2, 0
OpMoveYX, 1, 1
OpMoveYX, 0, 2
OpCallX, 2, 2
OpMoveYX, 1, 0
OpCallBuiltin, 2, 1, 0
OpDeallocateY
OpReturn

*/

void Program::createCodeArea2() {
  ByteCode codeBlock[] = {
    OpAllocateY, 3,
    OpCreateVarY, 0,
    OpCreateVarY, 1,
    OpCreateVarY, 2,
    OpCreateAbstractionK, 2, 0, 1, 0,
    OpArrayInitElementY, 0, 0, 0,
    OpUnifyXY, 0, 0,
    OpMoveKX, 1, 0,
    OpUnifyXY, 0, 2,
    OpMoveYX, 2, 0,
    OpMoveYX, 1, 1,
    OpMoveYX, 0, 2,
    OpCallX, 2, 2,
    OpMoveYX, 1, 0,
    OpCallBuiltin, 2, 1, 0,
    OpDeallocateY,
    OpReturn,

  };

  codeArea2 = new (vm) UnstableNode;
  codeArea2->make<CodeArea>(vm, 3, codeBlock, sizeof(codeBlock), 3);

  ArrayInitializer initializer = codeArea2->node;
  UnstableNode temp;
  temp.copy(vm, *codeArea3);
  initializer.initElement(vm, 0, &temp);
  temp.make<SmallInt>(vm, 10);
  initializer.initElement(vm, 1, &temp);
  temp.make<BuiltinProcedure>(vm, 1, (OzBuiltin) &builtins::show);
  initializer.initElement(vm, 2, &temp);

}

/*
<TopLevel>::Fibonacci: P/2
  formals: N~17 <Result>~18
  locals: `x$30`~30 `x$31`~31 `x$28`~28 `x$29`~29 `x$21`~21 `x$22`~22 `x$19`~19 `x$23`~23 `x$26`~26 `x$27`~27
  globals: Fibonacci~37

`x$31` = 0
{Value.'==' N
            `x$31`
            `x$30`}
if `x$30` then
   <Result> = 0
else
   `x$29` = 1
   {Value.'==' N
               `x$29`
               `x$28`}
   if `x$28` then
      <Result> = 1
   else
      `x$23` = {CreateAbstraction '<TopLevel>::Fibonacci::' [N Fibonacci `x$19`]}
      {CreateThread `x$23`}
      `x$21` = `x$19`
      `x$27` = 2
      {Number.'-' N
                  `x$27`
                  `x$26`}
      {Fibonacci `x$26`
                 `x$22`}
      {Number.'+' `x$21`
                  `x$22`
                  <Result>}
   end
end

constants: 0 Value.'=='~3 1 <CodeArea <TopLevel>::Fibonacci::> CreateThread~20 2 Number.'-'~6 Number.'+'~5

OpAllocateY, 12
OpMoveXY, 0, 0
OpMoveXY, 1, 1
OpCreateVarY, 2
OpCreateVarY, 3
OpCreateVarY, 4
OpCreateVarY, 5
OpCreateVarY, 6
OpCreateVarY, 7
OpCreateVarY, 8
OpCreateVarY, 9
OpCreateVarY, 10
OpCreateVarY, 11
OpMoveKX, 0, 0
OpUnifyXY, 0, 3
OpMoveYX, 0, 0
OpMoveYX, 3, 1
OpCallBuiltin, 1, 3, 0, 1, 2
OpUnifyXY, 2, 2
OpMoveYX, 2, 0
OpCondBranch, 0, 8, 0, 0
OpMoveKX, 0, 0
OpUnifyXY, 0, 1
OpBranch, 115
OpMoveKX, 2, 0
OpUnifyXY, 0, 5
OpMoveYX, 0, 0
OpMoveYX, 5, 1
OpCallBuiltin, 1, 3, 0, 1, 2
OpUnifyXY, 2, 4
OpMoveYX, 4, 0
OpCondBranch, 0, 8, 0, 0
OpMoveKX, 2, 0
OpUnifyXY, 0, 1
OpBranch, 78
OpCreateAbstractionK, 0, 3, 3, 0
OpArrayInitElementY, 0, 0, 0
OpArrayInitElementG, 0, 1, 0
OpArrayInitElementY, 0, 2, 8
OpUnifyXY, 0, 9
OpMoveYX, 9, 0
OpCallBuiltin, 4, 1, 0
OpMoveYX, 6, 0
OpUnifyXY, 0, 8
OpMoveKX, 5, 0
OpUnifyXY, 0, 11
OpMoveYX, 0, 0
OpMoveYX, 11, 1
OpCallBuiltin, 6, 3, 0, 1, 2
OpUnifyXY, 2, 10
OpMoveYX, 10, 0
OpMoveYX, 7, 1
OpCallG, 0, 2
OpMoveYX, 6, 0
OpMoveYX, 7, 1
OpCallBuiltin, 7, 3, 0, 1, 2
OpUnifyXY, 2, 1
OpDeallocateY
OpReturn

*/

void Program::createCodeArea3() {
  ByteCode codeBlock[] = {
    OpAllocateY, 12,
    OpMoveXY, 0, 0,
    OpMoveXY, 1, 1,
    OpCreateVarY, 2,
    OpCreateVarY, 3,
    OpCreateVarY, 4,
    OpCreateVarY, 5,
    OpCreateVarY, 6,
    OpCreateVarY, 7,
    OpCreateVarY, 8,
    OpCreateVarY, 9,
    OpCreateVarY, 10,
    OpCreateVarY, 11,
    OpMoveKX, 0, 0,
    OpUnifyXY, 0, 3,
    OpMoveYX, 0, 0,
    OpMoveYX, 3, 1,
    OpCallBuiltin, 1, 3, 0, 1, 2,
    OpUnifyXY, 2, 2,
    OpMoveYX, 2, 0,
    OpCondBranch, 0, 8, 0, 0,
    OpMoveKX, 0, 0,
    OpUnifyXY, 0, 1,
    OpBranch, 115,
    OpMoveKX, 2, 0,
    OpUnifyXY, 0, 5,
    OpMoveYX, 0, 0,
    OpMoveYX, 5, 1,
    OpCallBuiltin, 1, 3, 0, 1, 2,
    OpUnifyXY, 2, 4,
    OpMoveYX, 4, 0,
    OpCondBranch, 0, 8, 0, 0,
    OpMoveKX, 2, 0,
    OpUnifyXY, 0, 1,
    OpBranch, 78,
    OpCreateAbstractionK, 0, 3, 3, 0,
    OpArrayInitElementY, 0, 0, 0,
    OpArrayInitElementG, 0, 1, 0,
    OpArrayInitElementY, 0, 2, 8,
    OpUnifyXY, 0, 9,
    OpMoveYX, 9, 0,
    OpCallBuiltin, 4, 1, 0,
    OpMoveYX, 6, 0,
    OpUnifyXY, 0, 8,
    OpMoveKX, 5, 0,
    OpUnifyXY, 0, 11,
    OpMoveYX, 0, 0,
    OpMoveYX, 11, 1,
    OpCallBuiltin, 6, 3, 0, 1, 2,
    OpUnifyXY, 2, 10,
    OpMoveYX, 10, 0,
    OpMoveYX, 7, 1,
    OpCallG, 0, 2,
    OpMoveYX, 6, 0,
    OpMoveYX, 7, 1,
    OpCallBuiltin, 7, 3, 0, 1, 2,
    OpUnifyXY, 2, 1,
    OpDeallocateY,
    OpReturn,

  };

  codeArea3 = new (vm) UnstableNode;
  codeArea3->make<CodeArea>(vm, 8, codeBlock, sizeof(codeBlock), 3);

  ArrayInitializer initializer = codeArea3->node;
  UnstableNode temp;
  temp.make<SmallInt>(vm, 0);
  initializer.initElement(vm, 0, &temp);
  temp.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::equals);
  initializer.initElement(vm, 1, &temp);
  temp.make<SmallInt>(vm, 1);
  initializer.initElement(vm, 2, &temp);
  temp.copy(vm, *codeArea4);
  initializer.initElement(vm, 3, &temp);
  temp.make<BuiltinProcedure>(vm, 1, (OzBuiltin) &builtins::createThread);
  initializer.initElement(vm, 4, &temp);
  temp.make<SmallInt>(vm, 2);
  initializer.initElement(vm, 5, &temp);
  temp.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::subtract);
  initializer.initElement(vm, 6, &temp);
  temp.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::add);
  initializer.initElement(vm, 7, &temp);

}

/*
<TopLevel>::Fibonacci::: P/0
  formals:
  locals: `x$24`~24 `x$25`~25
  globals: N~34 Fibonacci~35 `x$19`~36

`x$25` = 1
{Number.'-' N
            `x$25`
            `x$24`}
{Fibonacci `x$24`
           `x$19`}

constants: 1 Number.'-'~6

OpAllocateY, 2
OpCreateVarY, 0
OpCreateVarY, 1
OpMoveKX, 0, 0
OpUnifyXY, 0, 1
OpMoveGX, 0, 0
OpMoveYX, 1, 1
OpCallBuiltin, 1, 3, 0, 1, 2
OpUnifyXY, 2, 0
OpMoveYX, 0, 0
OpMoveGX, 2, 1
OpCallG, 1, 2
OpDeallocateY
OpReturn

*/

void Program::createCodeArea4() {
  ByteCode codeBlock[] = {
    OpAllocateY, 2,
    OpCreateVarY, 0,
    OpCreateVarY, 1,
    OpMoveKX, 0, 0,
    OpUnifyXY, 0, 1,
    OpMoveGX, 0, 0,
    OpMoveYX, 1, 1,
    OpCallBuiltin, 1, 3, 0, 1, 2,
    OpUnifyXY, 2, 0,
    OpMoveYX, 0, 0,
    OpMoveGX, 2, 1,
    OpCallG, 1, 2,
    OpDeallocateY,
    OpReturn,

  };

  codeArea4 = new (vm) UnstableNode;
  codeArea4->make<CodeArea>(vm, 2, codeBlock, sizeof(codeBlock), 3);

  ArrayInitializer initializer = codeArea4->node;
  UnstableNode temp;
  temp.make<SmallInt>(vm, 1);
  initializer.initElement(vm, 0, &temp);
  temp.make<BuiltinProcedure>(vm, 3, (OzBuiltin) &builtins::subtract);
  initializer.initElement(vm, 1, &temp);

}
