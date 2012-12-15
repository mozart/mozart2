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

void createThreadFromOZB(VM vm, const char* functorName) {
  std::string fileName = std::string(functorName) + ".ozb";
  std::ifstream input(fileName);
  UnstableNode codeArea = bootUnpickle(vm, input);

  UnstableNode abstraction = Abstraction::build(vm, 0, codeArea);

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

  UnstableNode bootVirtualFS = OptVar::build(vm);
  UnstableNode runProc = OptVar::build(vm);
  UnstableNode baseEnv = OptVar::build(vm);

  vm->getPropertyRegistry().registerConstantProp(
    vm, MOZART_STR("internal.boot.virtualfs"), bootVirtualFS);
  vm->getPropertyRegistry().registerConstantProp(
    vm, MOZART_STR("internal.boot.run"), runProc);
  vm->getPropertyRegistry().registerConstantProp(
    vm, MOZART_STR("internal.boot.base"), baseEnv);

  createThreadFromOZB(vm, "Base");

  boostBasedVM.run();

  createThreadFromOZB(vm, "OPI");
  createThreadFromOZB(vm, "Emacs");
  createThreadFromOZB(vm, "OPIServer");
  createThreadFromOZB(vm, "OPIEnv");
  createThreadFromOZB(vm, "Space");
  createThreadFromOZB(vm, "System");
  createThreadFromOZB(vm, "Property");
  createThreadFromOZB(vm, "Listener");
  createThreadFromOZB(vm, "Type");
  createThreadFromOZB(vm, "ErrorListener");
  createThreadFromOZB(vm, "ObjectSupport");
  createThreadFromOZB(vm, "CompilerSupport");
  createThreadFromOZB(vm, "Narrator");
  createThreadFromOZB(vm, "DefaultURL");
  createThreadFromOZB(vm, "Init");
  createThreadFromOZB(vm, "Error");
  createThreadFromOZB(vm, "ErrorFormatters");
  createThreadFromOZB(vm, "Open");
  createThreadFromOZB(vm, "Combinator");
  createThreadFromOZB(vm, "RecordC");
  createThreadFromOZB(vm, "URL");
  createThreadFromOZB(vm, "Application");
  createThreadFromOZB(vm, "OS");
  createThreadFromOZB(vm, "Annotate");
  createThreadFromOZB(vm, "Assembler");
  createThreadFromOZB(vm, "BackquoteMacro");
  createThreadFromOZB(vm, "Builtins");
  createThreadFromOZB(vm, "CodeEmitter");
  createThreadFromOZB(vm, "CodeGen");
  createThreadFromOZB(vm, "CodeStore");
  createThreadFromOZB(vm, "Compiler");
  createThreadFromOZB(vm, "Core");
  createThreadFromOZB(vm, "ForLoop");
  createThreadFromOZB(vm, "GroundZip");
  createThreadFromOZB(vm, "Macro");
  createThreadFromOZB(vm, "PrintName");
  createThreadFromOZB(vm, "RunTime");
  createThreadFromOZB(vm, "StaticAnalysis");
  createThreadFromOZB(vm, "Unnester");
  createThreadFromOZB(vm, "WhileLoop");
  createThreadFromOZB(vm, "NewAssembler");
  createThreadFromOZB(vm, "Parser");
  createThreadFromOZB(vm, "PEG");

  boostBasedVM.run();

  new (vm) Thread(vm, vm->getTopLevelSpace(), runProc);

  boostBasedVM.run();
}
