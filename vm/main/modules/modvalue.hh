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

class ModValue: public Module {
public:
  ModValue(): Module("Value") {}

  class Dot: public Builtin<Dot> {
  public:
    Dot(): Builtin(".") {}

    OpResult operator()(VM vm, In value, In feature, Out result) {
      return Dottable(value).dot(vm, feature, result);
    }
  };

  class DotAssign: public Builtin<DotAssign> {
  public:
    DotAssign(): Builtin("dotAssign") {}

    OpResult operator()(VM vm, In value, In feature, In newValue) {
      return DotAssignable(value).dotAssign(vm, feature, newValue);
    }
  };

  class DotExchange: public Builtin<DotExchange> {
  public:
    DotExchange(): Builtin("dotExchange") {}

    OpResult operator()(VM vm, In value, In feature, In newValue,
                        Out oldValue) {
      return DotAssignable(value).dotExchange(vm, feature, newValue, oldValue);
    }
  };

  class CatAccess: public Builtin<CatAccess> {
  public:
    CatAccess(): Builtin("catAccess") {}

    OpResult operator()(VM vm, In reference, Out result) {
      return catHelper(vm, reference,
        [&result] (VM vm, Dottable dotAssignable,
                   RichNode feature) -> OpResult {
          return dotAssignable.dot(vm, feature, result);
        },
        [&result] (VM vm, CellLike cellLike) -> OpResult {
          return cellLike.access(vm, result);
        }
      );
    }
  };

  class CatAssign: public Builtin<CatAssign> {
  public:
    CatAssign(): Builtin("catAssign") {}

    OpResult operator()(VM vm, In reference, In newValue) {
      return catHelper(vm, reference,
        [newValue] (VM vm, DotAssignable dotAssignable,
                    RichNode feature) -> OpResult {
          return dotAssignable.dotAssign(vm, feature, newValue);
        },
        [newValue] (VM vm, CellLike cellLike) -> OpResult {
          return cellLike.assign(vm, newValue);
        }
      );
    }
  };

  class CatExchange: public Builtin<CatExchange> {
  public:
    CatExchange(): Builtin("catExchange") {}

    OpResult operator()(VM vm, In reference, In newValue, Out oldValue) {
      return catHelper(vm, reference,
        [newValue, &oldValue] (VM vm, DotAssignable dotAssignable,
                               RichNode feature) -> OpResult {
          return dotAssignable.dotExchange(vm, feature, newValue, oldValue);
        },
        [newValue, &oldValue] (VM vm, CellLike cellLike) -> OpResult {
          return cellLike.exchange(vm, newValue, oldValue);
        }
      );
    }
  };

  class CatAccessOO: public Builtin<CatAccessOO> {
  public:
    CatAccessOO(): Builtin("catAccessOO") {}

    OpResult operator()(VM vm, In self, In reference, Out result) {
      return catOOHelper(vm, self, reference,
        [&result] (VM vm, Dottable dotAssignable,
                   RichNode feature) -> OpResult {
          return dotAssignable.dot(vm, feature, result);
        },
        [&result] (VM vm, CellLike cellLike) -> OpResult {
          return cellLike.access(vm, result);
        },
        [&result] (VM vm, ObjectLike self, RichNode attr) -> OpResult {
          return self.attrGet(vm, attr, result);
        }
      );
    }
  };

  class CatAssignOO: public Builtin<CatAssignOO> {
  public:
    CatAssignOO(): Builtin("catAssignOO") {}

    OpResult operator()(VM vm, In self, In reference, In newValue) {
      return catOOHelper(vm, self, reference,
        [newValue] (VM vm, DotAssignable dotAssignable,
                    RichNode feature) -> OpResult {
          return dotAssignable.dotAssign(vm, feature, newValue);
        },
        [newValue] (VM vm, CellLike cellLike) -> OpResult {
          return cellLike.assign(vm, newValue);
        },
        [newValue] (VM vm, ObjectLike self, RichNode attr) -> OpResult {
          return self.attrPut(vm, attr, newValue);
        }
      );
    }
  };

  class CatExchangeOO: public Builtin<CatExchangeOO> {
  public:
    CatExchangeOO(): Builtin("catExchangeOO") {}

