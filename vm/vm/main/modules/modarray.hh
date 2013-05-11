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

#ifndef __MODARRAY_H
#define __MODARRAY_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////
// Array module //
//////////////////

class ModArray: public Module {
public:
  ModArray(): Module("Array") {}

  class New: public Builtin<New> {
  public:
    New(): Builtin("new") {}

    static void call(VM vm, In low, In high, In initValue, Out result) {
      auto intLow = getArgument<nativeint>(vm, low, MOZART_STR("integer"));
      auto intHigh = getArgument<nativeint>(vm, high, MOZART_STR("integer"));

      nativeint width = intHigh - intLow + 1;
      if (width < 0)
        raise(vm, MOZART_STR("negativeArraySize"));

      result = Array::build(vm, (size_t) width, intLow, initValue);
    }
  };

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, ArrayLike(value).isArray(vm));
    }
  };

  class Low: public Builtin<Low> {
  public:
    Low(): Builtin("low") {}

    static void call(VM vm, In array, Out result) {
      result = build(vm, ArrayLike(array).arrayLow(vm));
    }
  };

  class High: public Builtin<High> {
  public:
    High(): Builtin("high") {}

    static void call(VM vm, In array, Out result) {
      result = build(vm, ArrayLike(array).arrayHigh(vm));
    }
  };

  class Get: public Builtin<Get> {
  public:
    Get(): Builtin("get") {}

    static void call(VM vm, In array, In index, Out result) {
      result = ArrayLike(array).arrayGet(vm, index);
    }
  };

  class Put: public Builtin<Put> {
  public:
    Put(): Builtin("put") {}

    static void call(VM vm, In array, In index, In newValue) {
      ArrayLike(array).arrayPut(vm, index, newValue);
    }
  };

  class ExchangeFun: public Builtin<ExchangeFun> {
  public:
    ExchangeFun(): Builtin("exchangeFun") {}

    static void call(VM vm, In array, In index, In newValue, Out oldValue) {
      oldValue = ArrayLike(array).arrayExchange(vm, index, newValue);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODARRAY_H
