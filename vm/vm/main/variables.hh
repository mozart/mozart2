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

//////////////////
// VariableBase //
//////////////////

template <class This>
VariableBase<This>::VariableBase(VM vm, GR gr, HSelf from):
  WithHome(vm, gr, from->home()) {

  for (auto iter = from->pendings.begin();
       iter != from->pendings.end();
       ++iter) {
    pendings.push_back(vm, *iter);
    gr->copyStableRef(pendings.back(), pendings.back());
  }
}

template <class This>
void VariableBase<This>::addToSuspendList(VM vm, RichNode variable) {
  pendings.push_back(vm, variable.getStableRef(vm));
}

template <class This>
void VariableBase<This>::markNeeded(VM vm) {
  /* TODO What's supposed to happen if we're in a subspace?
   * The behavior of Mozart 1.4.0 was to send the needed flag up through
   * space boundaries, effectively making the original variable needed.
   * Since, generally, the computation waiting for the variable to become
   * needed is located in the home space of the variable, this may seem
   * appealing.
   * But it is semantically wrong, somehow, as this allows a subspace to
   * act on a parent space!
   */
  if (!_needed) {
    _needed = true;
    wakeUpPendings(vm);
  }
}

template <class This>
void VariableBase<This>::doBind(RichNode self, VM vm, RichNode src) {
  if (vm->isOnTopLevel()) {
    // The simple, fast binding when on top-level
    if (_needed) {
      DataflowVariable(src).markNeeded(vm);
      src.update();
    }
    self.become(vm, src);
    wakeUpPendings(vm);
  } else {
    // The complicated, slow binding when in a subspace
    bindSubSpace(self, vm, src);
  }
}

template <class This>
void VariableBase<This>::bindSubSpace(RichNode self, VM vm, RichNode src) {
  Space* currentSpace = vm->getCurrentSpace();

  // Is it a speculative binding?
  if (home() != currentSpace) {
    currentSpace->makeBackupForSpeculativeBinding(self.getStableRef(vm));
  }

  // Actual binding
  if (_needed) {
    DataflowVariable(src).markNeeded(vm);
    src.update();
  }
  self.become(vm, src);
  wakeUpPendingsSubSpace(vm, currentSpace);
}

template <class This>
void VariableBase<This>::wakeUpPendings(VM vm) {
  VMAllocatedList<StableNode*> pendings;
  std::swap(pendings, this->pendings);

  for (auto iter = pendings.begin(); iter != pendings.end(); iter++) {
    Wakeable(**iter).wakeUp(vm);
  }

  pendings.clear(vm);
}

template <class This>
void VariableBase<This>::wakeUpPendingsSubSpace(VM vm, Space* currentSpace) {
  /* The general idea here is to wake up things whose home space is the current
   * space or any of its children, but not the others.
   */

  VMAllocatedList<StableNode*> pendings;
  std::swap(pendings, this->pendings);

  for (auto iter = pendings.begin(); iter != pendings.end(); iter++) {
    Wakeable pending = **iter;
    if (pending.shouldWakeUpUnderSpace(vm, currentSpace))
      pending.wakeUp(vm);
  }

  pendings.clear(vm);
}

//////////////
// Variable //
//////////////

#include "Variable-implem.hh"

Variable::Variable(VM vm, GR gr, Self from): VariableBase(vm, gr, from) {}

void Variable::wakeUp(RichNode self, VM vm) {
  UnstableNode temp = Unit::build(vm);
  return bind(self, vm, temp);
}

bool Variable::shouldWakeUpUnderSpace(VM vm, Space* space) {
  return home()->isAncestor(space);
}

void Variable::bind(RichNode self, VM vm, RichNode src) {
  doBind(self, vm, src);
}

//////////////////////
// ReadOnlyVariable //
//////////////////////

#include "ReadOnlyVariable-implem.hh"

ReadOnlyVariable::ReadOnlyVariable(VM vm, GR gr, Self from):
  VariableBase(vm, gr, from) {}

