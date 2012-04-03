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

#include "reifiedspace-decl.hh"

#include "coreinterfaces.hh"
#include "boolean.hh"
#include "corebuilders.hh"

namespace mozart {

//////////////////
// ReifiedSpace //
//////////////////

#ifndef MOZART_GENERATOR
#include "ReifiedSpace-implem.hh"
#endif

Implementation<ReifiedSpace>::Implementation(VM vm, GC gc, Self from) {
  gc->gcSpace(from->_space, _space);
  _status = from->_status;
}

BuiltinResult Implementation<ReifiedSpace>::isSpace(
  VM vm, UnstableNode* result) {
  result->make<Boolean>(vm, true);
  return BuiltinResult::proceed();
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

}

#endif // __REIFIEDSPACE_H
