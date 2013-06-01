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

#ifndef __REIFIEDSPACE_H
#define __REIFIEDSPACE_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

///////////////////////
// ChooseDistributor //
///////////////////////

class ChooseDistributor: public Distributor {
private:
  class UnifyThread: public Runnable {
  private:
    typedef Runnable Super;
  public:
    UnifyThread(VM vm, Space* space, UnstableNode* var,
                UnstableNode* value): Runnable(vm, space) {
      _var.copy(vm, *var);
      _value.copy(vm, *value);
      resume();
    }

    UnifyThread(GR gr, UnifyThread& from): Runnable(gr, from) {
      gr->copyUnstableNode(_var, from._var);
      gr->copyUnstableNode(_value, from._value);
    }

    void run() {
      MOZART_TRY(vm) {
        unify(vm, _var, _value);
      } MOZART_CATCH(vm, kind, node) {
        assert(false); // TODO Or should we actually handle this case?
      } MOZART_ENDTRY(vm);
      terminate();
    }

    Runnable* gCollect(GC gc) {
      return new (gc->vm) UnifyThread(gc, *this);
    }

    Runnable* sClone(SC sc) {
      return new (sc->vm) UnifyThread(sc, *this);
    }
  private:
    UnstableNode _var;
    UnstableNode _value;
  };
public:
  ChooseDistributor(VM vm, Space* space, nativeint alternatives) {
    _alternatives = alternatives;
    _var = OptVar::build(vm, space);
  }

  ChooseDistributor(GR gr, ChooseDistributor& from) {
    _alternatives = from._alternatives;
    gr->copyUnstableNode(_var, from._var);
  }

  UnstableNode* getVar() {
    return &_var;
  }

  nativeint getAlternatives() {
    return _alternatives;
  }

  nativeint commit(VM vm, Space* space, nativeint value) {
    if (value > _alternatives)
      return -value;

    UnstableNode valueNode = build(vm, value);
    new (vm) UnifyThread(vm, space, &_var, &valueNode);

    return 0;
  }

  virtual Distributor* replicate(GR gr) {
    return new (gr->vm) ChooseDistributor(gr, *this);
  }
private:
  nativeint _alternatives;
  UnstableNode _var;
};

//////////////////
// ReifiedSpace //
//////////////////

#include "ReifiedSpace-implem.hh"

void ReifiedSpace::create(SpaceRef& self, VM vm, GR gr, ReifiedSpace from) {
  gr->copySpace(self, from.home());
}

UnstableNode ReifiedSpace::askSpace(RichNode self, VM vm) {
  using namespace patternmatching;

  Space* space = getSpace();

  if (!space->isAdmissible(vm))
    raise(vm, vm->coreatoms.spaceAdmissible, self);

  RichNode statusVar = *space->getStatusVar();

  if (matchesTuple(vm, statusVar, vm->coreatoms.succeeded, wildcard())) {
    return Atom::build(vm, vm->coreatoms.succeeded);
  } else {
    return { vm, statusVar };
  }
}

UnstableNode ReifiedSpace::askVerboseSpace(RichNode self, VM vm) {
  Space* space = getSpace();

  if (!space->isAdmissible(vm))
    raise(vm, vm->coreatoms.spaceAdmissible, self);

  if (space->isBlocked() && !space->isStable()) {
    return buildTuple(vm, vm->coreatoms.suspended, *space->getStatusVar());
  } else {
    return { vm, *space->getStatusVar() };
  }
}

