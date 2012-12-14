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

#ifndef __MODINT_H
#define __MODINT_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

////////////////
// Int module //
////////////////

class ModInt: public Module {
public:
  ModInt(): Module("Int") {}

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, Numeric(value).isInt(vm));
    }
  };

  class Div: public Builtin<Div> {
  public:
    Div(): Builtin("div") {}

    static void call(VM vm, In left, In right, Out result) {
      result = Numeric(left).div(vm, right);
    }
  };

  class Mod: public Builtin<Mod> {
  public:
    Mod(): Builtin("mod") {}

    static void call(VM vm, In left, In right, Out result) {
      result = Numeric(left).mod(vm, right);
    }
  };

  class Plus1: public Builtin<Plus1>, public InlineAs<OpInlinePlus1> {
  public:
    Plus1(): Builtin("+1") {}

    static void call(VM vm, In operand, Out result) {
      result = Numeric(operand).add(vm, 1);
    }
  };

  class Minus1: public Builtin<Minus1>, public InlineAs<OpInlineMinus1> {
  public:
    Minus1(): Builtin("-1") {}

    static void call(VM vm, In operand, Out result) {
      result = Numeric(operand).add(vm, -1);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODINT_H
