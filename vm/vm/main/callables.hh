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

#ifndef __CALLABLES_H
#define __CALLABLES_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

//////////////////////
// BuiltinProcedure //
//////////////////////

#include "BuiltinProcedure-implem.hh"

void BuiltinProcedure::create(Builtin*& self, VM vm, GR gr, Self from) {
  self = from.get()._builtin;
}

bool BuiltinProcedure::equals(VM vm, Self right) {
  return _builtin == right.get()._builtin;
}

void BuiltinProcedure::callBuiltin(VM vm, size_t argc, UnstableNode* args[]) {
  assert(argc == getArity());
  return _builtin->call(vm, args);
}

template <class... Args>
void BuiltinProcedure::callBuiltin(VM vm, Args&&... args) {
  assert(sizeof...(args) == getArity());
  return _builtin->call(vm, std::forward<Args>(args)...);
}

size_t BuiltinProcedure::procedureArity(VM vm) {
  return getArity();
}

void BuiltinProcedure::getCallInfo(
  RichNode self, VM vm, size_t& arity, ProgramCounter& start,
  size_t& Xcount, StaticArray<StableNode>& Gs, StaticArray<StableNode>& Ks) {

  return _builtin->getCallInfo(self, vm, arity, start, Xcount, Gs, Ks);
}

void BuiltinProcedure::getDebugInfo(
  RichNode self, VM vm, atom_t& printName, UnstableNode& debugData) {

  printName = _builtin->getNameAtom(vm);
  debugData = mozart::build(vm, unit);
}

/////////////////
// Abstraction //
/////////////////

#include "Abstraction-implem.hh"

Abstraction::Abstraction(VM vm, size_t Gc, RichNode body)
  : WithHome(vm), _Gc(Gc) {
  _body.init(vm, body);
  _codeAreaCacheValid = false;

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < Gc; i++)
    getElements(i).init(vm);
}

Abstraction::Abstraction(VM vm, size_t Gc, GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  gr->copyStableNode(_body, from->_body);
  _Gc = Gc;

  _codeAreaCacheValid = false;

  gr->copyStableNodes(getElementsArray(), from->getElementsArray(), Gc);
}

size_t Abstraction::procedureArity(VM vm) {
  ensureCodeAreaCacheValid(vm);
  return _arity;
}

void Abstraction::getCallInfo(
  VM vm, size_t& arity, ProgramCounter& start,
  size_t& Xcount, StaticArray<StableNode>& Gs, StaticArray<StableNode>& Ks) {

  ensureCodeAreaCacheValid(vm);

  arity = _arity;
  start = _start;
  Xcount = _Xcount;
  Gs = getElementsArray();
  Ks = _Ks;
}

void Abstraction::getDebugInfo(VM vm, atom_t& printName,
                               UnstableNode& debugData) {
  return CodeAreaProvider(_body).getCodeAreaDebugInfo(vm, printName, debugData);
}

void Abstraction::printReprToStream(VM vm, std::ostream& out, int depth) {
  MOZART_TRY(vm) {
    ensureCodeAreaCacheValid(vm);

    atom_t printName;
    UnstableNode debugData;
    CodeAreaProvider(_body).getCodeAreaDebugInfo(vm, printName, debugData);

    out << "<P/" << _arity;
    if (printName != vm->coreatoms.empty)
      out << " " << printName;
    out << ">";
  } MOZART_CATCH(vm, kind, node) {
    out << "<P/?>";
  } MOZART_ENDTRY(vm);
}

void Abstraction::ensureCodeAreaCacheValid(VM vm) {
  if (!_codeAreaCacheValid)
    fillCodeAreaCache(vm);
}

void Abstraction::fillCodeAreaCache(VM vm) {
  CodeAreaProvider(_body).getCodeAreaInfo(vm, _arity, _start, _Xcount, _Ks);
  _codeAreaCacheValid = true;
}

}

#endif // MOZART_GENERATOR

#endif // __CALLABLES_H