void ReadOnlyVariable::bind(RichNode self, VM vm, RichNode src) {
  waitFor(vm, self);
}

void ReadOnlyVariable::bindReadOnly(RichNode self, VM vm, RichNode src) {
  doBind(self, vm, src);
}

////////////
// OptVar //
////////////

#include "OptVar-implem.hh"

void OptVar::create(SpaceRef& self, VM vm, GR gr, Self from) {
  gr->copySpace(self, from.get().home());
}

void OptVar::addToSuspendList(RichNode self, VM vm, RichNode variable) {
  self.become(vm, Variable::build(vm));
  DataflowVariable(self).addToSuspendList(vm, variable);
}

void OptVar::markNeeded(RichNode self, VM vm) {
  self.become(vm, Variable::build(vm));
  DataflowVariable(self).markNeeded(vm);
}

void OptVar::bind(RichNode self, VM vm, UnstableNode&& src) {
  makeBackupForSpeculativeBindingIfNeeded(self, vm);
  self.become(vm, std::move(src));
}

void OptVar::bind(RichNode self, VM vm, RichNode src) {
  makeBackupForSpeculativeBindingIfNeeded(self, vm);
  self.become(vm, src);
}

void OptVar::makeBackupForSpeculativeBindingIfNeeded(RichNode self, VM vm) {
  // Is it a speculative binding?
  if (!vm->isOnTopLevel()) {
    Space* currentSpace = vm->getCurrentSpace();
    if (home() != currentSpace) {
      // Yes it is, make the backup
      currentSpace->makeBackupForSpeculativeBinding(self.getStableRef(vm));
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

void ReadOnly::newReadOnly(StableNode& dest, VM vm, RichNode underlying) {
  if (needsProtection(vm, underlying)) {
    dest.init(vm, ReadOnly::build(vm, underlying.getStableRef(vm)));
    DataflowVariable(underlying).addToSuspendList(vm, dest);
  } else {
    dest.init(vm, underlying);
  }
}

UnstableNode ReadOnly::newReadOnly(VM vm, RichNode underlying) {
  if (needsProtection(vm, underlying)) {
    StableNode* dest = new (vm) StableNode;
    dest->init(vm, ReadOnly::build(vm, underlying.getStableRef(vm)));
    DataflowVariable(underlying).addToSuspendList(vm, *dest);
    return Reference::build(vm, dest);
  } else {
    return { vm, underlying };
  }
}

bool ReadOnly::needsProtection(VM vm, RichNode underlying) {
  // TODO This is hardly nice. There should be a general predicate here.
  return underlying.is<Variable>() || underlying.is<OptVar>() ||
    underlying.is<ReadOnlyVariable>() || underlying.is<ReflectiveVariable>();
}

void ReadOnly::wakeUp(RichNode self, VM vm) {
  RichNode underlying = *_underlying;

  if (needsProtection(vm, underlying)) {
    // Aaah, no. I was waken up for nothing
    DataflowVariable(underlying).addToSuspendList(vm, self);
  } else {
    self.become(vm, *_underlying);
  }
}

bool ReadOnly::shouldWakeUpUnderSpace(VM vm, Space* space) {
  return true;
}

void ReadOnly::addToSuspendList(VM vm, RichNode variable) {
  DataflowVariable(*_underlying).addToSuspendList(vm, variable);
}

bool ReadOnly::isNeeded(VM vm) {
  return DataflowVariable(*_underlying).isNeeded(vm);
}

void ReadOnly::markNeeded(VM vm) {
  DataflowVariable(*_underlying).markNeeded(vm);
}

void ReadOnly::bind(VM vm, RichNode src) {
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

void FailedValue::addToSuspendList(VM vm, RichNode variable) {
  assert(false);
}

bool FailedValue::isNeeded(VM vm) {
  return true;
}

void FailedValue::markNeeded(VM vm) {
  // Nothing to do
}

void FailedValue::bind(VM vm, RichNode src) {
  return raiseUnderlying(vm);
}

}

#endif // MOZART_GENERATOR

#endif // __VARIABLES_H
