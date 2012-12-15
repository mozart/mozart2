// Copyright © 2012, Université catholique de Louvain
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

#include <mozart.hh>
#include <boostenv.hh>

#include <iostream>
#include <fstream>

using namespace mozart;

void createThreadFromOZB(VM vm, const char* functorName,
                         RichNode baseEnv, RichNode bootMM) {
  std::string fileName = std::string(functorName) + ".ozb";
  std::ifstream input(fileName);
  UnstableNode codeArea = bootUnpickle(vm, input);

  UnstableNode abstraction = Abstraction::build(vm, 2, codeArea);
  auto globalsArray =
    RichNode(abstraction).as<Abstraction>().getElementsArray();

  globalsArray[0].init(vm, baseEnv);
  globalsArray[1].init(vm, bootMM);

  new (vm) Thread(vm, vm->getTopLevelSpace(), abstraction);
}

int main(int argc, char** argv) {
  boostenv::BoostBasedVM boostBasedVM;
  VM vm = boostBasedVM.vm;

  if (argc >= 2) {
    boostBasedVM.setApplicationURL(argv[1]);
    boostBasedVM.setApplicationArgs(argc-2, argv+2);
  } else {
    boostBasedVM.setApplicationURL(u8"x-oz://system/OPI.ozf");
    boostBasedVM.setApplicationArgs(0, nullptr);
  }

  UnstableNode baseEnv = OptVar::build(vm);
  UnstableNode bootMM = OptVar::build(vm);

  vm->getPropertyRegistry().registerConstantProp(
    vm, MOZART_STR("internal.bootmm"), bootMM);

  createThreadFromOZB(vm, "Base", baseEnv, bootMM);
  createThreadFromOZB(vm, "OPI", baseEnv, bootMM);
  createThreadFromOZB(vm, "Emacs", baseEnv, bootMM);
  createThreadFromOZB(vm, "OPIServer", baseEnv, bootMM);
  createThreadFromOZB(vm, "OPIEnv", baseEnv, bootMM);
  createThreadFromOZB(vm, "Space", baseEnv, bootMM);
  createThreadFromOZB(vm, "System", baseEnv, bootMM);
  createThreadFromOZB(vm, "Property", baseEnv, bootMM);
  createThreadFromOZB(vm, "Listener", baseEnv, bootMM);
  createThreadFromOZB(vm, "Type", baseEnv, bootMM);
  createThreadFromOZB(vm, "ErrorListener", baseEnv, bootMM);
  createThreadFromOZB(vm, "ObjectSupport", baseEnv, bootMM);
  createThreadFromOZB(vm, "CompilerSupport", baseEnv, bootMM);
  createThreadFromOZB(vm, "Narrator", baseEnv, bootMM);
  createThreadFromOZB(vm, "DefaultURL", baseEnv, bootMM);
  createThreadFromOZB(vm, "Init", baseEnv, bootMM);
  createThreadFromOZB(vm, "Error", baseEnv, bootMM);
  createThreadFromOZB(vm, "ErrorFormatters", baseEnv, bootMM);
  createThreadFromOZB(vm, "Open", baseEnv, bootMM);
  createThreadFromOZB(vm, "Combinator", baseEnv, bootMM);
  createThreadFromOZB(vm, "RecordC", baseEnv, bootMM);
  createThreadFromOZB(vm, "URL", baseEnv, bootMM);
  createThreadFromOZB(vm, "Application", baseEnv, bootMM);
  createThreadFromOZB(vm, "OS", baseEnv, bootMM);
  createThreadFromOZB(vm, "Annotate", baseEnv, bootMM);
  createThreadFromOZB(vm, "Assembler", baseEnv, bootMM);
  createThreadFromOZB(vm, "BackquoteMacro", baseEnv, bootMM);
  createThreadFromOZB(vm, "Builtins", baseEnv, bootMM);
  createThreadFromOZB(vm, "CodeEmitter", baseEnv, bootMM);
  createThreadFromOZB(vm, "CodeGen", baseEnv, bootMM);
  createThreadFromOZB(vm, "CodeStore", baseEnv, bootMM);
  createThreadFromOZB(vm, "Compiler", baseEnv, bootMM);
  createThreadFromOZB(vm, "Core", baseEnv, bootMM);
  createThreadFromOZB(vm, "ForLoop", baseEnv, bootMM);
  createThreadFromOZB(vm, "GroundZip", baseEnv, bootMM);
  createThreadFromOZB(vm, "Macro", baseEnv, bootMM);
  createThreadFromOZB(vm, "PrintName", baseEnv, bootMM);
  createThreadFromOZB(vm, "RunTime", baseEnv, bootMM);
  createThreadFromOZB(vm, "StaticAnalysis", baseEnv, bootMM);
  createThreadFromOZB(vm, "Unnester", baseEnv, bootMM);
  createThreadFromOZB(vm, "WhileLoop", baseEnv, bootMM);
  createThreadFromOZB(vm, "NewAssembler", baseEnv, bootMM);
  createThreadFromOZB(vm, "Parser", baseEnv, bootMM);
  createThreadFromOZB(vm, "PEG", baseEnv, bootMM);

  boostBasedVM.run();

  {
    auto runAtom = build(vm, MOZART_STR("run"));
    auto runProc = Dottable(bootMM).dot(vm, runAtom);
    new (vm) Thread(vm, vm->getTopLevelSpace(), runProc);
  }

  boostBasedVM.run();
}