UnstableNode ReifiedSpace::mergeSpace(RichNode self, VM vm) {
  Space* currentSpace = vm->getCurrentSpace();
  Space* space = getSpace();

  if (!space->isAdmissible(currentSpace))
    raise(vm, vm->coreatoms.spaceAdmissible);

  if (space->getParent() != currentSpace) {
    // TODO This is not an error, but I don't know what to do with it yet
    raise(vm, "spaceMergeNotImplemented");
  }

  // Update status var
  RichNode statusVar = *space->getStatusVar();
  if (statusVar.isTransient()) {
    UnstableNode atomMerged = Atom::build(vm, vm->coreatoms.merged);
    DataflowVariable(statusVar).bind(vm, atomMerged);
  }

  // Extract root var
  auto result = mozart::build(vm, *space->getRootVar());

  // Become a merged space
  self.become(vm, MergedSpace::build(vm));

  // Actual merge
  if (!space->merge(vm, currentSpace))
    fail(vm);

  return result;
}

void ReifiedSpace::commitSpace(RichNode self, VM vm, RichNode value) {
  using namespace patternmatching;

  Space* space = getSpace();

  if (!space->isAdmissible(vm))
    raise(vm, vm->coreatoms.spaceAdmissible);

  if (!space->hasDistributor())
    raise(vm, vm->coreatoms.spaceNoChoice, self);

  nativeint left = 0, right = 0;

  if (matches(vm, value, capture(left))) {
    int commitResult = space->commit(vm, left);
    if (commitResult < 0)
      raise(vm, vm->coreatoms.spaceAltRange, self, left, -commitResult);
  } else if (matchesSharp(vm, value, capture(left), capture(right))) {
    raise(vm, "notImplemented", "commitRange");
  } else {
    raiseTypeError(vm, "int or range", value);
  }
}

UnstableNode ReifiedSpace::cloneSpace(RichNode self, VM vm) {
  Space* space = getSpace();

  if (!space->isAdmissible(vm))
    raise(vm, vm->coreatoms.spaceAdmissible);

  RichNode statusVar = *space->getStatusVar();
  if (statusVar.isTransient())
    waitFor(vm, statusVar);

  Space* copy = space->clone(vm);
  return ReifiedSpace::build(vm, copy);
}

void ReifiedSpace::killSpace(RichNode self, VM vm) {
  Space* space = getSpace();

  if (!space->isAdmissible(vm))
    return raise(vm, vm->coreatoms.spaceAdmissible);

  space->kill(vm);
}

/////////////////
// FailedSpace //
/////////////////

#include "FailedSpace-implem.hh"

void FailedSpace::create(unit_t& self, VM vm, GR gr, FailedSpace from) {
}

UnstableNode FailedSpace::askSpace(VM vm) {
  return Atom::build(vm, vm->coreatoms.failed);
}

UnstableNode FailedSpace::askVerboseSpace(VM vm) {
  return Atom::build(vm, vm->coreatoms.failed);
}

UnstableNode FailedSpace::mergeSpace(VM vm) {
  fail(vm);
}

void FailedSpace::commitSpace(VM vm, RichNode value) {
  // nothing to do
}

UnstableNode FailedSpace::cloneSpace(VM vm) {
  return FailedSpace::build(vm);
}

void FailedSpace::killSpace(VM vm) {
  // nothing to do
}

/////////////////
// MergedSpace //
/////////////////

#include "MergedSpace-implem.hh"

void MergedSpace::create(unit_t& self, VM vm, GR gr, MergedSpace from) {
}

UnstableNode MergedSpace::askSpace(VM vm) {
  return Atom::build(vm, vm->coreatoms.merged);
}

UnstableNode MergedSpace::askVerboseSpace(VM vm) {
  return Atom::build(vm, vm->coreatoms.merged);
}

UnstableNode MergedSpace::mergeSpace(VM vm) {
  raise(vm, vm->coreatoms.spaceMerged);
}

void MergedSpace::commitSpace(VM vm, RichNode value) {
  raise(vm, vm->coreatoms.spaceMerged);
}

UnstableNode MergedSpace::cloneSpace(VM vm) {
  raise(vm, vm->coreatoms.spaceMerged);
}

void MergedSpace::killSpace(VM vm) {
  // nothing to do
}

}

#endif // MOZART_GENERATOR

#endif // __REIFIEDSPACE_H
