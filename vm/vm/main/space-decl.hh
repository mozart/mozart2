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

struct TrailEntry {
public:
  TrailEntry(StableNode* node, const Node& saved) : node(node), saved(saved) {}

  StableNode* node;
  Node saved;
};

class SpaceTrail : public VMAllocatedList<TrailEntry> {
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
  Space(VM vm) : vm(vm), _parent(nullptr), _isTopLevel(true), _status(ssNormal),
    _mark(false) {}

  /** Construct a subspace */
  Space(VM vm, Space* parent) : vm(vm), _parent(parent), _isTopLevel(false),
    _status(ssNormal), _mark(false) {}

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

public:
  bool isTopLevel() {
    return _isTopLevel;
  }

  Status status() {
    return _status;
  }

  bool isFailed() {
    return _status == ssFailed;
  }

  inline
  bool isAlive();

  StableNode* getRootVar() {
    return &_rootVar;
  }

  UnstableNode* getStatusVar() {
    return &_statusVar;
  }

// Admissibility

  /* A space A is admissible for an operation while the current space is B iff
   * A is not an ancestor of B.
   */

  inline
  bool isAdmissible(Space* currentSpace);

  bool isAdmissible(VM vm) {
    return isAdmissible(vm->getCurrentSpace());
  }

  bool isAdmissible() {
    return isAdmissible(vm);
  }

// Relations between spaces

public:
  inline
  bool isAncestor(Space* potentialAncestor);

// Speculative bindings

public:
  inline
  void makeBackupForSpeculativeBinding(StableNode* node);

// Operations

public:
  inline
  BuiltinResult merge(VM vm, Space* destSpace);

// Status variable

private:
  inline
  void bindStatusVar(VM vm, RichNode value);

  inline
  void bindStatusVar(VM vm, UnstableNode&& value);

  inline
  UnstableNode newStatusVar(VM vm);

  inline
  UnstableNode genSucceeded(VM vm, bool isEntailed);

// Garbage collection

public:
  inline
  Space* gCollect(GC gc);

// Stability detection

public:
  inline
  void notifyThreadCreated();

  inline
  void notifyThreadTerminated();

  inline
  void notifyThreadResumed();

  inline
  void notifyThreadSuspended();
public:
  inline
  bool isStable();

  inline
  bool isBlocked();
private:
  inline
  void incThreadCount(int n = 1);

  inline
  void decThreadCount();

  inline
  int getThreadCount();

  inline
  void incRunnableThreadCount();

  inline
  void decRunnableThreadCount();

  inline
  bool hasRunnableThreads();

  void checkStability();

// Commit

private:
  void setReference(Space* ref) {
    _status = ssReference;
    _reference = ref;
  }

// Installation and deinstallation

public:
  /**
   * Try to install this space. Returns true on success and false on failure.
   * Upon failure, the highest space that could be installed is installed.
   */
  bool install();
private:
  inline
  Space* findCommonAncestor(Space* other);

  inline
  void deinstallTo(Space* ancestor);

  inline
  bool installFrom(Space* ancestor);

  inline
  void deinstallThis();

  bool installThis(bool isMerge = false);

// The mark

private:
  bool hasMark() {
    return _mark;
  }

  void setMark() {
    _mark = true;
  }

  void unsetMark() {
    _mark = false;
  }

// Fields

private:
  friend struct SpaceRef;

  VM vm;

  union {
    SpaceRef _parent;  // status not in [ssReference, ssGCed] && !isTopLevel
    Space* _reference; // status == ssReference
    Space* _gced;      // status == ssGCed
  };

  bool _isTopLevel;
  Status _status;

  bool _mark;

  VMAllocatedList<Runnable*> suspensionList;

  StableNode _rootVar;
  UnstableNode _statusVar;

  SpaceTrail trail;
  SpaceScript script;

  /*
   * Maintaining a counter of threads
   * Invariants:
   *
   *   threadCount ==
   *     Number of threads th such that th->getSpace() == this,
   *     which have been created but are not yet terminated.
   *     Note that threads that are suspended (even lost, i.e.,
   *     garbage-collectable), or that have failed are part of this count.
   *
   *   cascadedRunnableThreadCount == A + B
   *     where A ==
   *       Number of threads th such that th->getSpace() == this &&
   *       th->isRunnable().
   *     and B ==
   *       Number of spaces sp such that sp->getParent() == this &&
   *       sp->cascadedRunnableThreadCount > 0.
   *
   * These invariants are maintained by the notifyThread...() methods.
   */

  int threadCount;
  int cascadedRunnableThreadCount;
};

}

#endif // __SPACE_DECL_H
