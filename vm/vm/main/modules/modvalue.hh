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

    void operator()(VM vm, In value, In feature, Out result) {
      result = Dottable(value).dot(vm, feature);
    }
  };

  class DotAssign: public Builtin<DotAssign> {
  public:
    DotAssign(): Builtin("dotAssign") {}

    void operator()(VM vm, In value, In feature, In newValue) {
      DotAssignable(value).dotAssign(vm, feature, newValue);
    }
  };

  class DotExchange: public Builtin<DotExchange> {
  public:
    DotExchange(): Builtin("dotExchange") {}

    void operator()(VM vm, In value, In feature, In newValue, Out oldValue) {
      oldValue = DotAssignable(value).dotExchange(vm, feature, newValue);
    }
  };

  class CatAccess: public Builtin<CatAccess> {
  public:
    CatAccess(): Builtin("catAccess") {}

    void operator()(VM vm, In reference, Out result) {
      catHelper(vm, reference,
        [&result] (VM vm, Dottable dottable, RichNode feature) {
          result = dottable.dot(vm, feature);
        },
        [&result] (VM vm, CellLike cellLike) {
          result = cellLike.access(vm);
        }
      );
    }
  };

  class CatAssign: public Builtin<CatAssign> {
  public:
    CatAssign(): Builtin("catAssign") {}

    void operator()(VM vm, In reference, In newValue) {
      catHelper(vm, reference,
        [newValue] (VM vm, DotAssignable dotAssignable, RichNode feature) {
          dotAssignable.dotAssign(vm, feature, newValue);
        },
        [newValue] (VM vm, CellLike cellLike) {
          cellLike.assign(vm, newValue);
        }
      );
    }
  };

  class CatExchange: public Builtin<CatExchange> {
  public:
    CatExchange(): Builtin("catExchange") {}

    void operator()(VM vm, In reference, In newValue, Out oldValue) {
      catHelper(vm, reference,
        [newValue, &oldValue] (VM vm, DotAssignable dotAssignable,
                               RichNode feature) {
          oldValue = dotAssignable.dotExchange(vm, feature, newValue);
        },
        [newValue, &oldValue] (VM vm, CellLike cellLike) {
          oldValue = cellLike.exchange(vm, newValue);
        }
      );
    }
  };

  class CatAccessOO: public Builtin<CatAccessOO> {
  public:
    CatAccessOO(): Builtin("catAccessOO") {}

    void operator()(VM vm, In self, In reference, Out result) {
      catOOHelper(vm, self, reference,
        [&result] (VM vm, Dottable dottable, RichNode feature) {
          result = dottable.dot(vm, feature);
        },
        [&result] (VM vm, CellLike cellLike) {
          result = cellLike.access(vm);
        },
        [&result] (VM vm, ObjectLike self, RichNode attr) {
          result = self.attrGet(vm, attr);
        }
      );
    }
  };

  class CatAssignOO: public Builtin<CatAssignOO> {
  public:
    CatAssignOO(): Builtin("catAssignOO") {}

    void operator()(VM vm, In self, In reference, In newValue) {
      catOOHelper(vm, self, reference,
        [newValue] (VM vm, DotAssignable dotAssignable, RichNode feature) {
          dotAssignable.dotAssign(vm, feature, newValue);
        },
        [newValue] (VM vm, CellLike cellLike) {
          cellLike.assign(vm, newValue);
        },
        [newValue] (VM vm, ObjectLike self, RichNode attr) {
          self.attrPut(vm, attr, newValue);
        }
      );
    }
  };

  class CatExchangeOO: public Builtin<CatExchangeOO> {
  public:
    CatExchangeOO(): Builtin("catExchangeOO") {}

    void operator()(VM vm, In self, In reference, In newValue, Out oldValue) {
      catOOHelper(vm, self, reference,
        [newValue, &oldValue] (VM vm, DotAssignable dotAssignable,
                               RichNode feature) {
          oldValue = dotAssignable.dotExchange(vm, feature, newValue);
        },
        [newValue, &oldValue] (VM vm, CellLike cellLike) {
          oldValue = cellLike.exchange(vm, newValue);
        },
        [newValue, &oldValue] (VM vm, ObjectLike self, RichNode attr) {
          oldValue = self.attrExchange(vm, attr, newValue);
        }
      );
    }
  };

  class EqEq: public Builtin<EqEq> {
  public:
    EqEq(): Builtin("==") {}

    void operator()(VM vm, In left, In right, Out result) {
      result = build(vm, equals(vm, left, right));
    }
  };

  class NotEqEq: public Builtin<NotEqEq> {
  public:
    NotEqEq(): Builtin("\\=") {}

    void operator()(VM vm, In left, In right, Out result) {
      result = build(vm, !equals(vm, left, right));
    }
  };

  class Wait: public Builtin<Wait> {
  public:
    Wait(): Builtin("wait") {}

    void operator()(VM vm, In value) {
      if (value.isTransient())
        waitFor(vm, value);
    }
  };

  class WaitQuiet: public Builtin<WaitQuiet> {
  public:
    WaitQuiet(): Builtin("waitQuiet") {}

    void operator()(VM vm, In value) {
      if (value.isTransient() && !value.is<FailedValue>())
        waitQuietFor(vm, value);
    }
  };

  class WaitNeeded: public Builtin<WaitNeeded> {
  public:
    WaitNeeded(): Builtin("waitNeeded") {}

    void operator()(VM vm, In value) {
      if (!DataflowVariable(value).isNeeded(vm))
        waitQuietFor(vm, value);
    }
  };

  class MakeNeeded: public Builtin<MakeNeeded> {
  public:
    MakeNeeded(): Builtin("makeNeeded") {}

    void operator()(VM vm, In value) {
      DataflowVariable(value).markNeeded(vm);
    }
  };

  class IsFree: public Builtin<IsFree> {
  public:
    IsFree(): Builtin("isFree") {}

    void operator()(VM vm, In value, Out result) {
      result = build(vm, value.isTransient() &&
        !value.is<ReadOnly>() && !value.is<FailedValue>());
    }
  };

  class IsKinded: public Builtin<IsKinded> {
  public:
    IsKinded(): Builtin("isKinded") {}

    void operator()(VM vm, In value, Out result) {
      // TODO Update this when we actually have kinded values
      result = build(vm, false);
    }
  };

  class IsFuture: public Builtin<IsFuture> {
  public:
    IsFuture(): Builtin("isFuture") {}

    void operator()(VM vm, In value, Out result) {
      result = build(vm, value.is<ReadOnly>());
    }
  };

  class IsFailed: public Builtin<IsFailed> {
  public:
    IsFailed(): Builtin("isFailed") {}

    void operator()(VM vm, In value, Out result) {
      result = build(vm, value.is<FailedValue>());
    }
  };

  class IsDet: public Builtin<IsDet> {
  public:
    IsDet(): Builtin("isDet") {}

    void operator()(VM vm, In value, Out result) {
      result = build(vm, !value.isTransient());
    }
  };

  class Status: public Builtin<Status> {
  public:
    Status(): Builtin("status") {}

    void operator()(VM vm, In value, Out result) {
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
    }
  };

  class TypeOf: public Builtin<TypeOf> {
  public:
    TypeOf(): Builtin("type") {}

    void operator()(VM vm, In value, Out result) {
      if (value.isTransient())
        waitFor(vm, value);

      result = build(vm, value.type()->getTypeAtom(vm));
    }
  };

  class IsNeeded: public Builtin<IsNeeded> {
  public:
    IsNeeded(): Builtin("isNeeded") {}

    void operator()(VM vm, In value, Out result) {
      result = build(vm, DataflowVariable(value).isNeeded(vm));
    }
  };

  class LowerEqual: public Builtin<LowerEqual> {
  public:
    LowerEqual(): Builtin("=<") {}

    void operator()(VM vm, In left, In right, Out result) {
      result = build(vm, Comparable(left).compare(vm, right) <= 0);
    }
  };

  class LowerThan: public Builtin<LowerThan> {
  public:
    LowerThan(): Builtin("<") {}

    void operator()(VM vm, In left, In right, Out result) {
      result = build(vm, Comparable(left).compare(vm, right) < 0);
    }
  };

  class GreaterEqual: public Builtin<GreaterEqual> {
  public:
    GreaterEqual(): Builtin(">=") {}

    void operator()(VM vm, In left, In right, Out result) {
      result = build(vm, Comparable(left).compare(vm, right) >= 0);
    }
  };

  class GreaterThan: public Builtin<GreaterThan> {
  public:
    GreaterThan(): Builtin(">") {}

    void operator()(VM vm, In left, In right, Out result) {
      result = build(vm, Comparable(left).compare(vm, right) > 0);
    }
  };

  class HasFeature: public Builtin<HasFeature> {
  public:
    HasFeature(): Builtin("hasFeature") {}

    void operator()(VM vm, In record, In feature, Out result) {
      result = build(vm, Dottable(record).hasFeature(vm, feature));
    }
  };

  class CondSelect: public Builtin<CondSelect> {
  public:
    CondSelect(): Builtin("condSelect") {}

    void operator()(VM vm, In record, In feature, In def, Out result) {
      result = Dottable(record).condSelect(vm, feature, def);
    }
  };

  class MakeFailed: public Builtin<MakeFailed> {
  public:
    MakeFailed(): Builtin("failedValue") {}

    void operator()(VM vm, In exception, Out result) {
      result = FailedValue::build(vm, exception.getStableRef(vm));
    }
  };

  class MakeReadOnly: public Builtin<MakeReadOnly> {
  public:
    MakeReadOnly(): Builtin("readOnly") {}

    void operator()(VM vm, In variable, Out result) {
      result = ReadOnly::newReadOnly(vm, variable);
    }
  };

  class NewReadOnly: public Builtin<NewReadOnly> {
  public:
    NewReadOnly(): Builtin("newReadOnly") {}

    void operator()(VM vm, Out result) {
      result = ReadOnlyVariable::build(vm);
    }
  };

  class BindReadOnly: public Builtin<BindReadOnly> {
  public:
    BindReadOnly(): Builtin("bindReadOnly") {}

    void operator()(VM vm, In readOnly, In value) {
      BindableReadOnly(readOnly).bindReadOnly(vm, value);
    }
  };

