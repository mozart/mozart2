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

#include "core-forward-decl.hh"

const size_t MegaBytes = 1024*1024;

const size_t MAX_MEMORY = 512 * MegaBytes;

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

  void init() {
    if (_baseBlock == nullptr)
      _baseBlock = static_cast<char*>(::malloc(_maxMemory));

    _nextBlock = _baseBlock;
    _allocated = 0;
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
private:
  void* getMoreMemory(size_t size);

  char* _nextBlock;
  char* _baseBlock;

  size_t _maxMemory;
  size_t _allocated;
};

#endif // __MEMMANAGER_H
