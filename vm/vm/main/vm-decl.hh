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

#ifndef __VM_DECL_H
#define __VM_DECL_H

#include <cstdlib>

#include "core-forward-decl.hh"

#include "memmanager.hh"

#include "store-decl.hh"
#include "threadpool-decl.hh"
#include "gcollect-decl.hh"
#include "sclone-decl.hh"
#include "space-decl.hh"
#include "uuid-decl.hh"
#include "vmallocatedlist-decl.hh"

#include "atomtable.hh"
#include "coreatoms-decl.hh"
#include "properties-decl.hh"
#include "protect-decl.hh"

namespace mozart {

///////////////////
// BuiltinModule //
///////////////////

class BuiltinModule {
public:
  inline
  BuiltinModule(VM vm, const nchar* name);

  virtual ~BuiltinModule() {}

  atom_t getName() {
    return _name;
  }

  StableNode& getModule() {
    return *_module;
  }
protected:
  template <typename T>
  inline
  void initModule(VM vm, T&& module);
private:
  VM _vm;
  atom_t _name;
  ProtectedNode _module;
};

////////////////////
// VirtualMachine //
////////////////////

class VirtualMachineEnvironment {
public:
  VirtualMachineEnvironment(): _useDynamicPreemption(false) {}

  VirtualMachineEnvironment(bool useDynamicPreemption):
    _useDynamicPreemption(useDynamicPreemption) {}

  VirtualMachineEnvironment(const VirtualMachineEnvironment&) = delete;

  bool useDynamicPreemption() {
    return _useDynamicPreemption;
  }

  virtual bool testDynamicPreemption() {
    return false;
  }

  virtual bool testDynamicExitRun() {
    return false;
  }

  virtual UUID genUUID() = 0;

  virtual void gCollect(GC gc) {
  }
private:
  bool _useDynamicPreemption;
};

class VirtualMachine {
public:
  enum RunExitCode {
    recNeverInvokeAgain, recInvokeAgainNow, recInvokeAgainLater
  };

  typedef std::pair<RunExitCode, std::int64_t> run_return_type;
private:
  struct AlarmRecord {
    AlarmRecord(std::int64_t expiration, StableNode* wakeable):
      expiration(expiration), wakeable(wakeable) {}

    std::int64_t expiration;
    StableNode* wakeable;
  };
public:
  inline
  VirtualMachine(VirtualMachineEnvironment& environment);

  VirtualMachine(const VirtualMachine& src) = delete;

  inline
  ~VirtualMachine();

  void* malloc(size_t size) {
    return memoryManager.malloc(size);
  }

  void free(void* ptr, size_t size) {
    memoryManager.free(ptr, size);
  }

  template <class T>
  StaticArray<T> newStaticArray(size_t size) {
    void* memory = malloc(size * sizeof(T));
    return StaticArray<T>(static_cast<T*>(memory), size);
  }

  template <class T>
  void deleteStaticArray(StaticArray<T> array, size_t size) {
    void* memory = static_cast<void*>((T*) array);
    free(memory, size * sizeof(T));
  }

  void onCleanup(const VMCleanupProc& handler) {
    onCleanup(new (this) VMCleanupListNode, handler);
  }

  void onCleanup(VMCleanupListNode* node, const VMCleanupProc& handler) {
    node->handler = handler;
    node->next = _cleanupList;
    _cleanupList = node;
  }

  run_return_type run();

  inline
  bool testPreemption();

  ThreadPool& getThreadPool() { return threadPool; }

  MemoryManager& getMemoryManager() {
    return memoryManager;
  }

  MemoryManager& getSecondMemoryManager() {
    return secondMemoryManager;
  }

  GlobalExceptionMechanism& getGlobalExceptionMechanism() {
    return exceptionMechanism;
  }

  Space* getTopLevelSpace() {
    return _topLevelSpace;
  }

  Space* getCurrentSpace() {
    return _currentSpace;
  }

  Runnable* getCurrentThread() {
    return _currentThread;
  }

  bool isOnTopLevel() {
    return _isOnTopLevel;
  }

