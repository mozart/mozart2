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

#ifndef __VARIABLES_H
#define __VARIABLES_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

//////////////
// Variable //
//////////////

#include "Variable-implem.hh"

Implementation<Variable>::Implementation(VM vm, GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  for (auto iter = from->pendings.begin();
       iter != from->pendings.end();
       ++iter) {
    pendings.push_back(vm, *iter);
    gr->copyStableRef(pendings.back(), pendings.back());
  }
}

OpResult Implementation<Variable>::wakeUp(Self self, VM vm) {
  UnstableNode temp = SmallInt::build(vm, 0); // TODO Replace by unit
  return bind(self, vm, temp);
}

bool Implementation<Variable>::shouldWakeUpUnderSpace(VM vm, Space* space) {
  return home()->isAncestor(space);
}

void Implementation<Variable>::addToSuspendList(Self self, VM vm,
                                                RichNode variable) {
  pendings.push_back(vm, variable.getStableRef(vm));
}

void Implementation<Variable>::markNeeded(Self self, VM vm) {
  // TODO What's supposed to happen if we're in a subspace?
  if (!_needed) {
    _needed = true;
    wakeUpPendings(vm);
  }
}

OpResult Implementation<Variable>::bind(Self self, VM vm, RichNode src) {
  if (vm->isOnTopLevel()) {
    // The simple, fast binding when on top-level
    self.become(vm, src);

    /* If the value we were bound to is a Variable too, we have to transfer the
     * variables waiting for this so that they wait for the other Variable.
     * Otherwise, we wake up the variables.
     */
    src.update();
    if (src.is<Variable>()) {
      src.as<Variable>().transferPendings(vm, pendings);
    } else {
      wakeUpPendings(vm);
    }

    return OpResult::proceed();
  } else {
    // The complicated, slow binding when in a subspace
    return bindSubSpace(self, vm, src);
  }
}

OpResult Implementation<Variable>::bindSubSpace(Self self, VM vm,
                                                RichNode src) {
  Space* currentSpace = vm->getCurrentSpace();

  // Is it a speculative binding?
  if (!vm->isOnTopLevel() && (home() != currentSpace)) {
    currentSpace->makeBackupForSpeculativeBinding(
      RichNode(self).getStableRef(vm));
  }

  // Actual binding
  self.become(vm, src);

  /* If the value we were bound to is a Variable too, we have to transfer the
   * variables waiting for this so that they wait for the other Variable.
   * Otherwise, we wake up the variables.
   */
  src.update();
  if (src.is<Variable>()) {
    src.as<Variable>().transferPendingsSubSpace(vm, currentSpace, pendings);
  } else {
    wakeUpPendingsSubSpace(vm, currentSpace);
  }

  return OpResult::proceed();
}

void Implementation<Variable>::transferPendings(
  VM vm, VMAllocatedList<StableNode*>& src) {

  pendings.splice(vm, src);
}

void Implementation<Variable>::transferPendingsSubSpace(
  VM vm, Space* currentSpace, VMAllocatedList<StableNode*>& src) {

  for (auto iter = src.removable_begin();
       iter != src.removable_end(); ) {
    if (Wakeable(**iter).shouldWakeUpUnderSpace(vm, currentSpace))
      pendings.splice(vm, src, iter);
    else
      ++iter;
  }
}

void Implementation<Variable>::wakeUpPendings(VM vm) {
  VMAllocatedList<StableNode*> pendings;
  std::swap(pendings, this->pendings);

  for (auto iter = pendings.begin();
       iter != pendings.end(); iter++) {
    Wakeable(**iter).wakeUp(vm);
  }

  pendings.clear(vm);
}

