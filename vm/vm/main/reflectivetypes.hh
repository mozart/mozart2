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

#ifndef __REFLECTIVETYPES_H
#define __REFLECTIVETYPES_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

//////////////////////
// ReflectiveEntity //
//////////////////////

#include "ReflectiveEntity-implem.hh"

ReflectiveEntity::ReflectiveEntity(VM vm, UnstableNode& stream) {
  _stream = ReadOnlyVariable::build(vm);
  stream.copy(vm, _stream);
}

ReflectiveEntity::ReflectiveEntity(VM vm, GR gr, ReflectiveEntity& from) {
  gr->copyUnstableNode(_stream, from._stream);
}

template <typename Label, typename... Args>
bool ReflectiveEntity::reflectiveCall(
  VM vm, const char* identity, Label&& label, Args&&... args) {

  if (!vm->isOnTopLevel())
    raise(vm, "globalState", "reflective");

  return ozcalls::internal::doReflectiveCall(
    vm, identity, _stream,
    std::forward<Label>(label), std::forward<Args>(args)...);
}

////////////////////////
// ReflectiveVariable //
////////////////////////

#include "ReflectiveVariable-implem.hh"

ReflectiveVariable::ReflectiveVariable(VM vm, UnstableNode& stream):
  VariableBase(vm) {

  _stream = ReadOnlyVariable::build(vm);
  stream.copy(vm, _stream);
}

ReflectiveVariable::ReflectiveVariable(VM vm, Space* home,
                                       UnstableNode& stream):
  VariableBase(vm, home) {

  _stream = ReadOnlyVariable::build(vm);
  stream.copy(vm, _stream);
}

ReflectiveVariable::ReflectiveVariable(VM vm, GR gr, ReflectiveVariable& from):
  VariableBase(vm, gr, from) {

  gr->copyUnstableNode(_stream, from._stream);
}

void ReflectiveVariable::markNeeded(VM vm) {
  if (!isNeeded(vm)) {
    VariableBase::markNeeded(vm);
    sendToReadOnlyStream(vm, _stream, buildSharp(vm, "markNeeded",
                                                 OptVar::build(vm)));
  }
}

void ReflectiveVariable::bind(VM vm, RichNode src) {
  ozcalls::internal::doReflectiveCall(
    vm, "mozart::ReflectiveVariable::bind", _stream,
    "bind", src
  );
}

void ReflectiveVariable::reflectiveBind(RichNode self, VM vm, RichNode src) {
  doBind(self, vm, src);
}

void ReflectiveVariable::bindReadOnly(VM vm, RichNode src) {
  ozcalls::internal::doReflectiveCall(
    vm, "mozart::ReflectiveVariable::bindReadOnly", _stream,
    "bindReadOnly", src
  );
}

}

#endif // MOZART_GENERATOR

#endif // __REFLECTIVETYPES_H
