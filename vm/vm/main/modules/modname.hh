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

#ifndef __MODNAME_H
#define __MODNAME_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

/////////////////
// Name module //
/////////////////

class ModName: public Module {
public:
  ModName(): Module("Name") {}

  class New: public Builtin<New> {
  public:
    New(): Builtin("new") {}

    static void call(VM vm, Out result) {
      result = OptName::build(vm);
    }
  };

  class NewWithUUID: public Builtin<NewWithUUID> {
  public:
    NewWithUUID(): Builtin("newWithUUID") {}

    static void call(VM vm, In uuid, Out result) {
      auto uuidValue = getArgument<UUID>(vm, uuid);
      result = GlobalName::build(vm, uuidValue);
    }
  };

  class NewUnique: public Builtin<NewUnique> {
  public:
    NewUnique(): Builtin("newUnique") {}

    static void call(VM vm, In atom, Out result) {
      auto atomValue = getArgument<atom_t>(vm, atom, MOZART_STR("Atom"));
      result = UniqueName::build(vm, unique_name_t(atomValue));
    }
  };

  class NewNamed: public Builtin<NewNamed> {
  public:
    NewNamed(): Builtin("newNamed") {}

    static void call(VM vm, In printName, Out result) {
      auto printNameValue = getArgument<atom_t>(vm, printName);
      result = NamedName::build(vm, printNameValue);
    }
  };

  class NewNamedWithUUID: public Builtin<NewNamedWithUUID> {
  public:
    NewNamedWithUUID(): Builtin("newNamedWithUUID") {}

    static void call(VM vm, In printName, In uuid, Out result) {
      auto printNameValue = getArgument<atom_t>(vm, printName);
      auto uuidValue = getArgument<UUID>(vm, uuid);
      result = NamedName::build(vm, printNameValue, uuidValue);
    }
  };

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, NameLike(value).isName(vm));
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODNAME_H
