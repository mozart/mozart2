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

void Implementation<BuiltinProcedure>::build(Builtin*& self, VM vm, GR gr,
                                             Self from) {
  self = from.get()._builtin;
}

bool Implementation<BuiltinProcedure>::equals(VM vm, Self right) {
  return _builtin == right.get()._builtin;
}

OpResult Implementation<BuiltinProcedure>::callBuiltin(
  Self self, VM vm, size_t argc, UnstableNode* args[]) {

  assert(argc == getArity());
  return _builtin->call(vm, args);
}

template <class... Args>
OpResult Implementation<BuiltinProcedure>::callBuiltin(
  Self self, VM vm, Args&&... args) {

  assert(sizeof...(args) == getArity());
  return _builtin->call(vm, std::forward<Args>(args)...);
}

OpResult Implementation<BuiltinProcedure>::procedureArity(Self self, VM vm,
                                                          size_t& result) {
  result = getArity();
  return OpResult::proceed();
}

OpResult Implementation<BuiltinProcedure>::getCallInfo(
  Self self, VM vm, size_t& arity, ProgramCounter& start,
  size_t& Xcount, StaticArray<StableNode>& Gs, StaticArray<StableNode>& Ks) {

  return _builtin->getCallInfo(self, vm, arity, start, Xcount, Gs, Ks);
}

OpResult Implementation<BuiltinProcedure>::getDebugInfo(
  Self self, VM vm, atom_t& printName, UnstableNode& debugData) {

  printName = _builtin->getNameAtom(vm);
  debugData = mozart::build(vm, unit);

  return OpResult::proceed();
}

/////////////////
// Abstraction //
/////////////////

#include "Abstraction-implem.hh"

Implementation<Abstraction>::Implementation(VM vm, size_t Gc,
                                            StaticArray<StableNode> _Gs,
                                            RichNode body)
  : WithHome(vm), _Gc(Gc) {
  _body.init(vm, body);
  _codeAreaCacheValid = false;

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < Gc; i++)
    _Gs[i].init(vm);
}

Implementation<Abstraction>::Implementation(VM vm, size_t Gc,
                                            StaticArray<StableNode> _Gs,
                                            GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  gr->copyStableNode(_body, from->_body);
  _Gc = Gc;

  _codeAreaCacheValid = false;

  for (size_t i = 0; i < Gc; i++)
    gr->copyStableNode(_Gs[i], from[i]);
}

StaticArray<StableNode> Implementation<Abstraction>::getElementsArray(Self self) {
  return self.getArray();
}

OpResult Implementation<Abstraction>::initElement(Self self, VM vm,
                                                  size_t index,
                                                  RichNode value) {
  self[index].init(vm, value);
  return OpResult::proceed();
}

OpResult Implementation<Abstraction>::procedureArity(Self self, VM vm,
                                                     size_t& result) {
  MOZART_CHECK_OPRESULT(ensureCodeAreaCacheValid(vm));

  result = _arity;
  return OpResult::proceed();
}

OpResult Implementation<Abstraction>::getCallInfo(
  Self self, VM vm, size_t& arity, ProgramCounter& start,
  size_t& Xcount, StaticArray<StableNode>& Gs, StaticArray<StableNode>& Ks) {

  MOZART_CHECK_OPRESULT(ensureCodeAreaCacheValid(vm));

  arity = _arity;
  start = _start;
  Xcount = _Xcount;
  Gs = self.getArray();
  Ks = _Ks;

  return OpResult::proceed();
}

OpResult Implementation<Abstraction>::getDebugInfo(
  Self self, VM vm, atom_t& printName, UnstableNode& debugData) {

  return CodeAreaProvider(_body).getCodeAreaDebugInfo(vm, printName, debugData);
}

void Implementation<Abstraction>::printReprToStream(
  Self self, VM vm, std::ostream& out, int depth) {

  ensureCodeAreaCacheValid(vm);

  if (!_codeAreaCacheValid) {
    out << "<P/?>";
  } else {
    atom_t printName;
    UnstableNode debugData;
    MOZART_ASSERT_PROCEED(
      CodeAreaProvider(_body).getCodeAreaDebugInfo(vm, printName, debugData));

    out << "<P/" << _arity;
    if (printName != vm->coreatoms.empty)
      out << " " << printName;
    out << ">";
  }
}

OpResult Implementation<Abstraction>::ensureCodeAreaCacheValid(VM vm) {
  if (_codeAreaCacheValid)
    return OpResult::proceed();
  else
    return fillCodeAreaCache(vm);
}

OpResult Implementation<Abstraction>::fillCodeAreaCache(VM vm) {
  MOZART_CHECK_OPRESULT(
    CodeAreaProvider(_body).getCodeAreaInfo(vm, _arity, _start, _Xcount, _Ks));

  _codeAreaCacheValid = true;
  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __CALLABLES_H
