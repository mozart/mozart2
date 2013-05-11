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

#ifndef __MODDEBUG_H
#define __MODDEBUG_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////
// Debug module //
//////////////////

class ModDebug: public Module {
public:
  ModDebug(): Module("Debug") {}

  class GetRaiseOnBlock: public Builtin<GetRaiseOnBlock> {
  public:
    GetRaiseOnBlock(): Builtin("getRaiseOnBlock") {}

    static void call(VM vm, In thread, Out result) {
      auto runnable = getArgument<Runnable*>(vm, thread, MOZART_STR("Thread"));

      result = build(vm, runnable->getRaiseOnBlock());
    }
  };

  class SetRaiseOnBlock: public Builtin<SetRaiseOnBlock> {
  public:
    SetRaiseOnBlock(): Builtin("setRaiseOnBlock") {}

    static void call(VM vm, In thread, In value) {
      auto runnable = getArgument<Runnable*>(vm, thread, MOZART_STR("Thread"));
      auto boolValue = getArgument<bool>(vm, value, MOZART_STR("Boolean"));

      runnable->setRaiseOnBlock(boolValue);
    }
  };

  class SetId: public Builtin<SetId> {
  public:
    SetId(): Builtin("setId") {}

    static void call(VM vm, In thread, In id) {
      // TODO
    }
  };

  class Breakpoint: public Builtin<Breakpoint> {
  public:
    Breakpoint(): Builtin("breakpoint") {}

    static void call(VM vm) {
      // TODO
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODDEBUG_H
