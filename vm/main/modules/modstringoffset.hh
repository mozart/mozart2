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

#ifndef __MODSTRINGOFFSET_H
#define __MODSTRINGOFFSET_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

/////////////////////////
// StringOffset module //
/////////////////////////

class ModStringOffset: public Module {
public:
  ModStringOffset(): Module("StringOffset") {}

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    OpResult operator()(VM vm, In value, Out result) {
      bool isStringOffset;
      MOZART_CHECK_OPRESULT(StringOffsetLike(value).isStringOffset(vm, isStringOffset));
      result.make<Boolean>(vm, isStringOffset);
      return OpResult::proceed();
    }
  };

  class ToInt: public Builtin<ToInt> {
  public:
    ToInt(): Builtin("toInt") {}

    OpResult operator()(VM vm, In value, Out result) {
      nativeint index;
      MOZART_CHECK_OPRESULT(StringOffsetLike(value).getCharIndex(vm, index));
      result.make<SmallInt>(vm, index);
      return OpResult::proceed();
    }
  };

  class Advance: public Builtin<Advance> {
  public:
    Advance(): Builtin("advance") {}

    OpResult operator()(VM vm, In offset, In string, In deltaNode, Out result) {
      nativeint delta;
      MOZART_GET_ARG(delta, deltaNode, MOZART_STR("integer"));
      return StringOffsetLike(offset).stringOffsetAdvance(vm, string, delta, result);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODSTRINGOFFSET_H

