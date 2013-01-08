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

#ifndef __MODPROPERTY_H
#define __MODPROPERTY_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

/////////////////////
// Property module //
/////////////////////

class ModProperty: public Module {
public:
  ModProperty(): Module("Property") {}

  class RegisterValue: public Builtin<RegisterValue> {
  public:
    RegisterValue(): Builtin("registerValue") {}

    static void call(VM vm, In property, In value) {
      auto propertyAtom = getArgument<atom_t>(vm, property);
      vm->getPropertyRegistry().registerValueProp(
        vm, propertyAtom.contents(), value);
    }
  };

  class RegisterConstant: public Builtin<RegisterConstant> {
  public:
    RegisterConstant(): Builtin("registerConstant") {}

    static void call(VM vm, In property, In value) {
      auto propertyAtom = getArgument<atom_t>(vm, property);
      vm->getPropertyRegistry().registerConstantProp(
        vm, propertyAtom.contents(), value);
    }
  };

  class Get: public Builtin<Get> {
  public:
    Get(): Builtin("get") {}

    static void call(VM vm, In property, Out result, Out found) {
      if (vm->getPropertyRegistry().get(vm, property, result)) {
        found = build(vm, true);
      } else {
        result = build(vm, unit);
        found = build(vm, false);
      }
    }
  };

  class Put: public Builtin<Put> {
  public:
    Put(): Builtin("put") {}

    static void call(VM vm, In property, In value, Out found) {
      found = build(vm, vm->getPropertyRegistry().put(vm, property, value));
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODPROPERTY_H
