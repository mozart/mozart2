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

#ifndef __CORE_FORWARD_DECL_H
#define __CORE_FORWARD_DECL_H

#ifndef __MOZART_H
#ifndef MOZART_GENERATOR
#error Illegal inclusion chain. You must include "mozart.hh".
#endif
#endif

#include <cstdlib>
#include <cstdint>

namespace mozart {

typedef intptr_t nativeint;

class Type;

class Node;
class StableNode;
class UnstableNode;

class VirtualMachine;
typedef VirtualMachine* VM;

class GraphReplicator;
typedef GraphReplicator* GR;

class GarbageCollector;
typedef GarbageCollector* GC;

class Space;

/**
 * Reference to a Space
 * It is close to a Space*, except that it handles dereferencing transparently
 */
struct SpaceRef {
public:
  SpaceRef() {}

  SpaceRef(Space* space) : space(space) {}

  inline
  Space* operator->();

  Space& operator*() {
    return *operator->();
  }

  operator Space*() {
    return operator->();
  }
private:
  Space* space;
};

template <class T>
class Implementation {
};

}

// new operators must be declared outside of any namespace

inline
void* operator new (size_t size, mozart::VM vm);

inline
void* operator new[] (size_t size, mozart::VM vm);

#endif // __CORE_FORWARD_DECL_H
