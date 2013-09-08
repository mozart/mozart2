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

#ifndef __MODREFLECTION_H
#define __MODREFLECTION_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////////
// Reflection module //
///////////////////////

class ModReflection: public Module {
public:
  ModReflection(): Module("Reflection") {}

  class NewReflectiveEntity: public Builtin<NewReflectiveEntity> {
  public:
    NewReflectiveEntity(): Builtin("newReflectiveEntity") {}

    static void call(VM vm, Out stream, Out result) {
      result = ReflectiveEntity::build(vm, stream);
    }
  };

  class NewReflectiveVariable: public Builtin<NewReflectiveVariable> {
  public:
    NewReflectiveVariable(): Builtin("newReflectiveVariable") {}

    static void call(VM vm, Out stream, Out result) {
      result = ReflectiveVariable::build(vm, stream);
    }
  };

  class IsReflectiveVariable : public Builtin<IsReflectiveVariable> {
  public:
    IsReflectiveVariable(): Builtin("isReflectiveVariable") {}

    static void call(VM vm, In variable, Out result) {
      result = build(vm, variable.is<ReflectiveVariable>());
    }
  };

  class BindReflectiveVariable: public Builtin<BindReflectiveVariable> {
  public:
    BindReflectiveVariable(): Builtin("bindReflectiveVariable") {}

    static void call(VM vm, In variable, In value) {
      if (variable.is<ReflectiveVariable>())
        variable.as<ReflectiveVariable>().reflectiveBind(vm, value);
      else
        raiseTypeError(vm, "ReflectiveVariable", variable);
    }
  };

  class GetStructuralBehavior: public Builtin<GetStructuralBehavior> {
  public:
    GetStructuralBehavior(): Builtin("getStructuralBehavior") {}

    static void call(VM vm, In entity, Out result) {
      auto behavior = entity.type().getStructuralBehavior();

      switch (behavior) {
        case sbValue: result = build(vm, "value"); break;
        case sbStructural: result = build(vm, "structural"); break;
        case sbTokenEq: result = build(vm, "token"); break;
        case sbVariable: result = build(vm, "variable"); break;
        default: assert(false);
      }
    }
  };

  class Become: public Builtin<Become> {
  public:
    Become(): Builtin("become") {}

    static void call(VM vm, In entity, In value) {
      auto behavior = entity.type().getStructuralBehavior();

      if ((behavior == sbTokenEq) || (behavior == sbVariable)) {
        entity.become(vm, value);
      } else {
        raiseTypeError(vm, "Token or Variable entity", entity);
      }
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODREFLECTION_H
