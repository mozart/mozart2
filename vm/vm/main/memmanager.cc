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

#include "mozart.hh"

#include "memmanager.hh"

#include <new>
#include <iostream>

namespace mozart {

///////////////////
// MemoryManager //
///////////////////

void MemoryManager::init(VM vm) {
  this->vm = vm;

  size_t heapSize = vm->getHeapSize();
  if (_blockSize != heapSize) {
    if (OzDebugGC) {
      std::cerr << "Allocating " << std::setw(9) << heapSize << " bytes" << std::endl;
    }

    ::free(_baseBlock);

    _baseBlock = static_cast<char*>(::malloc(heapSize));
    if (_baseBlock == nullptr) {
      std::cerr << "FATAL: Failed to allocate " << heapSize << " bytes" << std::endl;
      throw std::bad_alloc();
    }
    _blockSize = heapSize;
  }

  _nextBlock = _baseBlock;
  _allocated = 0;

  for (size_t i = 0; i < MaxBuckets; i++)
    freeListBuckets[i] = nullptr;
  _allocatedInFreeList = 0;
}

void* MemoryManager::getMoreMemory(size_t size) {
  void *ptr = ::malloc(size);
  if (ptr == nullptr) {
    std::cerr << "FATAL: Failed to allocate an additional " << size << " bytes" << std::endl;
    throw std::bad_alloc();
  }
  if (OzDebugGC)
    std::cerr << "Extra alloc of " << size << " at " << ptr << std::endl;

  _extraAllocs.push_front(ptr);
  _allocatedInExtra += size;

  // Adjust the heap size so we do not need to GC twice
  size_t activeMemory = vm->getPropertyRegistry().stats.activeMemory + size;
  vm->getPropertyRegistry().computeGCThreshold(activeMemory);
  vm->adjustHeapSize();

  vm->requestGC();

  return ptr;
}

void MemoryManager::releaseExtraAllocs() {
  while (!_extraAllocs.empty()) {
    if (OzDebugGC)
      std::cerr << "Freeing extra alloc " << _extraAllocs.front() << std::endl;
    ::free(_extraAllocs.front());
    _extraAllocs.pop_front();
  }
  _allocatedInExtra = 0;
}

}