void Implementation<Variable>::wakeUpPendingsSubSpace(VM vm,
                                                      Space* currentSpace) {
  /* The general idea here is to wake up things whose home space is the current
   * space or any of its children, but not the others.
   */

  VMAllocatedList<StableNode*> pendings;
  std::swap(pendings, this->pendings);

  for (auto iter = pendings.begin();
       iter != pendings.end(); iter++) {
    Wakeable pending = **iter;
    if (pending.shouldWakeUpUnderSpace(vm, currentSpace))
      pending.wakeUp(vm);
  }

  pendings.clear(vm);
}

////////////
// OptVar //
////////////

#include "OptVar-implem.hh"

void Implementation<OptVar>::build(SpaceRef& self, VM vm, GR gr, Self from) {
  gr->copySpace(self, from.get().home());
}

void Implementation<OptVar>::addToSuspendList(Self self, VM vm,
                                              RichNode variable) {
  self.become(vm, Variable::build(vm));
  DataflowVariable(self).addToSuspendList(vm, variable);
}

void Implementation<OptVar>::markNeeded(Self self, VM vm) {
  self.become(vm, Variable::build(vm));
  DataflowVariable(self).markNeeded(vm);
}

OpResult Implementation<OptVar>::bind(Self self, VM vm, RichNode src) {
  // Is it a speculative binding?
  if (!vm->isOnTopLevel()) {
    Space* currentSpace = vm->getCurrentSpace();
    if (home() != currentSpace) {
      currentSpace->makeBackupForSpeculativeBinding(
        RichNode(self).getStableRef(vm));
    }
  }

  // Actual binding
  self.become(vm, src);

  return OpResult::proceed();
}

//////////////
// ReadOnly //
//////////////

#include "ReadOnly-implem.hh"

void Implementation<ReadOnly>::build(StableNode*& self, VM vm, GR gr,
                                     Self from) {
  gr->copyStableRef(self, from.get().getUnderlying());
}

OpResult Implementation<ReadOnly>::wakeUp(Self self, VM vm) {
  RichNode underlying = *_underlying;

  // TODO Test on something more generic than Variable and OptVar
  if (underlying.is<Variable>() || underlying.is<OptVar>()) {
    // Aaah, no. I was waken up for nothing
    DataflowVariable(underlying).addToSuspendList(vm, self);
  } else {
    self.become(vm, underlying);
  }

  return OpResult::proceed();
}

bool Implementation<ReadOnly>::shouldWakeUpUnderSpace(VM vm, Space* space) {
  return true;
}

void Implementation<ReadOnly>::addToSuspendList(Self self, VM vm,
                                                RichNode variable) {
  DataflowVariable(*_underlying).addToSuspendList(vm, variable);
}

bool Implementation<ReadOnly>::isNeeded(VM vm) {
  return DataflowVariable(*_underlying).isNeeded(vm);
}

void Implementation<ReadOnly>::markNeeded(Self self, VM vm) {
  DataflowVariable(*_underlying).markNeeded(vm);
}

OpResult Implementation<ReadOnly>::bind(Self self, VM vm, RichNode src) {
  return OpResult::waitFor(vm, *_underlying);
}

/////////////////
// FailedValue //
/////////////////

#include "FailedValue-implem.hh"

void Implementation<FailedValue>::build(StableNode*& self, VM vm, GR gr,
                                        Self from) {
  gr->copyStableRef(self, from.get().getUnderlying());
}

OpResult Implementation<FailedValue>::raiseUnderlying(VM vm) {
  return OpResult::raise(vm, *_underlying);
}

void Implementation<FailedValue>::addToSuspendList(Self self, VM vm,
                                                   RichNode variable) {
  assert(false);
}

bool Implementation<FailedValue>::isNeeded(VM vm) {
  return true;
}

void Implementation<FailedValue>::markNeeded(Self self, VM vm) {
  // Nothing to do
}

OpResult Implementation<FailedValue>::bind(Self self, VM vm, RichNode src) {
  return raiseUnderlying(vm);
}

}

#endif // MOZART_GENERATOR

#endif // __VARIABLES_H
