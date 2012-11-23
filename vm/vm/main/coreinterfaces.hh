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

#include "mozartcore-decl.hh"

#include "coreinterfaces-decl.hh"
#include "coredatatypes-decl.hh"
#include "ozcalls-decl.hh"

namespace mozart {

#ifndef MOZART_GENERATOR

/////////////////////
// Generated stuff //
/////////////////////

#include "DataflowVariable-interf.hh"
#include "BindableReadOnly-interf.hh"
#include "ValueEquatable-interf.hh"
#include "StructuralEquatable-interf.hh"
#include "Comparable-interf.hh"
#include "Wakeable-interf.hh"
#include "Literal-interf.hh"
#include "AtomLike-interf.hh"
#include "NameLike-interf.hh"
#include "PotentialFeature-interf.hh"
#include "BuiltinCallable-interf.hh"
#include "Callable-interf.hh"
#include "CodeAreaProvider-interf.hh"
#include "Numeric-interf.hh"
#include "BaseDottable-interf.hh"
#include "DotAssignable-interf.hh"
#include "RecordLike-interf.hh"
#include "PortLike-interf.hh"
#include "ArrayLike-interf.hh"
#include "DictionaryLike-interf.hh"
#include "ObjectLike-interf.hh"
#include "SpaceLike-interf.hh"
#include "ThreadLike-interf.hh"
#include "CellLike-interf.hh"
#include "ChunkLike-interf.hh"
#include "StringLike-interf.hh"
#include "VirtualString-interf.hh"

//////////////
// Callable //
//////////////

bool Interface<Callable>::isCallable(RichNode self, VM vm) {
  if (self.is<ReflectiveEntity>()) {
    bool result;
    if (self.as<ReflectiveEntity>().reflectiveCall(
          vm, MOZART_STR("$intf$::Callable::isCallable"),
          MOZART_STR("isCallable"), ozcalls::out(result)))
      return result;
  }

  return false;
}

bool Interface<Callable>::isProcedure(RichNode self, VM vm) {
  if (self.is<ReflectiveEntity>()) {
    bool result;
    if (self.as<ReflectiveEntity>().reflectiveCall(
          vm, MOZART_STR("$intf$::Callable::isProcedure"),
          MOZART_STR("isProcedure"), ozcalls::out(result)))
      return result;
  }

  return false;
}

size_t Interface<Callable>::procedureArity(RichNode self, VM vm) {
  if (self.is<ReflectiveEntity>()) {
    size_t result;
    if (self.as<ReflectiveEntity>().reflectiveCall(
          vm, MOZART_STR("$intf$::Callable::procedureArity"),
          MOZART_STR("procedureArity"), ozcalls::out(result)))
      return result;
  }

  raiseTypeError(vm, MOZART_STR("Procedure"), self);
}

void Interface<Callable>::getCallInfo(
  RichNode self, VM vm, size_t& arity, ProgramCounter& start, size_t& Xcount,
  StaticArray<StableNode>& Gs, StaticArray<StableNode>& Ks) {

  raiseTypeError(vm, MOZART_STR("Callable"), self);
}

void Interface<Callable>::getDebugInfo(RichNode self, VM vm,
                                       atom_t& printName,
                                       UnstableNode& debugData) {
  raiseTypeError(vm, MOZART_STR("Callable"), self);
}

//////////////
// Dottable //
//////////////

struct Dottable: public BaseDottable {
  // Not supported by compilers yet
  // using BaseDottable::BaseDottable;

  Dottable(RichNode self): BaseDottable(self) {}
  Dottable(UnstableNode& self): BaseDottable(self) {}
  Dottable(StableNode& self): BaseDottable(self) {}

  UnstableNode dot(VM vm, RichNode feature) {
    UnstableNode result;
    if (lookupFeature(vm, feature, result))
      return result;
    else
      raise(vm, vm->coreatoms.illegalFieldSelection, _self, feature);
  }

  UnstableNode dot(VM vm, nativeint feature) {
    UnstableNode result;
    if (lookupFeature(vm, feature, result))
      return result;
    else
      raise(vm, vm->coreatoms.illegalFieldSelection, _self, feature);
  }

  bool hasFeature(VM vm, RichNode feature) {
    return lookupFeature(vm, feature, nullptr);
  }

  bool hasFeature(VM vm, nativeint feature) {
    return lookupFeature(vm, feature, nullptr);
  }

  UnstableNode condSelect(VM vm, RichNode feature, RichNode defaultResult) {
    UnstableNode result;
    if (lookupFeature(vm, feature, result))
      return result;
    else
      return { vm, defaultResult };
  }

  UnstableNode condSelect(VM vm, nativeint feature, RichNode defaultResult) {
    UnstableNode result;
    if (lookupFeature(vm, feature, result))
      return result;
    else
      return { vm, defaultResult };
  }
};

#endif // MOZART_GENERATOR

}

#endif // __COREINTERFACES_H
