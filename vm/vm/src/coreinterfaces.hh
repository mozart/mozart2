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

#ifndef __COREINTERFACES_H
#define __COREINTERFACES_H

#include "store.hh"
#include "suspendable.hh"

#include "variables-decl.hh"
#include "boolean-decl.hh"
#include "smallint-decl.hh"
#include "codearea-decl.hh"
#include "callables-decl.hh"

#include <iostream>

struct DataflowVariable;
template<>
struct Interface<DataflowVariable>: ImplementedBy<Unbound, Variable>, NoAutoWait {
  BuiltinResult wait(Node& self, VM vm, Suspendable* thread) {
    if (self.type->isTransient()) {
      return &self;
    } else {
      return BuiltinResultContinue;
    }
  }

  BuiltinResult bind(Node& self, VM vm, Node* src) {
    if (self.type->isTransient()) {
      return &self;
    } else {
      // TODO bind a bound value
      return BuiltinResultContinue;
    }
  }
};

struct Equatable;
template<>
struct Interface<Equatable>: ImplementedBy<SmallInt>, NoAutoWait {
  BuiltinResult equals(Node& self, VM vm, UnstableNode* right, UnstableNode* result) {
    if (self.type->isTransient()) {
      // TODO A == B when A and B are aliased transients should return true
      return &self;
    } else {
      // TODO == of non-SmallInt
      cout << self.type->getName() << " == (right) not implemented yet" << endl;
      result->make<Boolean>(vm, false);
      return BuiltinResultContinue;
    }
  }
};

struct BuiltinCallable;
template<>
struct Interface<BuiltinCallable>: ImplementedBy<BuiltinProcedure> {
  BuiltinResult callBuiltin(Node& self, VM vm, int argc, UnstableNode* args[]) {
    // TODO call non-builtin
    cout << "BuiltinProcedure expected but " << self.type->getName();
    cout << " found" << endl;
    return BuiltinResultContinue;
  }
};

struct Callable;
template<>
struct Interface<Callable>: ImplementedBy<Abstraction> {
  BuiltinResult getCallInfo(Node& self, VM vm, int* arity, StableNode** body,
                            ProgramCounter* start, int* Xcount,
                            StaticArray<StableNode>** Gs,
                            StaticArray<StableNode>** Ks) {
    // TODO call non-abstraction
    cout << "Abstraction expected but " << self.type->getName();
    cout << " found" << endl;
    *arity = 0;
    *body = nullptr;
    *start = nullptr;
    *Xcount = 0;
    *Gs = nullptr;
    *Ks = nullptr;
    return BuiltinResultContinue;
  }
};

struct CodeAreaProvider;
template<>
struct Interface<CodeAreaProvider>: ImplementedBy<CodeArea> {
  BuiltinResult getCodeAreaInfo(Node& self, VM vm, ProgramCounter* start,
				int* Xcount, StaticArray<StableNode>** Ks) {
    // TODO code area info of a non-CodeArea
    cout << "CodeArea expected but " << self.type->getName();
    cout << " found" << endl;
    *start = nullptr;
    *Xcount = 0;
    *Ks = nullptr;
    return BuiltinResultContinue;
  }
};

struct Addable;
template<>
struct Interface<Addable>: ImplementedBy<SmallInt> {
  BuiltinResult add(Node& self, VM vm, UnstableNode* right, UnstableNode* result) {
    // TODO add non-SmallInt
    cout << "SmallInt expected but " << self.type->getName();
    cout << " found" << endl;
    return BuiltinResultContinue;
  }
};

struct IntegerValue;
template<>
struct Interface<IntegerValue>: ImplementedBy<SmallInt> {
  BuiltinResult equalsInteger(Node& self, VM vm, nativeint right, bool* result) {
    // TODO equalsInteger on a non-SmallInt
    *result = false;
    return BuiltinResultContinue;
  }

  BuiltinResult addValue(Node& self, VM vm, nativeint b, UnstableNode* result) {
    // TODO addValue on a non-SmallInt
    result->make<SmallInt>(vm, 0);
    return BuiltinResultContinue;
  }
};

struct BooleanValue;
template<>
struct Interface<BooleanValue>: ImplementedBy<Boolean> {
  BuiltinResult valueOrNotBool(Node& self, VM vm, BoolOrNotBool* result) {
    // TODO valueOrNotBool on a non-Boolean
    *result = bNotBool;
    return BuiltinResultContinue;
  }
};

#ifndef MOZART_GENERATOR

#include "DataflowVariable-interf.hh"
#include "Equatable-interf.hh"
#include "BuiltinCallable-interf.hh"
#include "Callable-interf.hh"
#include "CodeAreaProvider-interf.hh"
#include "Addable-interf.hh"
#include "IntegerValue-interf.hh"
#include "BooleanValue-interf.hh"

#include "variables.hh"
#include "boolean.hh"
#include "smallint.hh"
#include "codearea.hh"
#include "callables.hh"

#endif // MOZART_GENERATOR

#endif // __COREINTERFACES_H
