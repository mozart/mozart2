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

Variable::Variable(VM vm, GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  for (auto iter = from->pendings.begin();
       iter != from->pendings.end();
       ++iter) {
    pendings.push_back(vm, *iter);
    gr->copyStableRef(pendings.back(), pendings.back());
  }
}

void Variable::wakeUp(Self self, VM vm) {
  UnstableNode temp = Unit::build(vm);
  return bind(self, vm, temp);
}

bool Variable::shouldWakeUpUnderSpace(VM vm, Space* space) {
  return home()->isAncestor(space);
}

void Variable::addToSuspendList(Self self, VM vm, RichNode variable) {
  pendings.push_back(vm, variable.getStableRef(vm));
}

void Variable::markNeeded(Self self, VM vm) {
  // TODO What's supposed to happen if we're in a subspace?
  if (!_needed) {
    _needed = true;
    wakeUpPendings(vm);
  }
}

void Variable::bind(Self self, VM vm, RichNode src) {
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
  } else {
    // The complicated, slow binding when in a subspace
    bindSubSpace(self, vm, src);
  }
}

void Variable::bindSubSpace(Self self, VM vm, RichNode src) {
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
}

void Variable::transferPendings(VM vm, VMAllocatedList<StableNode*>& src) {
  pendings.splice(vm, src);
}

void Variable::transferPendingsSubSpace(VM vm, Space* currentSpace,
                                        VMAllocatedList<StableNode*>& src) {
  for (auto iter = src.removable_begin();
       iter != src.removable_end(); ) {
    if (Wakeable(**iter).shouldWakeUpUnderSpace(vm, currentSpace))
      pendings.splice(vm, src, iter);
    else
      ++iter;
  }
}

void Variable::wakeUpPendings(VM vm) {
  VMAllocatedList<StableNode*> pendings;
  std::swap(pendings, this->pendings);

  for (auto iter = pendings.begin();
       iter != pendings.end(); iter++) {
    Wakeable(**iter).wakeUp(vm);
  }

  pendings.clear(vm);
}

void Variable::wakeUpPendingsSubSpace(VM vm, Space* currentSpace) {
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

void OptVar::create(SpaceRef& self, VM vm, GR gr, Self from) {
  gr->copySpace(self, from.get().home());
}

void OptVar::addToSuspendList(Self self, VM vm, RichNode variable) {
  self.become(vm, Variable::build(vm));
  DataflowVariable(self).addToSuspendList(vm, variable);
}

void OptVar::markNeeded(Self self, VM vm) {
  self.become(vm, Variable::build(vm));
  DataflowVariable(self).markNeeded(vm);
}

void OptVar::bind(Self self, VM vm, UnstableNode&& src) {
  makeBackupForSpeculativeBindingIfNeeded(self, vm);
  self.become(vm, std::move(src));
}

void OptVar::bind(Self self, VM vm, RichNode src) {
  makeBackupForSpeculativeBindingIfNeeded(self, vm);
  self.become(vm, src);
}

void OptVar::makeBackupForSpeculativeBindingIfNeeded(Self& self, VM vm) {
  // Is it a speculative binding?
  if (!vm->isOnTopLevel()) {
    Space* currentSpace = vm->getCurrentSpace();
    if (home() != currentSpace) {
      // Yes it is, make the backup
      currentSpace->makeBackupForSpeculativeBinding(
        RichNode(self).getStableRef(vm));
    }
  }
}

//////////////
// ReadOnly //
//////////////

#include "ReadOnly-implem.hh"

void ReadOnly::create(StableNode*& self, VM vm, GR gr, Self from) {
  gr->copyStableRef(self, from.get().getUnderlying());
}

void ReadOnly::wakeUp(Self self, VM vm) {
  RichNode underlying = *_underlying;

  // TODO Test on something more generic than Variable and OptVar
  if (underlying.is<Variable>() || underlying.is<OptVar>()) {
    // Aaah, no. I was waken up for nothing
    DataflowVariable(underlying).addToSuspendList(vm, self);
  } else {
    self.become(vm, *_underlying);
  }
}

bool ReadOnly::shouldWakeUpUnderSpace(VM vm, Space* space) {
  return true;
}

void ReadOnly::addToSuspendList(Self self, VM vm, RichNode variable) {
  DataflowVariable(*_underlying).addToSuspendList(vm, variable);
}

bool ReadOnly::isNeeded(VM vm) {
  return DataflowVariable(*_underlying).isNeeded(vm);
}

void ReadOnly::markNeeded(Self self, VM vm) {
  DataflowVariable(*_underlying).markNeeded(vm);
}

void ReadOnly::bind(Self self, VM vm, RichNode src) {
  return waitFor(vm, *_underlying);
}

/////////////////
// FailedValue //
/////////////////

#include "FailedValue-implem.hh"

void FailedValue::create(StableNode*& self, VM vm, GR gr, Self from) {
  gr->copyStableRef(self, from.get().getUnderlying());
}

void FailedValue::raiseUnderlying(VM vm) {
  return raise(vm, *_underlying);
}

void FailedValue::addToSuspendList(Self self, VM vm, RichNode variable) {
  assert(false);
}

bool FailedValue::isNeeded(VM vm) {
  return true;
}

void FailedValue::markNeeded(Self self, VM vm) {
  // Nothing to do
}

void FailedValue::bind(Self self, VM vm, RichNode src) {
  return raiseUnderlying(vm);
}

}

#endif // MOZART_GENERATOR

#endif // __VARIABLES_H
