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

#include "mozartcore.hh"

#include "variables-decl.hh"
#include "boolean-decl.hh"
#include "smallint-decl.hh"
#include "float-decl.hh"
#include "codearea-decl.hh"
#include "callables-decl.hh"
#include "atom-decl.hh"
#include "records-decl.hh"

#include <iostream>

class DataflowVariable;
template<>
struct Interface<DataflowVariable>: ImplementedBy<Unbound, Variable>, NoAutoWait {
  BuiltinResult wait(Node& self, VM vm, Runnable* thread) {
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

class Equatable;
template<>
struct Interface<Equatable>: ImplementedBy<SmallInt, Atom>, NoAutoWait {
  BuiltinResult equals(Node& self, VM vm, UnstableNode* right, UnstableNode* result) {
    if (self.type->isTransient()) {
      // TODO A == B when A and B are aliased transients should return true
      return &self;
    } else {
      // TODO == of non-SmallInt
      std::cout << self.type->getName();
      std::cout << " == (right) not implemented yet" << std::endl;
      result->make<Boolean>(vm, false);
      return BuiltinResultContinue;
    }
  }
};

class BuiltinCallable;
template<>
struct Interface<BuiltinCallable>: ImplementedBy<BuiltinProcedure> {
  BuiltinResult callBuiltin(Node& self, VM vm, int argc, UnstableNode* args[]) {
    // TODO call non-builtin
    std::cout << "BuiltinProcedure expected but " << self.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }
};

class Callable;
template<>
struct Interface<Callable>: ImplementedBy<Abstraction> {
  BuiltinResult getCallInfo(Node& self, VM vm, int* arity, StableNode** body,
                            ProgramCounter* start, int* Xcount,
                            StaticArray<StableNode>* Gs,
                            StaticArray<StableNode>* Ks) {
    // TODO call non-abstraction
    std::cout << "Abstraction expected but " << self.type->getName();
    std::cout << " found" << std::endl;
    *arity = 0;
    *body = nullptr;
    *start = nullptr;
    *Xcount = 0;
    *Gs = nullptr;
    *Ks = nullptr;
    return BuiltinResultContinue;
  }
};

class CodeAreaProvider;
template<>
struct Interface<CodeAreaProvider>: ImplementedBy<CodeArea> {
  BuiltinResult getCodeAreaInfo(Node& self, VM vm, ProgramCounter* start,
                                int* Xcount, StaticArray<StableNode>* Ks) {
    // TODO code area info of a non-CodeArea
    std::cout << "CodeArea expected but " << self.type->getName();
    std::cout << " found" << std::endl;
    *start = nullptr;
    *Xcount = 0;
    *Ks = nullptr;
    return BuiltinResultContinue;
  }
};

class Numeric;
template<>
struct Interface<Numeric>: ImplementedBy<SmallInt, Float> {
  BuiltinResult add(Node& self, VM vm, UnstableNode* right,
                    UnstableNode* result) {
    // TODO add non-(SmallInt or Float)
    std::cout << "SmallInt or Float expected but " << self.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }

  BuiltinResult subtract(Node& self, VM vm, UnstableNode* right,
                         UnstableNode* result) {
    // TODO subtract non-(SmallInt or Float)
    std::cout << "SmallInt or Float expected but " << self.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }

  BuiltinResult multiply(Node& self, VM vm, UnstableNode* right,
                         UnstableNode* result) {
    // TODO multiply non-(SmallInt or Float)
    std::cout << "SmallInt or Float expected but " << self.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }

  BuiltinResult divide(Node& self, VM vm, UnstableNode* right,
                       UnstableNode* result) {
    // TODO divide non-Float
    std::cout << "Float expected but " << self.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }

  BuiltinResult div(Node& self, VM vm, UnstableNode* right,
                    UnstableNode* result) {
    // TODO div non-SmallInt
    std::cout << "SmallInt expected but " << self.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }

  BuiltinResult mod(Node& self, VM vm, UnstableNode* right,
                    UnstableNode* result) {
    // TODO mod non-SmallInt
    std::cout << "SmallInt expected but " << self.type->getName();
    std::cout << " found" << std::endl;
    return BuiltinResultContinue;
  }
};

class IntegerValue;
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

class BooleanValue;
template<>
struct Interface<BooleanValue>: ImplementedBy<Boolean> {
  BuiltinResult valueOrNotBool(Node& self, VM vm, BoolOrNotBool* result) {
    // TODO valueOrNotBool on a non-Boolean
    *result = bNotBool;
    return BuiltinResultContinue;
  }
};

class RecordLike;
template<>
struct Interface<RecordLike>: ImplementedBy<Tuple> {
  BuiltinResult width(Node& self, VM vm, UnstableNode* result) {
    // TODO width on a non-Tuple
    result->make<Boolean>(vm, false);
    return BuiltinResultContinue;
  }

  BuiltinResult dot(Node& self, VM vm, UnstableNode* feature,
                    UnstableNode* result) {
    // TODO dot on a non-Record
    result->make<Boolean>(vm, false);
    return BuiltinResultContinue;
  }

  BuiltinResult dotNumber(Node& self, VM vm, nativeint feature,
                          UnstableNode* result) {
    // TODO dot on a non-Record
    result->make<Boolean>(vm, false);
    return BuiltinResultContinue;
  }
};

class ArrayInitializer;
template<>
struct Interface<ArrayInitializer>:
  ImplementedBy<Tuple, Abstraction, CodeArea> {

  BuiltinResult initElement(Node& self, VM vm, size_t index,
                            UnstableNode* value) {
    // TODO initElement on a non-ArrayInitializer
    return BuiltinResultContinue;
  }
};

#ifndef MOZART_GENERATOR

#include "DataflowVariable-interf.hh"
#include "Equatable-interf.hh"
#include "BuiltinCallable-interf.hh"
#include "Callable-interf.hh"
#include "CodeAreaProvider-interf.hh"
#include "Numeric-interf.hh"
#include "IntegerValue-interf.hh"
#include "BooleanValue-interf.hh"
#include "RecordLike-interf.hh"
#include "ArrayInitializer-interf.hh"

#include "variables.hh"
#include "boolean.hh"
#include "smallint.hh"
#include "float.hh"
#include "codearea.hh"
#include "callables.hh"
#include "atom.hh"
#include "records.hh"

#endif // MOZART_GENERATOR

#endif // __COREINTERFACES_H
