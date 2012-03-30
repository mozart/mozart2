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
#include "memmanlist.hh"

#include "store-decl.hh"
#include "threadpool-decl.hh"
#include "gcollect-decl.hh"

#include "atomtable.hh"

namespace mozart {

////////////////////
// VirtualMachine //
////////////////////

typedef bool (*PreemptionTest)(void* data);

class VirtualMachine {
public:
  inline
  VirtualMachine(PreemptionTest preemptionTest,
                 void* preemptionTestData = nullptr);

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

  inline
  void run();

  inline
  bool testPreemption();

  ThreadPool& getThreadPool() { return threadPool; }

  MemoryManager& getMemoryManager() {
    return memoryManager;
  }

  Space* getTopLevelSpace() {
    return _topLevelSpace;
  }

  Space* getCurrentSpace() {
    return _currentSpace;
  }

  bool isOnTopLevel() {
    return _isOnTopLevel;
  }

  inline
  void setCurrentSpace(Space* space);
private:
  friend class GarbageCollector;
  friend class Runnable;
  friend class Thread;
  friend class Implementation<Atom>;

  VirtualMachine(const VirtualMachine& src) : gc(this) {}

  friend void* ::operator new (size_t size, mozart::VM vm);
  friend void* ::operator new[] (size_t size, mozart::VM vm);

  void* getMemory(size_t size) {
    return memoryManager.getMemory(size);
  }

  // Called from the constructor of Thread
  inline
  void scheduleThread(Runnable* thread);

  ThreadPool threadPool;
  AtomTable atomTable;

  PreemptionTest _preemptionTest;
  void* _preemptionTestData;

  MemoryManager memoryManager;

  Space* _topLevelSpace;
  Space* _currentSpace;
  bool _isOnTopLevel;

  RunnableList aliveThreads;

  GarbageCollector gc;
};

/////////////////////
// VMAllocatedList //
/////////////////////

template <class T>
class VMAllocatedList: public MemManagedList<T> {
public:
  void push_back(VM vm, const T& item) {
    MemManagedList<T>::push_back(vm->getMemoryManager(), item);
  }

  template <class... Args>
  void push_back_new(VM vm, Args... args) {
    MemManagedList<T>::push_back_new(vm->getMemoryManager(), args...);
  }

  void push_front(VM vm, const T& item) {
    MemManagedList<T>::push_front(vm->getMemoryManager(), item);
  }

  template <class... Args>
  void push_front_new(VM vm, Args... args) {
    MemManagedList<T>::push_front_new(vm->getMemoryManager(), args...);
  }

  T pop_front(VM vm) {
    return MemManagedList<T>::pop_front(vm->getMemoryManager());
  }

  void remove_front(VM vm) {
    MemManagedList<T>::remove_front(vm->getMemoryManager());
  }

  void clear(VM vm) {
    MemManagedList<T>::clear(vm->getMemoryManager());
  }

  void splice(VM vm, VMAllocatedList<T>& source) {
    MemManagedList<T>::splice(vm->getMemoryManager(), source);
  }
};

}

#endif // __VM_DECL_H
