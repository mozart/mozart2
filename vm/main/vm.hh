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

#ifndef __VM_H
#define __VM_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

////////////////////
// VirtualMachine //
////////////////////

VirtualMachine::VirtualMachine(VirtualMachineEnvironment& environment):
  environment(environment), gc(this), sc(this) {

  memoryManager.init();

  _topLevelSpace = new (this) Space(this);
  _currentSpace = _topLevelSpace;
  _currentThread = nullptr;
  _isOnTopLevel = true;

  _propertyRegistry.create(this);

  _envUseDynamicPreemption = environment.useDynamicPreemption();
  _preemptRequested = false;
  _exitRunRequested = false;
  _gcRequested = false;
  _referenceTime = 0;

  initialize();

  _propertyRegistry.initialize(this);
}

bool VirtualMachine::testPreemption() {
  return _preemptRequested ||
    (_envUseDynamicPreemption && environment.testDynamicPreemption()) ||
    gc.isGCRequired();
}

void VirtualMachine::setCurrentSpace(Space* space) {
  _currentSpace = space;
  _isOnTopLevel = space->isTopLevel();
}

Space* VirtualMachine::cloneSpace(Space* space) {
  return sc.doCloneSpace(space);
}

UUID VirtualMachine::genUUID() {
  return environment.genUUID();
}

void VirtualMachine::setAlarm(std::int64_t delay, StableNode* wakeable) {
  std::int64_t expiration = _referenceTime + delay;

  auto iter = _alarms.removable_begin();
  while ((iter != _alarms.removable_end()) && (iter->expiration < expiration))
    ++iter;

  _alarms.insert_before_new(this, iter, expiration, wakeable);
}

void VirtualMachine::initialize() {
  coreatoms.initialize(this, atomTable);
}

void VirtualMachine::beforeGR(GR gr) {
  if (gr->kind() == GraphReplicator::grkGarbageCollection) {
    _topLevelSpaceRef = _topLevelSpace;
    assert(_currentSpace == _topLevelSpace);
  }

  for (auto iter = aliveThreads.begin();
       iter != aliveThreads.end(); ++iter) {
    (*iter)->beforeGR();
  }
}

void VirtualMachine::afterGR(GR gr) {
  if (gr->kind() == GraphReplicator::grkGarbageCollection) {
    _topLevelSpace = _topLevelSpaceRef;
    _currentSpace = _topLevelSpace;
  }

  for (auto iter = aliveThreads.begin();
       iter != aliveThreads.end(); ++iter) {
    (*iter)->afterGR();
  }
}

void VirtualMachine::startGC(GC gc) {
  VMAllocatedList<AlarmRecord> alarms = std::move(_alarms);

  // Swap spaces
  getMemoryManager().swapWith(getSecondMemoryManager());
  getMemoryManager().init();

  // Forget lists of things
  atomTable = AtomTable();
  aliveThreads = RunnableList();
  _alarms = VMAllocatedList<AlarmRecord>();

  // Reinitialize the VM
  initialize();

  // Roots of garbage collection

  // Top-level space
  gc->copySpace(_topLevelSpaceRef, _topLevelSpaceRef);

  // Property registry
  _propertyRegistry.gCollect(gc);

  // Runnable threads
  getThreadPool().gCollect(gc);

  // Protected nodes
  _protectedNodes.gCollect(gc);

  // Pending alarms
  for (auto iter = alarms.begin(); iter != alarms.end(); ++iter) {
    _alarms.push_back_new(this, iter->expiration, iter->wakeable);
    gc->copyStableRef(_alarms.back().wakeable, _alarms.back().wakeable);
  }

  // Environmental roots
  environment.gCollect(gc);
}

}

// new operators must be declared outside of any namespace

void* operator new (size_t size, mozart::VM vm) {
  return vm->getMemory(size);
}

void* operator new[] (size_t size, mozart::VM vm) {
  return vm->getMemory(size);
}

#endif // MOZART_GENERATOR

#endif // __VM_H
