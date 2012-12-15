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
#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>

using namespace mozart;
namespace fs = boost::filesystem;

void createThreadFromOZB(VM vm, const fs::path& ozbPath,
                         const std::string& functorName) {
  fs::path fileName = ozbPath / fs::path(functorName + ".ozb");
  fs::ifstream input(fileName);

  if (!input.is_open()) {
    std::cerr << "panic: cannot open " << fileName << "\n";
    std::abort();
  }

  UnstableNode codeArea = bootUnpickle(vm, input);
  UnstableNode abstraction = Abstraction::build(vm, 0, codeArea);
  new (vm) Thread(vm, vm->getTopLevelSpace(), abstraction);
}

int main(int argc, char** argv) {
  boostenv::BoostBasedVM boostBasedVM;
  VM vm = boostBasedVM.vm;

  fs::path ozbPath;
  {
    char* ozbPathVar = std::getenv("OZ_BOOT_PATH");
    if (ozbPathVar != nullptr)
      ozbPath = fs::path(ozbPathVar);
    else
      ozbPath = fs::path(argv[0]).parent_path();
  }

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

  createThreadFromOZB(vm, ozbPath, "Base");

  boostBasedVM.run();

  createThreadFromOZB(vm, ozbPath, "OPI");
  createThreadFromOZB(vm, ozbPath, "Emacs");
  createThreadFromOZB(vm, ozbPath, "OPIServer");
  createThreadFromOZB(vm, ozbPath, "OPIEnv");
  createThreadFromOZB(vm, ozbPath, "Space");
  createThreadFromOZB(vm, ozbPath, "System");
  createThreadFromOZB(vm, ozbPath, "Property");
  createThreadFromOZB(vm, ozbPath, "Listener");
  createThreadFromOZB(vm, ozbPath, "Type");
  createThreadFromOZB(vm, ozbPath, "ErrorListener");
  createThreadFromOZB(vm, ozbPath, "ObjectSupport");
  createThreadFromOZB(vm, ozbPath, "CompilerSupport");
  createThreadFromOZB(vm, ozbPath, "Narrator");
  createThreadFromOZB(vm, ozbPath, "DefaultURL");
  createThreadFromOZB(vm, ozbPath, "Init");
  createThreadFromOZB(vm, ozbPath, "Error");
  createThreadFromOZB(vm, ozbPath, "ErrorFormatters");
  createThreadFromOZB(vm, ozbPath, "Open");
  createThreadFromOZB(vm, ozbPath, "Combinator");
  createThreadFromOZB(vm, ozbPath, "RecordC");
  createThreadFromOZB(vm, ozbPath, "URL");
  createThreadFromOZB(vm, ozbPath, "Application");
  createThreadFromOZB(vm, ozbPath, "OS");
  createThreadFromOZB(vm, ozbPath, "Annotate");
  createThreadFromOZB(vm, ozbPath, "Assembler");
  createThreadFromOZB(vm, ozbPath, "BackquoteMacro");
  createThreadFromOZB(vm, ozbPath, "Builtins");
  createThreadFromOZB(vm, ozbPath, "CodeEmitter");
  createThreadFromOZB(vm, ozbPath, "CodeGen");
  createThreadFromOZB(vm, ozbPath, "CodeStore");
  createThreadFromOZB(vm, ozbPath, "Compiler");
  createThreadFromOZB(vm, ozbPath, "Core");
  createThreadFromOZB(vm, ozbPath, "ForLoop");
  createThreadFromOZB(vm, ozbPath, "GroundZip");
  createThreadFromOZB(vm, ozbPath, "Macro");
  createThreadFromOZB(vm, ozbPath, "PrintName");
  createThreadFromOZB(vm, ozbPath, "RunTime");
  createThreadFromOZB(vm, ozbPath, "StaticAnalysis");
  createThreadFromOZB(vm, ozbPath, "Unnester");
  createThreadFromOZB(vm, ozbPath, "WhileLoop");
  createThreadFromOZB(vm, ozbPath, "NewAssembler");
  createThreadFromOZB(vm, ozbPath, "Parser");
  createThreadFromOZB(vm, ozbPath, "PEG");

  boostBasedVM.run();

  new (vm) Thread(vm, vm->getTopLevelSpace(), runProc);

  boostBasedVM.run();
}
