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

#ifndef __MODFLOAT_H
#define __MODFLOAT_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////
// Float module //
//////////////////

class ModFloat: public Module {
public:
  ModFloat(): Module("Float") {}

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).isFloat(vm));
    }
  };

  class Divide: public Builtin<Divide> {
  public:
    Divide(): Builtin("/") {}

    static void call(VM vm, In left, In right, Out result) {
      result = Numeric(left).divide(vm, right);
    }
  };

  class ToInt: public Builtin<ToInt> {
  public:
    ToInt(): Builtin("toInt") {}

    static void call(VM vm, In value, Out result) {
      auto floatValue = getArgument<double>(vm, value);
      result = build(vm, (nativeint) floatValue);
    }
  };

  class Acos: public Builtin<Acos> {
  public:
    Acos(): Builtin("acos") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).acos(vm));
    }
  };

  class Acosh: public Builtin<Acosh> {
  public:
    Acosh(): Builtin("acosh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).acosh(vm));
    }
  };

  class Asin: public Builtin<Asin> {
  public:
    Asin(): Builtin("asin") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).asin(vm));
    }
  };

  class Asinh: public Builtin<Asinh> {
  public:
    Asinh(): Builtin("asinh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).asinh(vm));
    }
  };

  class Atan: public Builtin<Atan> {
  public:
    Atan(): Builtin("atan") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).atan(vm));
    }
  };

  class Atanh: public Builtin<Atanh> {
  public:
    Atanh(): Builtin("atanh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).atanh(vm));
    }
  };

  class Atan2: public Builtin<Atan2> {
  public:
    Atan2(): Builtin("atan2") {}

    static void call(VM vm, In left, In right, Out result) {
      result = Numeric(left).atan2(vm, right);
    }
  };

  class Ceil: public Builtin<Ceil> {
  public:
    Ceil(): Builtin("ceil") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).ceil(vm));
    }
  };

  class Cos: public Builtin<Cos> {
  public:
    Cos(): Builtin("cos") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).cos(vm));
    }
  };

  class Cosh: public Builtin<Cosh> {
  public:
    Cosh(): Builtin("cosh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).cosh(vm));
    }
  };

  class Exp: public Builtin<Exp> {
  public:
    Exp(): Builtin("exp") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).exp(vm));
    }
  };

  class Floor: public Builtin<Floor> {
  public:
    Floor(): Builtin("floor") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).floor(vm));
    }
  };

  class Log: public Builtin<Log> {
  public:
    Log(): Builtin("log") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).log(vm));
    }
  };

  class Mod: public Builtin<Mod> {
  public:
    Mod(): Builtin("mod") {}

    static void call(VM vm, In left, In right, Out result) {
      result = Numeric(left).mod(vm, right);
    }
  };

  class Round: public Builtin<Round> {
  public:
    Round(): Builtin("round") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).round(vm));
    }
  };

  class Sin: public Builtin<Sin> {
  public:
    Sin(): Builtin("sin") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).sin(vm));
    }
  };

  class Sinh: public Builtin<Sinh> {
  public:
    Sinh(): Builtin("sinh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).sinh(vm));
    }
  };

  class Sqrt: public Builtin<Sqrt> {
  public:
    Sqrt(): Builtin("sqrt") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).sqrt(vm));
    }
  };

  class Tan: public Builtin<Tan> {
  public:
    Tan(): Builtin("tan") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).tan(vm));
    }
  };

  class Tanh: public Builtin<Tanh> {
  public:
    Tanh(): Builtin("tanh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).tanh(vm));
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODFLOAT_H
