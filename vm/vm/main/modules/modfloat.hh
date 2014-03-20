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

#ifndef MOZART_MODFLOAT_H
#define MOZART_MODFLOAT_H

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
      result = FloatLike(left).divide(vm, right);
    }
  };

  class Pow: public Builtin<Pow> {
  public:
    Pow(): Builtin("pow") {}

    static void call(VM vm, In left, In right, Out result) {
      result = FloatLike(left).pow(vm, right);
    }
  };

  class ToInt: public Builtin<ToInt> {
  public:
    ToInt(): Builtin("toInt") {}

    static void call(VM vm, In value, Out result) {
      auto floatValue = getArgument<double>(vm, value);
      nativeint intValue = static_cast<nativeint>(floatValue);
      result = SmallInt::build(vm, intValue);
      UnstableNode big;
      double err;

      if ((intValue == SmallInt::min() || intValue == SmallInt::max()) &&
          Comparable(big = vm->newBigInt(floatValue)).compare(vm, result) != 0) {
        // Overflow
        result = std::move(big);
        err = floatValue - RichNode(result).as<BigInt>().doubleValue();
      } else {
        err = floatValue - static_cast<double>(intValue);
      }

      // bankers' rounding
      if (err > 0.5) {
        result = Numeric(result).add(vm, 1);
      } else if (err < -0.5) {
        result = Numeric(result).add(vm, -1);
      } else if (err == 0.5 || err == -0.5) {
        UnstableNode two = SmallInt::build(vm, 2);
        UnstableNode mod = Numeric(result).mod(vm, two);
        if (RichNode(mod).as<SmallInt>().value() != 0) {
          result = Numeric(result).add(vm, mod);
        }
      }
    }
  };

  class Acos: public Builtin<Acos> {
  public:
    Acos(): Builtin("acos") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).acos(vm));
    }
  };

  class Acosh: public Builtin<Acosh> {
  public:
    Acosh(): Builtin("acosh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).acosh(vm));
    }
  };

  class Asin: public Builtin<Asin> {
  public:
    Asin(): Builtin("asin") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).asin(vm));
    }
  };

  class Asinh: public Builtin<Asinh> {
  public:
    Asinh(): Builtin("asinh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).asinh(vm));
    }
  };

  class Atan: public Builtin<Atan> {
  public:
    Atan(): Builtin("atan") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).atan(vm));
    }
  };

  class Atanh: public Builtin<Atanh> {
  public:
    Atanh(): Builtin("atanh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).atanh(vm));
    }
  };

  class Atan2: public Builtin<Atan2> {
  public:
    Atan2(): Builtin("atan2") {}

    static void call(VM vm, In left, In right, Out result) {
      result = FloatLike(left).atan2(vm, right);
    }
  };

  class Ceil: public Builtin<Ceil> {
  public:
    Ceil(): Builtin("ceil") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).ceil(vm));
    }
  };

  class Cos: public Builtin<Cos> {
  public:
    Cos(): Builtin("cos") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).cos(vm));
    }
  };

  class Cosh: public Builtin<Cosh> {
  public:
    Cosh(): Builtin("cosh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).cosh(vm));
    }
  };

  class Exp: public Builtin<Exp> {
  public:
    Exp(): Builtin("exp") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).exp(vm));
    }
  };

  class Floor: public Builtin<Floor> {
  public:
    Floor(): Builtin("floor") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).floor(vm));
    }
  };

  class Log: public Builtin<Log> {
  public:
    Log(): Builtin("log") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).log(vm));
    }
  };

  class FMod: public Builtin<FMod> {
  public:
    FMod(): Builtin("fMod") {}

    static void call(VM vm, In left, In right, Out result) {
      result = FloatLike(left).fmod(vm, right);
    }
  };

  class Round: public Builtin<Round> {
  public:
    Round(): Builtin("round") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).round(vm));
    }
  };

  class Sin: public Builtin<Sin> {
  public:
    Sin(): Builtin("sin") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).sin(vm));
    }
  };

  class Sinh: public Builtin<Sinh> {
  public:
    Sinh(): Builtin("sinh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).sinh(vm));
    }
  };

  class Sqrt: public Builtin<Sqrt> {
  public:
    Sqrt(): Builtin("sqrt") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).sqrt(vm));
    }
  };

  class Tan: public Builtin<Tan> {
  public:
    Tan(): Builtin("tan") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).tan(vm));
    }
  };

  class Tanh: public Builtin<Tanh> {
  public:
    Tanh(): Builtin("tanh") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, FloatLike(value).tanh(vm));
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // MOZART_MODFLOAT_H
