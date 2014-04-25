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

#ifndef MOZART_MEMMANAGER_H
#define MOZART_MEMMANAGER_H

#include "core-forward-decl.hh"

#include <cstdlib>
#include <algorithm>
#include <forward_list>

namespace mozart {

const size_t MegaBytes = 1024*1024;

class MemoryManager {
public:
  MemoryManager(VM vm) :
    vm(vm), _nextBlock(nullptr), _baseBlock(nullptr), _blockSize(0), _extraAllocated(0) {}

  ~MemoryManager() {
    if (_baseBlock != nullptr)
      ::free(_baseBlock);
  }

  void swapWith(MemoryManager& other) {
    std::swap(_nextBlock, other._nextBlock);
    std::swap(_baseBlock, other._baseBlock);
    std::swap(_blockSize, other._blockSize);
    std::swap(_allocated, other._allocated);
    std::swap(_extraAllocs, other._extraAllocs);
    std::swap(_extraAllocated, other._extraAllocated);

    for (size_t i = 0; i < MaxBuckets; i++)
      std::swap(freeListBuckets[i], other.freeListBuckets[i]);
  }

  void init();

public:
  // Memory requests and releases

  void* getMemory(size_t size) {
    if (_allocated + size > _blockSize) {
      return getMoreMemory(size);
    } else {
      void* result = static_cast<void*>(_nextBlock);
      _nextBlock += size;
      _allocated += size;
      return result;
    }
  }

  void* malloc(size_t size) {
    if (size == 0)
      return nullptr;

    size_t bucket = bucketFor(size);

    if (bucket < MaxBuckets) {
      // Small block - use free list
      void* list = freeListBuckets[bucket];
      if (list != nullptr) {
        freeListBuckets[bucket] = *static_cast<void**>(list);
        return list;
      } else {
        size_t chunkSize = bucket * AllocGranularity;
        stats.allocatedInFreeList += chunkSize;
        return getMemory(chunkSize);
      }
    } else {
      // Big block - for now use regular malloc/free
      // TODO Allocate a new big block instead
      return ::malloc(size);
    }
  }

  void free(void* ptr, size_t size) {
    if (size == 0)
      return;

    size_t bucket = bucketFor(size);

    if (bucket < MaxBuckets) {
      // Small block - put back in free list
      *static_cast<void**>(ptr) = freeListBuckets[bucket];
      freeListBuckets[bucket] = ptr;
    } else {
      // Big block - for now use regular malloc/free
      ::free(ptr);
    }
  }

  void releaseExtraAllocs();

private:
  size_t bucketFor(size_t size) {
    return (size + (AllocGranularity-1)) / AllocGranularity;
  }

  void* getMoreMemory(size_t size);

public:
  // Query statistics and properties

  size_t getBlockSize() {
    return _blockSize;
  }

  size_t getAllocated() {
    return _allocated + _extraAllocated;
  }

  size_t getAllocatedInFreeList() {
    return stats.allocatedInFreeList;
  }

  size_t getAllocatedOutsideFreeList() {
    return getAllocated() - getAllocatedInFreeList();
  }

private:
  // Fields
  VM vm;

  static const size_t AllocGranularity = 2 * sizeof(char*);
  static const size_t MaxBuckets = 64 + 1;

  char* _nextBlock;
  char* _baseBlock;

  size_t _blockSize;
  size_t _allocated; // in _baseBlock

  void* freeListBuckets[MaxBuckets];

  std::forward_list<void*> _extraAllocs;
  size_t _extraAllocated; // So it can be reset to 0 after releaseExtraAllocs()

  struct {
    size_t allocatedInFreeList;
  } stats;
};

}

#endif // MOZART_MEMMANAGER_H
