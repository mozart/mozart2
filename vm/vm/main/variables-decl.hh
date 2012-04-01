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

#ifndef __VARIABLES_DECL_H
#define __VARIABLES_DECL_H

#include "mozartcore.hh"

namespace mozart {

//////////////
// Variable //
//////////////

class Variable;

#ifndef MOZART_GENERATOR
#include "Variable-implem-decl.hh"
#endif

template <>
class Implementation<Variable>: Transient, WithVariableBehavior<90> {
public:
  typedef SelfType<Variable>::Self Self;
public:
  Implementation(VM vm) : _home(vm->getCurrentSpace()) {}

  inline
  Implementation(VM vm, GC gc, Self from);

  Space* home() {
    return _home;
  }

  inline
  void addToSuspendList(Self self, VM vm, Runnable* thread);

  inline
  void addToSuspendList(Self self, VM vm, RichNode variable);

  inline
  BuiltinResult bind(Self self, VM vm, RichNode src);

  inline
  void transferPendings(VM vm, VMAllocatedList<Runnable*>& srcThreads,
                        VMAllocatedList<StableNode*>& srcVariables);

  inline
  void transferPendingsSubSpace(VM vm, Space* currentSpace,
                                VMAllocatedList<Runnable*>& srcThreads,
                                VMAllocatedList<StableNode*>& srcVariables);
private:
  // TODO Might a good candidate for noinline
  inline
  BuiltinResult bindSubSpace(Self self, VM vm, RichNode src);

  inline
  void resumePendings(VM vm);

  inline
  void resumePendingsSubSpace(VM vm, Space* currentSpace);

  SpaceRef _home;

  VMAllocatedList<Runnable*> pendingThreads;
  VMAllocatedList<StableNode*> pendingVariables;
};

#ifndef MOZART_GENERATOR
#include "Variable-implem-decl-after.hh"
#endif

/////////////
// Unbound //
/////////////

class Unbound;

#ifndef MOZART_GENERATOR
#include "Unbound-implem-decl.hh"
#endif

template <>
class Implementation<Unbound>: Transient, StoredAs<SpaceRef>,
  WithVariableBehavior<100> {
public:
  typedef SelfType<Unbound>::Self Self;
public:
  Implementation(SpaceRef home) : _home(home) {}

  static SpaceRef build(VM vm) {
    return vm->getCurrentSpace();
  }

  inline
  static SpaceRef build(VM vm, GC gc, Self from);

  Space* home() {
    return _home;
  }

  inline
  void addToSuspendList(Self self, VM vm, Runnable* thread);

  inline
  void addToSuspendList(Self self, VM vm, RichNode variable);

  inline
  BuiltinResult bind(Self self, VM vm, RichNode src);
private:
  SpaceRef _home;
};

#ifndef MOZART_GENERATOR
#include "Unbound-implem-decl-after.hh"
#endif

}

#endif // __VARIABLES_DECL_H
