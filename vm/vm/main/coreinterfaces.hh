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
#include "reifiedspace-decl.hh"

#include "corebuilders.hh"
#include "exchelpers-decl.hh"

#include <iostream>

namespace mozart {

class DataflowVariable;
template<>
struct Interface<DataflowVariable>: ImplementedBy<Unbound, Variable>, NoAutoWait {
  void addToSuspendList(RichNode self, VM vm, Runnable* thread) {
  }

  void addToSuspendList(RichNode self, VM vm, RichNode variable) {
  }

  /**
   * Precondition:
   *   self.type()->getStructuralBehavior() == sbVariable
   */
  BuiltinResult bind(RichNode self, VM vm, RichNode src) {
    assert(self.type()->getStructuralBehavior() == sbVariable);
    assert(false);
    return raiseTypeError(vm, u"Variable", self);
  }
};

class ValueEquatable;
template<>
struct Interface<ValueEquatable>:
  ImplementedBy<SmallInt, Atom, Boolean, Float> {

  /**
   * Precondition:
   *   self.type()->getStructuralBehavior() == sbValue
   *   self.type() == right.type()
   */
  bool equals(RichNode self, VM vm, RichNode right) {
    assert(self.type()->getStructuralBehavior() == sbValue);
    assert(self.type() == right.type());
    assert(false);
    return false;
  }
};

class StructuralEquatable;
template<>
struct Interface<StructuralEquatable>:
  ImplementedBy<Tuple> {

  /**
   * Precondition:
   *   self.type()->getStructuralBehavior() == sbStructural
   *   self.type() == right.type()
   */
  bool equals(RichNode self, VM vm, RichNode right, WalkStack& stack) {
    assert(self.type()->getStructuralBehavior() == sbStructural);
    assert(self.type() == right.type());
    assert(false);
    return false;
  }
};

class BuiltinCallable;
template<>
struct Interface<BuiltinCallable>: ImplementedBy<BuiltinProcedure> {
  BuiltinResult callBuiltin(RichNode self, VM vm, int argc,
                            UnstableNode* args[]) {
    return raiseTypeError(vm, u"BuiltinProcedure", self);
  }
};

class Callable;
template<>
struct Interface<Callable>: ImplementedBy<Abstraction> {
  BuiltinResult getCallInfo(RichNode self, VM vm, int* arity, StableNode** body,
                            ProgramCounter* start, int* Xcount,
                            StaticArray<StableNode>* Gs,
                            StaticArray<StableNode>* Ks) {
    *arity = 0;
    *body = nullptr;
    *start = nullptr;
    *Xcount = 0;
    *Gs = nullptr;
    *Ks = nullptr;
    return raiseTypeError(vm, u"Abstraction", self);
  }
};

class CodeAreaProvider;
template<>
struct Interface<CodeAreaProvider>: ImplementedBy<CodeArea> {
  BuiltinResult getCodeAreaInfo(RichNode self, VM vm, ProgramCounter* start,
                                int* Xcount, StaticArray<StableNode>* Ks) {
    *start = nullptr;
    *Xcount = 0;
    *Ks = nullptr;
    return raiseTypeError(vm, u"CodeArea", self);
  }
};

class Numeric;
template<>
struct Interface<Numeric>: ImplementedBy<SmallInt, Float> {
  BuiltinResult add(RichNode self, VM vm, UnstableNode* right,
                    UnstableNode* result) {
    return raiseTypeError(vm, u"Numeric", self);
  }

  BuiltinResult subtract(RichNode self, VM vm, UnstableNode* right,
                         UnstableNode* result) {
    return raiseTypeError(vm, u"Numeric", self);
  }

  BuiltinResult multiply(RichNode self, VM vm, UnstableNode* right,
                         UnstableNode* result) {
    return raiseTypeError(vm, u"Numeric", self);
  }

  BuiltinResult divide(RichNode self, VM vm, UnstableNode* right,
                       UnstableNode* result) {
    return raiseTypeError(vm, u"Numeric", self);
  }

