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

#ifndef MOZART_MODVMBOOST_H
#define MOZART_MODVMBOOST_H

#include <mozart.hh>

#include "boostenv-decl.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

namespace builtins {

using namespace ::mozart::builtins;

///////////////
// VM module //
///////////////

class ModVM: public Module {
public:
  ModVM(): Module("VM") {}

  class Ncores: public Builtin<Ncores> {
  public:
    Ncores(): Builtin("ncores") {}

    static void call(VM vm, Out result) {
      nativeint ncores = boost::thread::hardware_concurrency();
      if (ncores == 0)
        raiseSystem(vm, buildTuple(vm, "vm", "cannotDetectNumberOfCores"));
      result = build(vm, ncores);
    }
  };

  class Current: public Builtin<Current> {
  public:
    Current(): Builtin("current") {}

    static void call(VM vm, Out result) {
      result = build(vm, BoostVM::forVM(vm).identifier);
    }
  };

  class New: public Builtin<New> {
  public:
    New(): Builtin("new") {}

    static void call(VM vm, In app, Out result) {
      using namespace mozart::patternmatching;

      atom_t appURL;
      bool isURL = matches(vm, app, capture(appURL));

      VMIdentifier parent = BoostVM::forVM(vm).identifier;
      std::unique_ptr<std::string> appStr; // use heap to transfer between VMs

      if (isURL) {
        appStr.reset(new std::string(appURL.contents()));
      } else { // app is a pickled functor
        std::ostringstream out;
        pickle(vm, app, out);
        appStr.reset(new std::string(out.str()));
      }

      // inherit memory settings
      auto& config = vm->getPropertyRegistry().config;
      VirtualMachineOptions options;
      options.minimalHeapSize = config.minimalHeapSize;
      options.maximalHeapSize = config.maximalHeapSize;

      VMIdentifier newVM = BoostEnvironment::forVM(vm).addVM(
        parent, std::move(appStr), isURL, options);
      result = build(vm, newVM);
    }
  };

  class GetPort: public Builtin<GetPort> {
  public:
    GetPort(): Builtin("getPort") {}

    static void call(VM vm, In vmIdentifier, Out result) {
      auto& env = BoostEnvironment::forVM(vm);
      VMIdentifier identifier = env.checkValidIdentifier(vm, vmIdentifier);

      result = VMPort::build(vm, identifier);
    }
  };

  class IdentForPort: public Builtin<IdentForPort> {
  public:
    IdentForPort(): Builtin("identForPort") {}

    static void call(VM vm, In vmPort, Out result) {
      if (vmPort.is<VMPort>()) {
        result = build(vm, vmPort.as<VMPort>().value());
      } else if (vmPort.isTransient()) {
        waitFor(vm, vmPort);
      } else {
        raiseTypeError(vm, "VMPort", vmPort);
      }
    }
  };

  class GetStream: public Builtin<GetStream> {
  public:
    GetStream(): Builtin("getStream") {}

    static void call(VM vm, Out result) {
      result = BoostVM::forVM(vm).getStream();
    }
  };

  class CloseStream: public Builtin<CloseStream> {
  public:
    CloseStream(): Builtin("closeStream") {}

    static void call(VM vm) {
      BoostVM::forVM(vm).closeStream();
    }
  };

  class List: public Builtin<List> {
  public:
    List(): Builtin("list") {}

    static void call(VM vm, Out result) {
      result = BoostEnvironment::forVM(vm).listVMs(vm);
    }
  };

  class Kill: public Builtin<Kill> {
  public:
    Kill(): Builtin("kill") {}

    static void call(VM vm, In vmIdentifier) {
      auto& env = BoostEnvironment::forVM(vm);
      VMIdentifier identifier = env.checkValidIdentifier(vm, vmIdentifier);

      env.killVM(identifier, 0, "kill");
    }
  };

  class Monitor: public Builtin<Monitor> {
  public:
    Monitor(): Builtin("monitor") {}

    static void call(VM vm, In vmIdentifier) {
      auto& env = BoostEnvironment::forVM(vm);
      VMIdentifier identifier = env.checkValidIdentifier(vm, vmIdentifier);
      VMIdentifier monitor = BoostVM::forVM(vm).identifier;

      if (identifier == monitor)
        raiseError(vm, buildTuple(vm, "vm", "cannotMonitorItself"));

      bool found = env.findVM(identifier, [monitor] (BoostVM& monitoredVM) {
        monitoredVM.addMonitor(monitor);
      });
      if (!found) {
        UnstableNode notification =
          BoostVM::forVM(vm).buildTerminationRecord(identifier, "unknown");
        BoostVM::forVM(vm).receiveOnVMStream(notification);
      }
    }
  };
};

}

} }

#endif // MOZART_GENERATOR

#endif // MOZART_MODVMBOOST_H