private:
  template <class FDotAssignable, class FCellLike, class FOther>
  static void catHelperBase(VM vm, RichNode value,
                            const FDotAssignable& fDotAssignable,
                            const FCellLike& fCellLike,
                            const FOther& fOther) {
    using namespace patternmatching;

    RichNode dotAssignable, feature;

    if (matchesSharp(vm, value, capture(dotAssignable), capture(feature)))
      fDotAssignable(vm, dotAssignable, feature);
    else if (CellLike(value).isCell(vm))
      fCellLike(vm, value);
    else
      fOther(vm, value);
  }

  template <class FDotAssignable, class FCellLike>
  static void catHelper(VM vm, RichNode value,
                        const FDotAssignable& fDotAssignable,
                        const FCellLike& fCellLike) {
    catHelperBase(vm, value,
      fDotAssignable, fCellLike,
      [] (VM vm, RichNode value) {
        raiseTypeError(vm, MOZART_STR("Cell or A#I or D#F"), value);
      }
    );
  }

  template <class FDotAssignable, class FCellLike, class FObjectLike>
  static void catOOHelper(VM vm, RichNode self, RichNode value,
                          const FDotAssignable& fDotAssignable,
                          const FCellLike& fCellLike,
                          const FObjectLike& fObjectLike) {
    catHelperBase(vm, value,
      fDotAssignable, fCellLike,
      [self, &fObjectLike] (VM vm, RichNode value) {
        fObjectLike(vm, self, value);
      }
    );
  }
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODVALUE_H
