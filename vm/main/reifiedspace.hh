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
      unify(vm, _var, _value);
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
    _var.make<Unbound>(vm, space);
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

    UnstableNode valueNode = trivialBuild(vm, value);
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

}

#ifndef MOZART_GENERATOR

namespace mozart {

//////////////////
// ReifiedSpace //
//////////////////

#include "ReifiedSpace-implem.hh"

Implementation<ReifiedSpace>::Implementation(VM vm, GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  gr->copySpace(_space, from->_space);
  _status = from->_status;
}

BuiltinResult Implementation<ReifiedSpace>::isSpace(
  VM vm, UnstableNode* result) {
  result->make<Boolean>(vm, true);
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<ReifiedSpace>::askSpace(
  Self self, VM vm, UnstableNode* result) {

  using namespace patternmatching;

  switch (status()) {
    case ssFailed: {
      result->make<Atom>(vm, u"failed");
      return BuiltinResult::proceed();
    }

    case ssMerged: {
      result->make<Atom>(vm, u"merged");
      return BuiltinResult::proceed();
    }

    case ssNormal: {
      Space* space = getSpace();

      if (!space->isAdmissible(vm))
        return raise(vm, u"spaceAdmissible", self);

      UnstableNode statusVar(vm, *space->getStatusVar());
      BuiltinResult res = BuiltinResult::proceed();

      if (matchesTuple(vm, res, statusVar, u"succeeded", wildcard())) {
        result->make<Atom>(vm, u"succeeded");
      } else if (res.isProceed()) {
        *result = std::move(statusVar);
      } else {
        return res;
      }

      return BuiltinResult::proceed();
    }

    default: {
      assert(false);
      return BuiltinResult::failed();
    }
  }
}

BuiltinResult Implementation<ReifiedSpace>::askVerboseSpace(
  Self self, VM vm, UnstableNode* result) {

  switch (status()) {
    case ssFailed: {
      result->make<Atom>(vm, u"failed");
      return BuiltinResult::proceed();
    }

    case ssMerged: {
      result->make<Atom>(vm, u"merged");
      return BuiltinResult::proceed();
    }

    case ssNormal: {
      Space* space = getSpace();

      if (!space->isAdmissible(vm))
        return raise(vm, u"spaceAdmissible", self);

      if (space->isBlocked() && !space->isStable()) {
        UnstableNode statusVar(vm, *space->getStatusVar());
        *result = buildTuple(vm, u"suspended", statusVar);

        return BuiltinResult::proceed();
      }

      result->copy(vm, *space->getStatusVar());
      return BuiltinResult::proceed();
    }

    default: {
      assert(false);
      return BuiltinResult::failed();
    }
  }
}

BuiltinResult Implementation<ReifiedSpace>::mergeSpace(
  Self self, VM vm, UnstableNode* result) {

  switch (status()) {
    case ssFailed:
      return BuiltinResult::failed();

    case ssMerged:
      return raise(vm, u"spaceMerged");

    case ssNormal: {
      Space* currentSpace = vm->getCurrentSpace();
      Space* space = getSpace();

      if (!space->isAdmissible(currentSpace))
        return raise(vm, u"spaceAdmissible");

      if (space->getParent() != currentSpace) {
        // TODO This is not an error, but I don't know what to do with it yet
        return raise(vm, u"spaceMergeNotImplemented");
      }

      // Update status var
      RichNode statusVar = *space->getStatusVar();
      if (statusVar.type()->isTransient()) {
        UnstableNode atomMerged = UnstableNode::build<Atom>(vm, u"merged");
        DataflowVariable(statusVar).bind(vm, atomMerged);
      }

      // Extract root var
      result->copy(vm, *space->getRootVar());

      // Actual merge
      BuiltinResult res = space->merge(vm, currentSpace);

      this->_status = ssMerged;

      return res;
    }

    default: {
      assert(false);
      return BuiltinResult::failed();
    }
  }
}

BuiltinResult Implementation<ReifiedSpace>::commitSpace(
  Self self, VM vm, UnstableNode* value) {

  using namespace patternmatching;

  switch (status()) {
    case ssFailed:
      return BuiltinResult::proceed();

    case ssMerged:
      return raise(vm, u"spaceMerged");

    case ssNormal: {
      Space* space = getSpace();

      if (!space->isAdmissible(vm))
        return raise(vm, u"spaceAdmissible");

      if (!space->hasDistributor())
        return raise(vm, u"spaceNoChoice", self);

      RichNode val = *value;
      BuiltinResult res = BuiltinResult::proceed();
      nativeint left, right;

      if (matches(vm, res, val, capture(left))) {
        int commitResult = space->commit(vm, left);
        if (commitResult < 0)
          return raise(vm, u"spaceAltRange", self, left, -commitResult);

        return BuiltinResult::proceed();
      } else if (matchesSharp(vm, res, val, capture(left), capture(right))) {
        return raise(vm, u"notImplemented", u"commitRange");
      } else {
        return matchTypeError(vm, res, val, u"int or range");
      }
    }

    default: {
      assert(false);
      return BuiltinResult::failed();
    }
  }
}

BuiltinResult Implementation<ReifiedSpace>::cloneSpace(
  Self self, VM vm, UnstableNode* result) {

  switch (status()) {
    case ssFailed:
      result->make<ReifiedSpace>(vm, ssFailed);
      return BuiltinResult::proceed();

    case ssMerged:
      return raise(vm, u"spaceMerged");

    case ssNormal: {
      Space* space = getSpace();

      if (!space->isAdmissible(vm))
        return raise(vm, u"spaceAdmissible");

      RichNode statusVar = *space->getStatusVar();
      if (statusVar.type()->isTransient())
        return BuiltinResult::waitFor(vm, statusVar);

      Space* copy = space->clone(vm);
      result->make<ReifiedSpace>(vm, copy);

      return BuiltinResult::proceed();
    }

    default: {
      assert(false);
      return BuiltinResult::failed();
    }
  }
}

}

#endif // MOZART_GENERATOR

#endif // __REIFIEDSPACE_H
