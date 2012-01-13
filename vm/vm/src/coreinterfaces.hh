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
#include "smallint.hh"
#include "emulate.hh"
#include "callables.hh"
#include "variables.hh"

#include <iostream>

struct BuiltinCallable {
  BuiltinCallable(Node& self) : self(Reference::dereference(self)) {};

  BuiltinResult callBuiltin(VM vm, int argc, UnstableNode* args[]) {
    if (self.type == BuiltinProcedure::type) {
      return IMPL(BuiltinResult, BuiltinProcedure, callBuiltin,
                  &self, vm, argc, args);
    } else {
      // TODO call non-builtin
      cout << "BuiltinProcedure expected but " << self.type->getName();
      cout << " found" << endl;
      return BuiltinResultContinue;
    }
  }
private:
  Node& self;
};

struct Callable {
  Callable(Node& self) : self(Reference::dereference(self)) {};

  BuiltinResult getCallInfo(VM vm, int* arity, CodeArea** body,
    StaticArray<StableNode>** Gs) {
    if (self.type == Abstraction::type) {
      return IMPL(BuiltinResult, Abstraction, getCallInfo,
                  &self, vm, arity, body, Gs);
    } else {
      // TODO call non-abstraction
      cout << "Abstraction expected but " << self.type->getName();
      cout << " found" << endl;
      return BuiltinResultContinue;
    }
  }
private:
  Node& self;
};

struct Addable {
  Addable(Node& self) : self(Reference::dereference(self)) {};

  BuiltinResult add(VM vm, UnstableNode* right, UnstableNode* result) {
    if (self.type == SmallInt::type) {
      return IMPL(BuiltinResult, SmallInt, add,
                  &self, vm, right, result);
    } else {
      // TODO add non-SmallInt
      cout << "SmallInt expected but " << self.type->getName();
      cout << " found" << endl;
      return BuiltinResultContinue;
    }
  }
private:
  Node& self;
};

#endif // __COREINTERFACES_H
