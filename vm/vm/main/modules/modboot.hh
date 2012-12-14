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

#ifndef __MODBOOT_H
#define __MODBOOT_H

#include "../mozartcore.hh"

#include "modvirtualstring.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

/////////////////
// Boot module //
/////////////////

class ModBoot: public Module {
public:
  ModBoot(): Module("Boot") {}

  class GetInternal: public Builtin<GetInternal> {
  public:
    GetInternal(): Builtin("getInternal") {}

    static void call(VM vm, In name, Out result) {
      UnstableNode nameAtom;
      ModVirtualString::ToAtom::call(vm, name, nameAtom);
      result = vm->findBuiltinModule(std::move(nameAtom));
    }
  };

  class GetNative: public Builtin<GetNative> {
  public:
    GetNative(): Builtin("getNative") {}

    static void call(VM vm, In name, Out result) {
      raiseError(vm, MOZART_STR("notImplemented"),
                 MOZART_STR("Boot.getNative"));
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODBOOT_H
