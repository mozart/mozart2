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

#ifndef __SPACE_DECL_H
#define __SPACE_DECL_H

#include "core-forward-decl.hh"

#include "store-decl.hh"
#include "vm-decl.hh"

#include <iostream>

namespace mozart {

struct ScriptEntry {
public:
  UnstableNode left;
  UnstableNode right;
};

class SpaceScript : public VMAllocatedList<ScriptEntry> {
private:
  typedef VMAllocatedList<ScriptEntry> Super;
public:
  ScriptEntry& append(VM vm) {
    Super::push_back_new(vm);
    return back();
  }
};

/**
 * Computation space
 */
class Space {
public:
  enum Status {
    ssNormal, ssReference, ssFailed, ssGCed
  };
public:
  /** Construct the top-level space */
  Space() : _parent(nullptr), _isTopLevel(true), _status(ssNormal) {}

  /** Construct a subspace */
  Space(Space* parent) : _parent(parent), _isTopLevel(false),
    _status(ssNormal) {}

  /** GC constructor */
  inline
  Space(GC gc, Space* from);

  Space* getParent() {
    if (_isTopLevel)
      return nullptr;
    else
      return _parent;
  }

  // Status

  bool isTopLevel() {
    return _isTopLevel;
  }

  Status status() {
    return _status;
  }

  bool isFailed() {
    return _status == ssFailed;
  }

  bool isAlive() {
    for (Space* s = this; !s->isTopLevel(); s = s->getParent())
      if (s->isFailed())
        return false;
    return true;
  }

  StableNode* getRootVar() {
    return &_rootVar;
  }

  // Operations

  // Garbage collection

  Space* gCollect(GC gc) {
    Space* result = new (gc->vm) Space(gc, this);
    _status = ssGCed;
    _gced = result;
    return result;
  }
public:
  // Maintenance

  void incRunnableCount() {
    if (!isTopLevel())
      runnableCount++;
  }

  void decRunnableCount() {
    if (!isTopLevel())
      runnableCount--;
  }
private:
  void setReference(Space* ref) {
    _status = ssReference;
    _reference = ref;
  }
private:
  friend class GarbageCollector;

  Space* getGCed() {
    assert(status() == ssGCed);
    return _gced;
  }
private:
  friend struct SpaceRef;

  union {
    SpaceRef _parent;  // status not in [ssReference, ssGCed] && !isTopLevel
    Space* _reference; // status == ssReference
    Space* _gced;      // status == ssGCed
  };

  bool _isTopLevel;
  Status _status;

  StableNode _rootVar;

  SpaceScript script;

  int runnableCount;
};

}

#endif // __SPACE_DECL_H