  bool isIntermediateStateAvailable() {
    return _currentThread != nullptr;
  }

  IntermediateState& getIntermediateState() {
    assert(isIntermediateStateAvailable());
    return _currentThread->getIntermediateState();
  }

  inline
  void setCurrentSpace(Space* space);

  inline
  Space* cloneSpace(Space* space);

  VirtualMachineEnvironment& getEnvironment() {
    return environment;
  }

public:
  inline
  void registerBuiltinModule(const std::shared_ptr<BuiltinModule>& module);

  template <typename T>
  inline
  UnstableNode findBuiltinModule(T&& name);

  template <typename T, typename U>
  inline
  UnstableNode findBuiltin(T&& moduleName, U&& builtinName);

public:
  PropertyRegistry& getPropertyRegistry() {
    return _propertyRegistry;
  }

  inline
  UUID genUUID();

  std::int64_t getReferenceTime() {
    return _referenceTime;
  }

  inline
  void setAlarm(std::int64_t delay, StableNode* wakeable);
public:
  CoreAtoms coreatoms;

  atom_t getAtom(const nchar* data) {
    return atomTable.get(this, data);
  }

  atom_t getAtom(size_t length, const nchar* data) {
    return atomTable.get(this, length, data);
  }

  unique_name_t getUniqueName(const nchar* data) {
    return atomTable.getUniqueName(this, data);
  }

  unique_name_t getUniqueName(size_t length, const nchar* data) {
    return atomTable.getUniqueName(this, length, data);
  }
public:
  /** Protect a node from the GC.
   *  Returns a reference-counted ref to that node.
   */
  template <typename T>
  inline
  ProtectedNode protect(T&& node) {
    return _protectedNodes.protect(this, std::forward<T>(node));
  }
public:
  // Influence from the external world
  void requestPreempt() {
    _preemptRequested = true;
  }

  void requestExitRun() {
    _exitRunRequested = true;
    _preemptRequested = true;
  }

  void requestGC() {
    _gcRequested = true;
    _preemptRequested = true;
  }

  void setReferenceTime(std::int64_t value) {
    _referenceTime = value;
  }
private:
  friend class GarbageCollector;
  friend class SpaceCloner;
  friend class Runnable;

  friend void* ::operator new (size_t size, mozart::VM vm);
  friend void* ::operator new[] (size_t size, mozart::VM vm);

  void* getMemory(size_t size) {
    return memoryManager.getMemory(size);
  }

  inline
  void initialize();

  inline
  void doGC();

  inline
  void beforeGR(GR gr);

  inline
  void afterGR(GR gr);

  inline
  void startGC(GC gc);

  inline
  VMCleanupListNode* acquireCleanupList();

  inline
  void doCleanup(VMCleanupListNode* cleanupList);

  void doCleanup() {
    doCleanup(acquireCleanupList());
  }

  ThreadPool threadPool;
  AtomTable atomTable;

  VirtualMachineEnvironment& environment;

  MemoryManager memoryManager;
  MemoryManager secondMemoryManager;

  GlobalExceptionMechanism exceptionMechanism;

  Space* _topLevelSpace;
  Space* _currentSpace;
  Runnable* _currentThread;
  bool _isOnTopLevel;

  NodeDictionary* _builtinModules;
  PropertyRegistry _propertyRegistry;

  RunnableList aliveThreads;
  VMCleanupListNode* _cleanupList;

  GarbageCollector gc;
  SpaceCloner sc;

  VMAllocatedList<AlarmRecord> _alarms;
  internal::ProtectedNodesContainer _protectedNodes;

  // Flags set externally for preemption etc.
  // TODO Use atomic data types
  bool _envUseDynamicPreemption;
  volatile bool _preemptRequested;
  volatile bool _exitRunRequested;
  volatile bool _gcRequested;
  volatile std::int64_t _referenceTime;

  // During GC, we need a SpaceRef version of the top-level space
  SpaceRef _topLevelSpaceRef;
};

}

#endif // __VM_DECL_H
