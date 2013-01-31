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

#ifndef __MEMMANAGER_H
#define __MEMMANAGER_H

#include <algorithm>

namespace mozart {

const size_t MegaBytes = 1024*1024;

const size_t MAX_MEMORY = 768 * MegaBytes;
const size_t MemoryRoom = 10 * MegaBytes;

class MemoryManager {
public:
  MemoryManager(size_t maxMemory) :
    _nextBlock(nullptr), _baseBlock(nullptr), _maxMemory(maxMemory) {}

  MemoryManager() :
    _nextBlock(nullptr), _baseBlock(nullptr), _maxMemory(MAX_MEMORY) {}

  ~MemoryManager() {
    if (_baseBlock != nullptr)
      ::free(_baseBlock);
  }

  void swapWith(MemoryManager& other) {
    std::swap(_nextBlock, other._nextBlock);
    std::swap(_baseBlock, other._baseBlock);
    std::swap(_maxMemory, other._maxMemory);
    std::swap(_allocated, other._allocated);

    for (size_t i = 0; i < MaxBuckets; i++)
      std::swap(freeListBuckets[i], other.freeListBuckets[i]);
  }

  void init() {
    if (_baseBlock == nullptr) {
      _baseBlock = static_cast<char*>(::malloc(_maxMemory));
      if (_baseBlock == nullptr)
        throw std::bad_alloc();
    }

    _nextBlock = _baseBlock;
    _allocated = 0;

    for (size_t i = 0; i < MaxBuckets; i++)
      freeListBuckets[i] = nullptr;
  }

  void* getMemory(size_t size) {
    if (_allocated + size > _maxMemory) {
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
        return getMemory(bucket * AllocGranularity);
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

  size_t getAllocated() {
    return _allocated;
  }

  bool isGCRequired() {
    return (_allocated + MemoryRoom > _maxMemory);
  }
private:
  size_t bucketFor(size_t size) {
    return (size + (AllocGranularity-1)) / AllocGranularity;
  }

  void* getMoreMemory(size_t size);

  static const size_t AllocGranularity = 2 * sizeof(char*);
  static const size_t MaxBuckets = 64 + 1;

  char* _nextBlock;
  char* _baseBlock;

  size_t _maxMemory;
  size_t _allocated;

  void* freeListBuckets[MaxBuckets];
};

}

#endif // __MEMMANAGER_H
