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

#include "store.hh"

#include <list>

using namespace std;

//////////////
// Variable //
//////////////

class Variable;

template <>
class Implementation<Variable> {
public:
  typedef SelfType<Variable>::Self Self;
public:
  Implementation<Variable>(VM) {}

  inline
  BuiltinResult wait(Self self, VM vm, Suspendable* thread);

  inline
  BuiltinResult bind(Self self, VM vm, Node* src);
private:
  inline
  void resumePendingThreads(VM vm);

  void transferPendingThreads(VM vm, list<Suspendable*>& source) {
    pendingThreads.splice(pendingThreads.end(), source);
  }

  list<Suspendable*> pendingThreads;
};

/**
 * Type of a dataflow variable
 */
class Variable: public Type {
public:
  Variable() : Type("Variable", false, true) {}

  static const Variable* const type;
private:
  static const Variable rawType;
};

/////////////
// Unbound //
/////////////

class Unbound;

template <>
class Storage<Unbound> {
public:
  typedef void* Type;
};

template <>
class Implementation<Unbound> {
public:
  typedef SelfType<Unbound>::Self Self;
public:
  Implementation<Unbound>() {}
  Implementation<Unbound>(void* dummy) {}

  inline
  BuiltinResult wait(Self self, VM vm, Suspendable* thread);

  inline
  BuiltinResult bind(Self self, VM vm, Node* src);
};

/**
 * Type of an unbound variable (optimized for the no-wait case)
 */
class Unbound: public Type {
public:
  Unbound() : Type("Unbound", false, true) {}

  static const Unbound* const type;

  static void* build(VM) { return nullptr; }
private:
  static const Unbound rawType;
};

#endif // __VARIABLES_DECL_H
