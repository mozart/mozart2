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

#ifndef MOZART_VM_H
#define MOZART_VM_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

///////////////////
// BuiltinModule //
///////////////////

BuiltinModule::BuiltinModule(VM vm, const char* name)
  : _name(vm->getAtom(name)) {}

template <typename T>
void BuiltinModule::initModule(VM vm, T&& module) {
  _module = vm->protect(std::forward<T>(module));
}

///////////////////////////////
// VirtualMachineEnvironment //
///////////////////////////////

std::shared_ptr<BigIntImplem> VirtualMachineEnvironment::newBigIntImplem(VM vm, nativeint value) {
  raiseError(vm, "Overflow! BigInt unsupported in the default VM environment without implementation");
}

std::shared_ptr<BigIntImplem> VirtualMachineEnvironment::newBigIntImplem(VM vm, double value) {
  raiseError(vm, "Overflow! BigInt unsupported in the default VM environment without implementation");
}

std::shared_ptr<BigIntImplem> VirtualMachineEnvironment::newBigIntImplem(VM vm, const std::string& value) {
  raiseError(vm, "Overflow! BigInt unsupported in the default VM environment without implementation");
}

void VirtualMachineEnvironment::sendOnVMPort(VM from, VMIdentifier to, RichNode value) {
  raiseError(from, "{Send VMPort} not implemented in this environment");
}

////////////////////
// VirtualMachine //
////////////////////

void registerCoreModules(VM vm);

VirtualMachine::VirtualMachine(VirtualMachineEnvironment& environment,
                               VirtualMachineOptions options):
  rootGlobalNode(nullptr), environment(environment),
  _propertyRegistry(options),
  gc(this, environment.getSecondMemoryManagerRef()), sc(this),
  _referenceTime(0) {

  _preemptRequestedNot.clear();
  _exitRunRequestedNot.clear();
  _gcRequestedNot.clear();

  memoryManager.init(this);

  _topLevelSpace = new (this) Space(this);
  _currentSpace = _topLevelSpace;
  _currentThread = nullptr;
  _isOnTopLevel = true;

  _builtinModules = new (this) NodeDictionary;
  _propertyRegistry.create(this);

  _cleanupList = nullptr;

  _envUseDynamicPreemption = environment.useDynamicPreemption();
  _preemptRequestedNot.test_and_set();
  _exitRunRequestedNot.test_and_set();
  _gcRequestedNot.test_and_set();

  initialize();
  _pickleTypesRecord = new (this) StableNode(this, Pickler::buildTypesRecord(this));

  registerCoreModules(this);
  _propertyRegistry.registerPredefined(this);
}

VirtualMachine::~VirtualMachine() {
  doCleanup();
}