    OpResult operator()(VM vm, In self, In reference,
                        In newValue, Out oldValue) {
      return catOOHelper(vm, self, reference,
        [newValue, &oldValue] (VM vm, DotAssignable dotAssignable,
                               RichNode feature) -> OpResult {
          return dotAssignable.dotExchange(vm, feature, newValue, oldValue);
        },
        [newValue, &oldValue] (VM vm, CellLike cellLike) -> OpResult {
          return cellLike.exchange(vm, newValue, oldValue);
        },
        [newValue, &oldValue] (VM vm, ObjectLike self,
                               RichNode attr) -> OpResult {
          return self.attrExchange(vm, attr, newValue, oldValue);
        }
      );
    }
  };

  class EqEq: public Builtin<EqEq> {
  public:
    EqEq(): Builtin("==") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      bool res = false;
      MOZART_CHECK_OPRESULT(equals(vm, left, right, res));

      result = Boolean::build(vm, res);
      return OpResult::proceed();
    }
  };

  class NotEqEq: public Builtin<NotEqEq> {
  public:
    NotEqEq(): Builtin("\\=") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      bool res = false;
      MOZART_CHECK_OPRESULT(notEquals(vm, left, right, res));

      result = Boolean::build(vm, res);
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
      if (value.isTransient() && !value.is<FailedValue>())
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

  class IsFree: public Builtin<IsFree> {
  public:
    IsFree(): Builtin("isFree") {}

    OpResult operator()(VM vm, In value, Out result) {
      bool res = value.isTransient() &&
        !value.is<ReadOnly>() && !value.is<FailedValue>();

      result = Boolean::build(vm, res);
      return OpResult::proceed();
    }
  };

  class IsKinded: public Builtin<IsKinded> {
  public:
    IsKinded(): Builtin("isKinded") {}

    OpResult operator()(VM vm, In value, Out result) {
      // TODO Update this when we actually have kinded values
      result = Boolean::build(vm, false);
      return OpResult::proceed();
    }
  };

  class IsFuture: public Builtin<IsFuture> {
  public:
    IsFuture(): Builtin("isFuture") {}

    OpResult operator()(VM vm, In value, Out result) {
      result = Boolean::build(vm, value.is<ReadOnly>());
      return OpResult::proceed();
    }
  };

  class IsFailed: public Builtin<IsFailed> {
  public:
    IsFailed(): Builtin("isFailed") {}

    OpResult operator()(VM vm, In value, Out result) {
      result = Boolean::build(vm, value.is<FailedValue>());
      return OpResult::proceed();
    }
  };

  class IsDet: public Builtin<IsDet> {
  public:
    IsDet(): Builtin("isDet") {}

    OpResult operator()(VM vm, In value, Out result) {
      result = Boolean::build(vm, !value.isTransient());
      return OpResult::proceed();
    }
  };

  class Status: public Builtin<Status> {
  public:
    Status(): Builtin("status") {}

    OpResult operator()(VM vm, In value, Out result) {
      if (value.isTransient()) {
        if (value.is<ReadOnly>())
          result = Atom::build(vm, MOZART_STR("future"));
        else if (value.is<FailedValue>())
          result = Atom::build(vm, MOZART_STR("failed"));
        else
          result = Atom::build(vm, MOZART_STR("free"));
      } else {
        result = buildTuple(vm, MOZART_STR("det"), OptVar::build(vm));
      }

      return OpResult::proceed();
    }
  };

  class TypeOf: public Builtin<TypeOf> {
  public:
    TypeOf(): Builtin("type") {}

    OpResult operator()(VM vm, In value, Out result) {
      if (value.isTransient())
        return OpResult::waitFor(vm, value);

      result = build(vm, value.type()->getTypeAtom(vm));
      return OpResult::proceed();
    }
  };

  class IsNeeded: public Builtin<IsNeeded> {
  public:
    IsNeeded(): Builtin("isNeeded") {}

    OpResult operator()(VM vm, In value, Out result) {
      bool boolResult = DataflowVariable(value).isNeeded(vm);
      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class LowerEqual: public Builtin<LowerEqual> {
  public:
    LowerEqual(): Builtin("=<") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      int res = 0;
      MOZART_CHECK_OPRESULT(Comparable(left).compare(vm, right, res));

      result = Boolean::build(vm, res <= 0);
      return OpResult::proceed();
    }
  };

  class LowerThan: public Builtin<LowerThan> {
  public:
    LowerThan(): Builtin("<") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      int res = 0;
      MOZART_CHECK_OPRESULT(Comparable(left).compare(vm, right, res));

      result = Boolean::build(vm, res < 0);
      return OpResult::proceed();
    }
  };

  class GreaterEqual: public Builtin<GreaterEqual> {
  public:
    GreaterEqual(): Builtin(">=") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      int res = 0;
      MOZART_CHECK_OPRESULT(Comparable(left).compare(vm, right, res));

      result = Boolean::build(vm, res >= 0);
      return OpResult::proceed();
    }
  };

  class GreaterThan: public Builtin<GreaterThan> {
  public:
    GreaterThan(): Builtin(">") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      int res = 0;
      MOZART_CHECK_OPRESULT(Comparable(left).compare(vm, right, res));

      result = Boolean::build(vm, res > 0);
      return OpResult::proceed();
    }
  };

  class HasFeature: public Builtin<HasFeature> {
  public:
    HasFeature(): Builtin("hasFeature") {}

    OpResult operator()(VM vm, In record, In feature, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(
        Dottable(record).hasFeature(vm, feature, boolResult));

      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class CondSelect: public Builtin<CondSelect> {
  public:
    CondSelect(): Builtin("condSelect") {}

    OpResult operator()(VM vm, In record, In feature, In def, Out result) {
      return Dottable(record).condSelect(vm, feature, def, result);
    }
  };

  class MakeFailed: public Builtin<MakeFailed> {
  public:
    MakeFailed(): Builtin("failedValue") {}

    OpResult operator()(VM vm, In exception, Out result) {
      result = FailedValue::build(vm, exception.getStableRef(vm));
      return OpResult::proceed();
    }
  };

  class MakeReadOnly: public Builtin<MakeReadOnly> {
  public:
    MakeReadOnly(): Builtin("readOnly") {}

    OpResult operator()(VM vm, In variable, Out result) {
      // TODO Test on something more generic than Variable and OptVar
      if (variable.is<Variable>() || variable.is<OptVar>()) {
        StableNode* readOnly = new (vm) StableNode;
        readOnly->init(vm, ReadOnly::build(vm, variable.getStableRef(vm)));

        result.copy(vm, *readOnly);
        DataflowVariable(variable).addToSuspendList(vm, result);
      } else {
        result.copy(vm, variable);
      }

      return OpResult::proceed();
    }
  };

private:
  template <class FDotAssignable, class FCellLike, class FOther>
  static OpResult catHelperBase(VM vm, RichNode value,
                                const FDotAssignable& fDotAssignable,
                                const FCellLike& fCellLike,
                                const FOther& fOther) {
    using namespace patternmatching;

    OpResult matchRes = OpResult::proceed();
    UnstableNode dotAssignable, feature;

    if (matchesSharp(vm, matchRes, value,
                     capture(dotAssignable), capture(feature))) {
      return fDotAssignable(vm, dotAssignable, feature);
    } else if (matchRes.isProceed()) {
      bool isCell;
      MOZART_CHECK_OPRESULT(CellLike(value).isCell(vm, isCell));

      if (isCell)
        return fCellLike(vm, value);
      else
        return fOther(vm, value);
    } else {
      return matchRes;
    }
  }

  template <class FDotAssignable, class FCellLike>
  static OpResult catHelper(VM vm, RichNode value,
                            const FDotAssignable& fDotAssignable,
                            const FCellLike& fCellLike) {
    return catHelperBase(vm, value,
      fDotAssignable, fCellLike,
      [] (VM vm, RichNode value) -> OpResult {
        return raiseTypeError(vm, MOZART_STR("Cell or A#I or D#F"), value);
      }
    );
  }

  template <class FDotAssignable, class FCellLike, class FObjectLike>
  static OpResult catOOHelper(VM vm, RichNode self, RichNode value,
                              const FDotAssignable& fDotAssignable,
                              const FCellLike& fCellLike,
                              const FObjectLike& fObjectLike) {
    return catHelperBase(vm, value,
      fDotAssignable, fCellLike,
      [self, &fObjectLike] (VM vm, RichNode value) -> OpResult {
        return fObjectLike(vm, self, value);
      }
    );
  }
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODVALUE_H