  BuiltinResult div(RichNode self, VM vm, UnstableNode* right,
                    UnstableNode* result) {
    return raiseTypeError(vm, u"Numeric", self);
  }

  BuiltinResult mod(RichNode self, VM vm, UnstableNode* right,
                    UnstableNode* result) {
    return raiseTypeError(vm, u"Numeric", self);
  }
};

class IntegerValue;
template<>
struct Interface<IntegerValue>: ImplementedBy<SmallInt> {
  BuiltinResult intValue(RichNode self, VM vm, nativeint* result) {
    return raiseTypeError(vm, u"Integer", self);
  }

  BuiltinResult equalsInteger(RichNode self, VM vm,
                              nativeint right, bool* result) {
    *result = false;
    return BuiltinResult::proceed();
  }

  BuiltinResult addValue(RichNode self, VM vm,
                         nativeint b, UnstableNode* result) {
    return raiseTypeError(vm, u"Integer", self);
  }
};

class FloatValue;
template<>
struct Interface<FloatValue>: ImplementedBy<Float> {
  BuiltinResult floatValue(RichNode self, VM vm, double* result) {
    return raiseTypeError(vm, u"Float", self);
  }

  BuiltinResult equalsFloat(RichNode self, VM vm,
                            double right, bool* result) {
    *result = false;
    return BuiltinResult::proceed();
  }

  BuiltinResult addValue(RichNode self, VM vm,
                         double b, UnstableNode* result) {
    return raiseTypeError(vm, u"Float", self);
  }
};

class BooleanValue;
template<>
struct Interface<BooleanValue>: ImplementedBy<Boolean> {
  BuiltinResult boolValue(RichNode self, VM vm, bool* result) {
    return raiseTypeError(vm, u"Boolean", self);
  }

  BuiltinResult valueOrNotBool(RichNode self, VM vm, BoolOrNotBool* result) {
    *result = bNotBool;
    return BuiltinResult::proceed();
  }
};

class RecordLike;
template<>
struct Interface<RecordLike>: ImplementedBy<Tuple> {
  BuiltinResult label(RichNode self, VM vm, UnstableNode* result) {
    return raiseTypeError(vm, u"Record", self);
  }

  BuiltinResult width(RichNode self, VM vm, UnstableNode* result) {
    return raiseTypeError(vm, u"Record", self);
  }

  BuiltinResult dot(RichNode self, VM vm, UnstableNode* feature,
                    UnstableNode* result) {
    return raiseTypeError(vm, u"Record", self);
  }

  BuiltinResult dotNumber(RichNode self, VM vm, nativeint feature,
                          UnstableNode* result) {
    return raiseTypeError(vm, u"Record", self);
  }

  BuiltinResult waitOr(RichNode self, VM vm, UnstableNode* result) {
    return raiseTypeError(vm, u"Record", self);
  }
};

class ArrayInitializer;
template<>
struct Interface<ArrayInitializer>:
  ImplementedBy<Tuple, Abstraction, CodeArea> {

  BuiltinResult initElement(RichNode self, VM vm, size_t index,
                            UnstableNode* value) {
    return raiseTypeError(vm, u"Array initializer", self);
  }
};

} // namespace mozart

#ifndef MOZART_GENERATOR

namespace mozart {

#include "DataflowVariable-interf.hh"
#include "ValueEquatable-interf.hh"
#include "StructuralEquatable-interf.hh"
#include "BuiltinCallable-interf.hh"
#include "Callable-interf.hh"
#include "CodeAreaProvider-interf.hh"
#include "Numeric-interf.hh"
#include "IntegerValue-interf.hh"
#include "FloatValue-interf.hh"
#include "BooleanValue-interf.hh"
#include "RecordLike-interf.hh"
#include "ArrayInitializer-interf.hh"

} // namespace mozart

#include "variables.hh"
#include "boolean.hh"
#include "smallint.hh"
#include "float.hh"
#include "codearea.hh"
#include "callables.hh"
#include "atom.hh"
#include "records.hh"
#include "reifiedspace.hh"

#include "exchelpers.hh"

#endif // MOZART_GENERATOR

#endif // __COREINTERFACES_H
