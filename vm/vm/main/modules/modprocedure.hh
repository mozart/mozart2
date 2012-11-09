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

#ifndef __MODPROCEDURE_H
#define __MODPROCEDURE_H

#include "../mozartcore.hh"
#include "../emulate.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////////
// Procedure module //
//////////////////////

class ModProcedure: public Module {
public:
  ModProcedure(): Module("Procedure") {}

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    void operator()(VM vm, In value, Out result) {
      result = build(vm, Callable(value).isProcedure(vm));
    }
  };

  class Arity: public Builtin<Arity> {
  public:
    Arity(): Builtin("arity") {}

    void operator()(VM vm, In procedure, Out result) {
      result = build(vm, Callable(procedure).procedureArity(vm));
    }
  };

  class Apply: public Builtin<Apply> {
  public:
    Apply(): Builtin("apply") {}

    void operator()(VM vm, In procedure, In args) {
      RichNode terminationVar = protectNonIdempotentStep(
        vm, MOZART_STR("::mozart::builtins::ModProcedure::Apply"),
        [=] () -> RichNode {
          size_t argc = ozListLength(vm, args);
          auto arguments = vm->newStaticArray<RichNode>(argc);
          ozListForEach(
            vm, args,
            [&arguments] (RichNode arg, size_t i) {
              arguments[i] = arg;
            },
            MOZART_STR("list"));

          auto thr = new Thread(vm, vm->getCurrentSpace(),
                                procedure, argc, arguments);

          vm->deleteStaticArray<RichNode>(arguments, argc);

          return RichNode(thr->getTerminationVar());
        }
      );

      if (terminationVar.isTransient())
        waitFor(vm, terminationVar);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODPROCEDURE_H
