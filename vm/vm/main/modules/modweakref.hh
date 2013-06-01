// Copyright © 2013, Université catholique de Louvain
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

#ifndef __MODWEAKREF_H
#define __MODWEAKREF_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////////////
// WeakReference module //
//////////////////////////

class ModWeakReference: public Module {
public:
  ModWeakReference(): Module("WeakReference") {}

  class New: public Builtin<New> {
  public:
    New(): Builtin("new") {}

    static void call(VM vm, In underlying, Out result) {
      result = WeakReference::build(vm, underlying.getStableRef(vm));
    }
  };

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      if (value.isTransient())
        waitFor(vm, value);
      result = build(vm, value.is<WeakReference>());
    }
  };

  class Get: public Builtin<Get> {
  public:
    Get(): Builtin("get") {}

    static void call(VM vm, In weakRef, Out result) {
      if (weakRef.is<WeakReference>()) {
        StableNode* underlying = weakRef.as<WeakReference>().getUnderlying();
        if (underlying == nullptr)
          result = build(vm, "none");
        else
          result = buildTuple(vm, "some", *underlying);
      } else if (weakRef.isTransient()) {
        waitFor(vm, weakRef);
      } else {
        raiseTypeError(vm, "WeakReference", weakRef);
      }
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODWEAKREF_H
