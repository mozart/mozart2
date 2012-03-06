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

//////////////
// Variable //
//////////////

class Variable;

#ifndef MOZART_GENERATOR
#include "Variable-implem-decl.hh"
#endif

template <>
class Implementation<Variable>: Transient {
public:
  typedef SelfType<Variable>::Self Self;
  typedef SelfType<Variable>::SelfReadOnlyView SelfReadOnlyView;
public:
  Implementation(VM) {}

  inline
  Implementation(VM vm, GC gc, SelfReadOnlyView from);

  inline
  BuiltinResult wait(Self self, VM vm, Runnable* thread);

  inline
  BuiltinResult bind(Self self, VM vm, Node* src);
private:
  inline
  void resumePendingThreads(VM vm);

  void transferPendingThreads(VM vm, VMAllocatedList<Runnable*>& source) {
    pendingThreads.splice(vm, source);
  }

  VMAllocatedList<Runnable*> pendingThreads;
};

/////////////
// Unbound //
/////////////

class Unbound;

#ifndef MOZART_GENERATOR
#include "Unbound-implem-decl.hh"
#endif

template <>
class Implementation<Unbound>: Transient, StoredAs<void*> {
public:
  typedef SelfType<Unbound>::Self Self;
  typedef SelfType<Unbound>::SelfReadOnlyView SelfReadOnlyView;
public:
  Implementation() {}
  Implementation(void* dummy) {}

  static void* build(VM) { return nullptr; }

  inline
  static void* build(VM vm, GC gc, SelfReadOnlyView from);

  inline
  BuiltinResult wait(Self self, VM vm, Runnable* thread);

  inline
  BuiltinResult bind(Self self, VM vm, Node* src);
};

#endif // __VARIABLES_DECL_H
