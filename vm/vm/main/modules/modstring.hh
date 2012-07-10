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

#ifndef __MODSTRING_H
#define __MODSTRING_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////
// String module //
///////////////////

class ModString : public Module {
public:
  ModString() : Module("String") {}

  class Is : public Builtin<Is> {
  public:
    Is() : Builtin("is") {}

    OpResult operator()(VM vm, In value, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(StringLike(value).isString(vm, boolResult));
      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class ToAtom : public Builtin<ToAtom> {
  public:
    ToAtom() : Builtin("toAtom") {}

    OpResult operator()(VM vm, In value, Out result) {
      LString<nchar>* content = nullptr;
      MOZART_CHECK_OPRESULT(StringLike(value).stringGet(vm, content));
      result = Atom::build(vm, content->length, content->string);
      return OpResult::proceed();
    }
  };

  class CharAt : public Builtin<CharAt> {
  public:
    CharAt() : Builtin("charAt") {}

    OpResult operator()(VM vm, In value, In index, Out result) {
      nativeint charResult = 0;
      MOZART_CHECK_OPRESULT(
        StringLike(value).stringCharAt(vm, index, charResult));
      result = SmallInt::build(vm, charResult);
      return OpResult::proceed();
    }
  };

  class Append : public Builtin<Append> {
  public:
    Append() : Builtin("append") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      return StringLike(left).stringAppend(vm, right, result);
    }
  };

  class Slice : public Builtin<Slice> {
  public:
    Slice() : Builtin("slice") {}

    OpResult operator()(VM vm, In value, In from, In to, Out result) {
      return StringLike(value).stringSlice(vm, from, to, result);
    }
  };

  class Search : public Builtin<Search> {
  public:
    Search() : Builtin("search") {}

    OpResult operator()(VM vm, In value, In from, In needle, Out begin, Out end) {
      return StringLike(value).stringSearch(vm, from, needle, begin, end);
    }
  };

  class HasPrefix : public Builtin<HasPrefix> {
  public:
    HasPrefix() : Builtin("hasPrefix") {}

    OpResult operator()(VM vm, In string, In prefix, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(
        StringLike(string).stringHasPrefix(vm, prefix, boolResult));
      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class HasSuffix : public Builtin<HasSuffix> {
  public:
    HasSuffix() : Builtin("hasSuffix") {}

    OpResult operator()(VM vm, In string, In suffix, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(
        StringLike(string).stringHasSuffix(vm, suffix, boolResult));
      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };
};

}

}

#endif

#endif // __MODSTRING_H
