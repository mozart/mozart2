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

builtins::BaseBuiltin* Implementation<BuiltinProcedure>::build(
  VM vm, GR gr, Self from) {
  return from.get()._builtin;
}

OpResult Implementation<BuiltinProcedure>::callBuiltin(
  Self self, VM vm, int argc, UnstableNode* args[]) {

  if (argc == getArity())
    return _builtin->call(vm, args);
  else
    return raiseIllegalArity(vm, getArity(), argc);
}

template <class... Args>
OpResult Implementation<BuiltinProcedure>::callBuiltin(
  Self self, VM vm, Args&&... args) {

  if (sizeof...(args) == getArity())
    return _builtin->call(vm, std::forward<Args>(args)...);
  else
    return raiseIllegalArity(vm, getArity(), sizeof...(args));
}

OpResult Implementation<BuiltinProcedure>::arity(Self self, VM vm,
                                                 UnstableNode& result) {
  result.make<SmallInt>(vm, getArity());
  return OpResult::proceed();
}

/////////////////
// Abstraction //
/////////////////

#include "Abstraction-implem.hh"

Implementation<Abstraction>::Implementation(VM vm, size_t Gc,
                                            StaticArray<StableNode> _Gs,
                                            GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  _arity = from->_arity;
  gr->copyStableNode(_body, from->_body);
  _Gc = Gc;

  _codeAreaCacheValid = false;

  for (size_t i = 0; i < Gc; i++)
    gr->copyStableNode(_Gs[i], from[i]);
}

OpResult Implementation<Abstraction>::arity(Self self, VM vm,
                                            UnstableNode& result) {
  result.make<SmallInt>(vm, _arity);
  return OpResult::proceed();
}

OpResult Implementation<Abstraction>::initElement(Self self, VM vm,
                                                  size_t index,
                                                  RichNode value) {
  self[index].init(vm, value);
  return OpResult::proceed();
}

OpResult Implementation<Abstraction>::getCallInfo(
  Self self, VM vm, int& arity, StableNode*& body, ProgramCounter& start,
  int& Xcount, StaticArray<StableNode>& Gs, StaticArray<StableNode>& Ks) {

  if (!_codeAreaCacheValid) {
    UnstableNode temp(vm, _body);
    MOZART_CHECK_OPRESULT(
      CodeAreaProvider(temp).getCodeAreaInfo(vm, _start, _Xcount, _Ks));

    _codeAreaCacheValid = true;
  }

  arity = _arity;
  body = &_body;
  start = _start;
  Xcount = _Xcount;
  Gs = self.getArray();
  Ks = _Ks;

  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __CALLABLES_H
