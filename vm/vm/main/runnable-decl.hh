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

#ifndef __RUNNABLE_DECL_H
#define __RUNNABLE_DECL_H

#include "core-forward-decl.hh"
#include "store-decl.hh"
#include "vmallocatedlist-decl.hh"

#include <cassert>

namespace mozart {

// This enum is often used for indexing in arrays
// tpCount reflects the number of valid ThreadPriority's
// And you probably don't want to add or remove existing ThreadPriority's
enum ThreadPriority {
  tpLow, tpMiddle, tpHi,
  tpCount
};

///////////////////////
// IntermediateState //
///////////////////////

class IntermediateState {
private:
  typedef VMAllocatedList<UnstableNode> List;
public:
  typedef List::iterator CheckPoint;
public:
  inline
  explicit IntermediateState(VM vm);

  inline
  IntermediateState(VM vm, GR gr, IntermediateState& from);

  CheckPoint makeCheckPoint(VM vm) {
    return _last;
  }

  inline
  void reset(VM vm, CheckPoint checkPoint);

  inline
  void reset(VM vm);

  template <typename... Args>
  inline
  bool fetch(VM vm, const nchar* identity, Args... args);

  template <typename... Args>
  inline
  void store(VM vm, const nchar* identity, Args&&... args);

  template <typename... Args>
  inline
  void resetAndStore(VM vm, CheckPoint checkPoint, const nchar* identity,
                     Args&&... args);

  inline
  void rewind(VM vm);
private:
  List _list;
  List::iterator _last;
};

//////////////
// Runnable //
//////////////

class Runnable {
public:
  inline
  Runnable(VM vm, Space* space, ThreadPriority priority = tpMiddle);

  inline
  Runnable(GR gr, Runnable& from);

  Space* getSpace() {
    return _space;
  }

  ThreadPriority getPriority() { return _priority; }

  inline
  void setPriority(ThreadPriority priority);

  virtual void run() = 0;

  bool isTerminated() { return _terminated; }
  bool isRunnable() { return _runnable; }

  inline
  virtual void resume(bool skipSchedule = false);

  inline
  virtual void suspend(bool skipUnschedule = false);

  inline
  void suspendOnVar(VM vm, RichNode variable, bool skipUnschedule = true);

  inline
  virtual void kill();

  inline
  virtual void injectException(StableNode* exception) {
    /* We cannot come here because there's no way the Oz code has gained a
     * reference to a thread that is not an emulated thread.
     */
    assert(false);
  }

  bool getRaiseOnBlock() {
    return _raiseOnBlock;
  }

  void setRaiseOnBlock(bool value) {
    _raiseOnBlock = value;
  }

  IntermediateState& getIntermediateState() {
    return _intermediateState;
  }

  virtual void beforeGR() {}
  virtual void afterGR() {}

  virtual Runnable* gCollect(GC gc) = 0;
  virtual Runnable* sClone(SC sc) = 0;

  inline
  Runnable* gCollectOuter(GC gc);

  inline
  Runnable* sCloneOuter(SC sc);

  inline
  void restoreAfterGR();
protected:
  inline
  virtual void terminate();

  inline
  virtual void dispose();
public:
  virtual void dump() {}
protected:
  VM vm;
private:
  friend class RunnableList;

  SpaceRef _space;

  ThreadPriority _priority;

  bool _runnable;
  bool _terminated;
  bool _dead;

  bool _raiseOnBlock;

  StableNode _reification;

  IntermediateState _intermediateState;

  Runnable* _replicate;

  Runnable* _previous;
  Runnable* _next;
};

class RunnableList {
public:
  struct iterator {
  public:
    iterator(Runnable* node) : node(node) {}

    bool operator==(const iterator& other) {
      return node == other.node;
    }

    bool operator!=(const iterator& other) {
      return node != other.node;
    }

    iterator operator++() {
      node = node->_next;
      return *this;
    }

    iterator operator++(int) {
      iterator result = *this;
      node = node->_next;
      return result;
    }

    Runnable* operator*() {
      return node;
    }
  private:
    Runnable* node;
  };
public:
  RunnableList() : first(nullptr), last(nullptr) {}

  iterator begin() {
    return iterator(first);
  }

  iterator end() {
    return iterator(nullptr);
  }
private:
  friend class Runnable;

  void insert(Runnable* item) {
    item->_previous = last;
    item->_next = nullptr;

    if (first == nullptr)
      first = item;
    else
      last->_next = item;

    last = item;
  }

  void remove(Runnable* item) {
    if (item->_previous == nullptr)
      first = item->_next;
    else
      item->_previous->_next = item->_next;

    if (item->_next == nullptr)
      last = item->_previous;
    else
      item->_next->_previous = item->_previous;
  }

  Runnable* first;
  Runnable* last;
};

}

#endif // __RUNNABLE_DECL_H