bool VirtualMachine::testPreemption() {
  return testAndClearPreemptRequested() ||
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

void VirtualMachine::registerBuiltinModule(
  const std::shared_ptr<BuiltinModule>& module) {

  UnstableNode moduleName = build(this, module->getName());
  UnstableNode* moduleValue;
  _builtinModules->lookupOrCreate(this, moduleName, moduleValue);
  moduleValue->copy(this, module);
}

template <typename T>
UnstableNode VirtualMachine::findBuiltinModule(T&& name) {
  UnstableNode nameNode(this, std::forward<T>(name));
  UnstableNode* moduleNode;
  if (_builtinModules->lookup(this, nameNode, moduleNode)) {
    auto module = getPointerArgument<BuiltinModule>(this, *moduleNode,
                                                    "BuiltinModule");
    return { this, module->getModule() };
  } else {
    raiseError(this, "foreign",
               "cannotFindBootModule", nameNode);
  }
}

template <typename T, typename U>
UnstableNode VirtualMachine::findBuiltin(T&& moduleName, U&& builtinName) {
  auto module = findBuiltinModule(std::forward<T>(moduleName));
  UnstableNode builtinNameNode(this, std::forward<U>(builtinName));
  return Dottable(module).dot(this, builtinNameNode);
}

UUID VirtualMachine::genUUID() {
  return environment.genUUID(this);
}

void VirtualMachine::setAlarm(std::int64_t delay, StableNode* wakeable) {
  std::int64_t expiration = getReferenceTime() + delay;

  auto iter = _alarms.removable_begin();
  while ((iter != _alarms.removable_end()) && (iter->expiration < expiration))
    ++iter;

  _alarms.insert_before_new(this, iter, expiration, wakeable);
}

template <typename T>
ProtectedNode VirtualMachine::protect(T&& node) {
  /* Yes, it must always be a *new* StableNode, otherwise protecting twice
   * the same node fails!
   */
  auto result = std::make_shared<StableNode*>(
    new (this) StableNode(this, std::forward<T>(node)));
  _protectedNodes.emplace_front(result);
  return ProtectedNode(std::move(result));
}

void VirtualMachine::initialize() {
  coreatoms.initialize(this, atomTable);
}

void VirtualMachine::doGC() {
  // Update stats (1)
  getPropertyRegistry().stats.totalUsedMemory +=
    memoryManager.getAllocatedOutsideFreeList();

  environment.withSecondMemoryManager([this] (MemoryManager& secondMemoryManager) {
    auto cleanupList = acquireCleanupList();
    gc.doGC(secondMemoryManager);
    doCleanup(cleanupList);
    secondMemoryManager.releaseExtraAllocs();
  });

  // Handle the GC watcher
  UnstableNode watcher;
  if (getPropertyRegistry().get(this, "gc.watcher", watcher)) {
    assert(RichNode(watcher).is<ReadOnlyVariable>());
    UnstableNode unitNode(this, unit);
    RichNode(watcher).as<ReadOnlyVariable>().bindReadOnly(this, unitNode);

    // Put a new watcher
    getPropertyRegistry().put(this, "gc.watcher",
                              ReadOnlyVariable::build(this),
                              /* forceWriteConstantProp = */ true);
  }

  // Update stats (2)
  size_t activeMemory = memoryManager.getAllocated();
  getPropertyRegistry().stats.activeMemory = activeMemory;
  getPropertyRegistry().computeGCThreshold(activeMemory);

  if (activeMemory > getPropertyRegistry().config.maxGCThreshold) {
    std::cerr << "FATAL: The active memory (" << activeMemory << ") ";
    std::cerr << "after a GC is over the maximal heap size threshold: ";
    std::cerr << getPropertyRegistry().config.maxGCThreshold << std::endl;
    throw std::bad_alloc();
  }

  adjustHeapSize();
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

void VirtualMachine::adjustHeapSize() {
  auto& config = getPropertyRegistry().config;

  size_t tolerance = config.gcThresholdTolerance;
  size_t wishedHeapSize = config.gcThreshold / 100 * (100 + tolerance);
  size_t newHeapSize = config.heapSize;

  if (wishedHeapSize > newHeapSize) {
    if (newHeapSize == config.maximalHeapSize)
      return;

    while (wishedHeapSize > newHeapSize)
      newHeapSize *= 2;

    newHeapSize = std::min(newHeapSize, config.maximalHeapSize);
    config.heapSize = newHeapSize;
    requestGC(); // To use the new heap size
  } else if (wishedHeapSize < newHeapSize / 2) {
    if (newHeapSize == config.minimalHeapSize)
      return;

    while (wishedHeapSize < newHeapSize / 2)
      newHeapSize /= 2;

    newHeapSize = std::max(newHeapSize, config.minimalHeapSize);
    config.heapSize = newHeapSize;
    requestGC(); // To use the new heap size
  }
}

void VirtualMachine::startGC(GC gc, MemoryManager& secondMemoryManager) {
  VMAllocatedList<AlarmRecord> alarms = std::move(_alarms);

  // Swap spaces
  memoryManager.swap(secondMemoryManager);
  memoryManager.init(this);

  // Forget lists of things
  atomTable = AtomTable();
  aliveThreads = RunnableList();
  _alarms = VMAllocatedList<AlarmRecord>();
  rootGlobalNode = nullptr;

  // Reinitialize the VM
  initialize();

  // Roots of garbage collection

  // Top-level space
  gc->copySpace(_topLevelSpaceRef, _topLevelSpaceRef);

  // Builtin modules and property registry
  _builtinModules = new (this) NodeDictionary(gc, *_builtinModules);
  _propertyRegistry.gCollect(gc);

  // Runnable threads
  getThreadPool().gCollect(gc);

  // Protected nodes
  gcProtectedNodes(gc);

  // Pending alarms
  for (auto iter = alarms.begin(); iter != alarms.end(); ++iter) {
    _alarms.push_back_new(this, iter->expiration, iter->wakeable);
    gc->copyStableRef(_alarms.back().wakeable, _alarms.back().wakeable);
  }

  // Pickle types record
  gc->copyStableRef(_pickleTypesRecord, _pickleTypesRecord);

  // Environmental roots
  environment.gCollect(gc);
}

void VirtualMachine::gcProtectedNodes(GC gc) {
  /* Elements that are still referenced somewhere are garbage-collected, and
   * the StableNode* is updated to point to the GCed node.
   *
   * Elements that are not referenced anymore are erased from the list of
   * protected nodes.
   */

  auto previous = _protectedNodes.before_begin();
  auto current = _protectedNodes.begin();

  while (current != _protectedNodes.end()) {
    auto locked = current->lock();
    if (locked) {
      gc->copyStableRef(*locked, *locked);
      previous = current++;
    } else {
      _protectedNodes.erase_after(previous);
      current = previous;
      ++current;
    }
  }
}

VMCleanupListNode* VirtualMachine::acquireCleanupList() {
  auto result = _cleanupList;
  _cleanupList = nullptr;
  return result;
}

void VirtualMachine::doCleanup(VMCleanupListNode* cleanupList) {
  while (cleanupList != nullptr) {
    cleanupList->handler(this);
    cleanupList = cleanupList->next;
  }
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

#endif // MOZART_VM_H
