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

#ifndef __MODVALUE_H
#define __MODVALUE_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////
// Value module //
//////////////////

class Value: public Module {
public:
  Value(): Module("Value") {}

  class Dot: public Builtin<Dot> {
  public:
    Dot(): Builtin(".") {}

    OpResult operator()(VM vm, In record, In feature, Out result) {
      return RecordLike(record).dot(vm, feature, result);
    }
  };

  class EqEq: public Builtin<EqEq> {
  public:
    EqEq(): Builtin("==") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      bool res = false;
      MOZART_CHECK_OPRESULT(equals(vm, left, right, res));

      result.make<Boolean>(vm, res);
      return OpResult::proceed();
    }
  };

  class NotEqEq: public Builtin<NotEqEq> {
  public:
    NotEqEq(): Builtin("\\=") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      bool res = false;
      MOZART_CHECK_OPRESULT(notEquals(vm, left, right, res));

      result.make<Boolean>(vm, res);
      return OpResult::proceed();
    }
  };

  class Wait: public Builtin<Wait> {
  public:
    Wait(): Builtin("wait") {}

    OpResult operator()(VM vm, In value) {
      if (value.isTransient())
        return OpResult::waitFor(vm, value);
      else
        return OpResult::proceed();
    }
  };

  class WaitQuiet: public Builtin<WaitQuiet> {
  public:
    WaitQuiet(): Builtin("waitQuiet") {}

    OpResult operator()(VM vm, In value) {
      if (value.isTransient())
        return OpResult::waitQuietFor(vm, value);
      else
        return OpResult::proceed();
    }
  };

  class WaitNeeded: public Builtin<WaitNeeded> {
  public:
    WaitNeeded(): Builtin("waitNeeded") {}

    OpResult operator()(VM vm, In value) {
      if (!DataflowVariable(value).isNeeded(vm))
        return OpResult::waitQuietFor(vm, value);
      else
        return OpResult::proceed();
    }
  };

  class MakeNeeded: public Builtin<MakeNeeded> {
  public:
    MakeNeeded(): Builtin("makeNeeded") {}

    OpResult operator()(VM vm, In value) {
      DataflowVariable(value).markNeeded(vm);
      return OpResult::proceed();
    }
  };

  class IsDet: public Builtin<IsDet> {
  public:
    IsDet(): Builtin("isDet") {}

    OpResult operator()(VM vm, In value, Out result) {
      result.make<Boolean>(vm, !value.isTransient());
      return OpResult::proceed();
    }
  };

  class LowerEqual: public Builtin<LowerEqual> {
  public:
    LowerEqual(): Builtin("=<") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      int res = 0;
      MOZART_CHECK_OPRESULT(Comparable(left).compare(vm, right, res));

      result.make<Boolean>(vm, res <= 0);
      return OpResult::proceed();
    }
  };

  class LowerThan: public Builtin<LowerThan> {
  public:
    LowerThan(): Builtin("<") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      int res = 0;
      MOZART_CHECK_OPRESULT(Comparable(left).compare(vm, right, res));

      result.make<Boolean>(vm, res < 0);
      return OpResult::proceed();
    }
  };

  class GreaterEqual: public Builtin<GreaterEqual> {
  public:
    GreaterEqual(): Builtin(">=") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      int res = 0;
      MOZART_CHECK_OPRESULT(Comparable(left).compare(vm, right, res));

      result.make<Boolean>(vm, res >= 0);
      return OpResult::proceed();
    }
  };

  class GreaterThan: public Builtin<GreaterThan> {
  public:
    GreaterThan(): Builtin(">") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      int res = 0;
      MOZART_CHECK_OPRESULT(Comparable(left).compare(vm, right, res));

      result.make<Boolean>(vm, res > 0);
      return OpResult::proceed();
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODVALUE_H
