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

#ifndef __REIFIEDTHREAD_DECL_H
#define __REIFIEDTHREAD_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

///////////////////
// ReifiedThread //
///////////////////

class ReifiedThread;

class ReifiedThreadBase: public Type {
public:
  ReifiedThreadBase(std::string name, const UUID& uuid,
                    bool copiable, bool transient, bool feature,
                    StructuralBehavior structuralBehavior,
                    unsigned char bindingPriority) :
    Type(name, uuid, copiable, transient, feature, structuralBehavior,
         bindingPriority) {}

  inline
  void gCollect(GC gc, RichNode from, StableNode& to) const;

  inline
  void gCollect(GC gc, RichNode from, UnstableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, StableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, UnstableNode& to) const;
};

#ifndef MOZART_GENERATOR
#include "ReifiedThread-implem-decl.hh"
#endif

template <>
class Implementation<ReifiedThread>:
  BasedOn<ReifiedThreadBase>, NoAutoGCollect, NoAutoSClone,
  StoredAs<Runnable*>, Copiable, WithValueBehavior {
public:
  typedef SelfType<ReifiedThread>::Self Self;
public:
  Implementation(Runnable* runnable): _runnable(runnable) {}

  static Runnable* build(VM vm, Runnable* runnable) {
    return runnable;
  }

public:
  inline
  bool equals(VM vm, Self right);

public:
  Runnable* getRunnable() {
    return _runnable;
  }

public:
  // ThreadLike interface

  inline
  OpResult isThread(VM vm, UnstableNode& result);

  inline
  OpResult getThreadPriority(VM vm, ThreadPriority& result);

  inline
  OpResult setThreadPriority(VM vm, ThreadPriority priority);

private:
  Runnable* _runnable;
};

#ifndef MOZART_GENERATOR
#include "ReifiedThread-implem-decl-after.hh"
#endif

}

#endif // __REIFIEDTHREAD_DECL_H
