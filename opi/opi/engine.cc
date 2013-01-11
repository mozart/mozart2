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

atom_t pathToAtom(VM vm, const fs::path& path) {
  auto nativeStr = path.native();
  auto mozartStr = toUTF<nchar>(
    makeLString(nativeStr.c_str(), nativeStr.size()));
  return vm->getAtom(mozartStr.length, mozartStr.string);
}

int main(int argc, char** argv) {
  boostenv::BoostBasedVM boostBasedVM;
  VM vm = boostBasedVM.vm;

  fs::path appPath = fs::path(argv[0]).parent_path();

  // Hacky way to guess if we are in an installed setting
  bool isInstalled = appPath.empty() || (appPath.filename() == "bin");

  fs::path ozHome;
  {
    char* ozHomeVar = std::getenv("OZHOME");
    if (ozHomeVar == nullptr)
      ozHomeVar = std::getenv("OZ_HOME");

    if (ozHomeVar != nullptr)
      ozHome = fs::path(ozHomeVar);
    else if (isInstalled)
      ozHome = appPath.parent_path();
    else
      ozHome = appPath;

    auto propValue = build(vm, pathToAtom(vm, ozHome));

    auto propName = build(vm, MOZART_STR("oz.emulator.home"));
    vm->getPropertyRegistry().put(vm, propName, propValue);

    propName = build(vm, MOZART_STR("oz.configure.home"));
    vm->getPropertyRegistry().put(vm, propName, propValue);
  }

  fs::path bootSearchPath;
  {
    char* bootSearchPathVar = std::getenv("OZ_BOOT_PATH");
    if (bootSearchPathVar != nullptr)
      bootSearchPath = fs::path(bootSearchPathVar);
    else if (isInstalled)
      bootSearchPath = ozHome / "share" / "mozart" / "boot";
    else
      bootSearchPath = ozHome / "boot";

    vm->getPropertyRegistry().registerConstantProp(
      vm, MOZART_STR("oz.search.boot"), pathToAtom(vm, bootSearchPath));
  }

  {
    if (argc < 2) {
      std::cerr << "usage: ozengine AppURL" << std::endl;
      return 1;
    }

    boostBasedVM.setApplicationURL(argv[1]);
    boostBasedVM.setApplicationArgs(argc-2, argv+2);
  }

  {
    // Load the Base environment and the Init functor

    UnstableNode baseEnv = OptVar::build(vm);
    UnstableNode initFunctor = OptVar::build(vm);

    vm->getPropertyRegistry().registerConstantProp(
      vm, MOZART_STR("internal.boot.base"), baseEnv);
    vm->getPropertyRegistry().registerConstantProp(
      vm, MOZART_STR("internal.boot.init"), initFunctor);

    UnstableNode baseValue, initValue;
    auto& bootLoader = boostBasedVM.getBootLoader();
    fs::path systemSearchPath = bootSearchPath / "x-oz" / "system";

    if (!bootLoader(vm, (systemSearchPath / "Base.ozf").native(), baseValue)) {
      std::cerr << "panic: could not load Base functor" << std::endl;
      return 1;
    }

    if (!bootLoader(vm, (systemSearchPath / "Init.ozf").native(), initValue)) {
      std::cerr << "panic: could not load Init functor" << std::endl;
      return 1;
    }

    // Create the thread that loads the Base environment
    if (Callable(baseValue).isProcedure(vm)) {
      ozcalls::asyncOzCall(vm, baseValue, baseEnv);
    } else {
      // Assume it is a functor that does not import anything
      UnstableNode applyAtom = build(vm, MOZART_STR("apply"));
      UnstableNode applyProc = Dottable(baseValue).dot(vm, applyAtom);
      UnstableNode importParam = build(vm, MOZART_STR("import"));
      ozcalls::asyncOzCall(vm, applyProc, importParam, baseEnv);
    }

    // Create the thread that loads the Init functor
    if (Callable(initValue).isProcedure(vm)) {
      ozcalls::asyncOzCall(vm, initValue, initFunctor);
    } else {
      // Assume it is already the Init functor
      DataflowVariable(initFunctor).bind(vm, initValue);
    }

    boostBasedVM.run();
  }

  {
    // Base.'Base' = Base
    UnstableNode Base;
    auto BaseProperty = build(vm, MOZART_STR("internal.boot.base"));
    vm->getPropertyRegistry().get(vm, BaseProperty, Base);

    auto BaseAtom = build(vm, MOZART_STR("Base"));
    auto BaseField = Dottable(Base).dot(vm, BaseAtom);

    if (RichNode(BaseField).isTransient())
      DataflowVariable(BaseField).bind(vm, Base);
  }

  {
    // Apply the Init functor

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
