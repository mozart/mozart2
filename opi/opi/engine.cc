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

bool doBootLoad(VM vm, const fs::path& ozbPath,
                const std::string& functorName, UnstableNode& result) {
  fs::path fileName = ozbPath / fs::path(functorName + ".ozb");
  fs::ifstream input(fileName);

  if (!input.is_open())
    return false;

  result = bootUnpickle(vm, input);
  return true;
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

  boostBasedVM.setBootLoader(
    [ozbPath] (VM vm, const std::string& url, UnstableNode& result) -> bool {
      std::string prefix = "x-oz://system/";
      std::string suffix = ".ozf";
      size_t prefixSize = prefix.size();
      size_t suffixSize = suffix.size();
      size_t urlSize = url.size();

      if ((urlSize <= prefixSize + suffixSize) ||
          (url.substr(0, prefixSize) != prefix) ||
          (url.substr(urlSize-suffixSize, suffixSize) != suffix)) {
        return false;
      }

      auto name = url.substr(prefixSize, urlSize-prefixSize-suffixSize);

      return doBootLoad(vm, ozbPath, name, result);
    }
  );

  if (argc >= 2) {
    boostBasedVM.setApplicationURL(argv[1]);
    boostBasedVM.setApplicationArgs(argc-2, argv+2);
  } else {
    boostBasedVM.setApplicationURL(u8"x-oz://system/OPI.ozf");
    boostBasedVM.setApplicationArgs(0, nullptr);
  }

  {
    UnstableNode baseEnv = OptVar::build(vm);
    UnstableNode initFunctor = OptVar::build(vm);

    vm->getPropertyRegistry().registerConstantProp(
      vm, MOZART_STR("internal.boot.base"), baseEnv);
    vm->getPropertyRegistry().registerConstantProp(
      vm, MOZART_STR("internal.boot.init"), initFunctor);

    UnstableNode baseAbstraction, initAbstraction;
    if (!doBootLoad(vm, ozbPath, "Base", baseAbstraction))
      std::cerr << "panic: could not load Base module" << std::endl;
    if (!doBootLoad(vm, ozbPath, "Init", initAbstraction))
      std::cerr << "panic: could not load Init functor" << std::endl;

    ozcalls::asyncOzCall(vm, baseAbstraction, baseEnv);
    ozcalls::asyncOzCall(vm, initAbstraction, initFunctor);

    boostBasedVM.run();
  }

  {
    UnstableNode InitFunctor;
    auto InitFunctorProperty = build(vm, MOZART_STR("internal.boot.init"));
    vm->getPropertyRegistry().get(vm, InitFunctorProperty, InitFunctor);

    auto ApplyAtom = build(vm, MOZART_STR("apply"));
    auto ApplyProc = Dottable(InitFunctor).dot(vm, ApplyAtom);

    auto BootModule = vm->findBuiltinModule(MOZART_STR("Boot"));
    auto ImportRecord = buildRecord(
      vm, buildArity(vm, MOZART_STR("import"), MOZART_STR("Boot")),
      BootModule);

    ozcalls::asyncOzCall(vm, ApplyProc, ImportRecord, OptVar::build(vm));

    boostBasedVM.run();
  }
}
