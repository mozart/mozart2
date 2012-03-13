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

#include "callables-decl.hh"

#include "coreinterfaces.hh"
#include "smallint.hh"

#include <iostream>

/////////////////////////////
// Inline BuiltinProcedure //
/////////////////////////////

#ifndef MOZART_GENERATOR
#include "BuiltinProcedure-implem.hh"
#endif

BuiltinResult Implementation<BuiltinProcedure>::arity(Self self, VM vm,
                                                      UnstableNode* result) {
  result->make<SmallInt>(vm, _arity);
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<BuiltinProcedure>::raiseIllegalArity(
  Self self, VM vm, int argc) {

  UnstableNode exception;
  exception.make<Atom>(vm, u"illegalArity");

  return BuiltinResult::raise(vm, exception);
}

////////////////////////
// Inline Abstraction //
////////////////////////

#ifndef MOZART_GENERATOR
#include "Abstraction-implem.hh"
#endif

Implementation<Abstraction>::Implementation(VM vm, size_t Gc,
                                            StaticArray<StableNode> _Gs,
                                            GC gc, Self from) {
  _arity = from->_arity;
  gc->gcStableNode(from->_body, _body);
  _Gc = Gc;

  _codeAreaCacheValid = false;

  for (size_t i = 0; i < Gc; i++)
    gc->gcStableNode(from[i], _Gs[i]);
}

BuiltinResult Implementation<Abstraction>::arity(Self self, VM vm,
                                                 UnstableNode* result) {
  result->make<SmallInt>(vm, _arity);
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Abstraction>::initElement(Self self, VM vm,
                                                       size_t index,
                                                       UnstableNode* value) {
  self[index].init(vm, *value);
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Abstraction>::getCallInfo(
  Self self, VM vm, int* arity, StableNode** body, ProgramCounter* start,
  int* Xcount, StaticArray<StableNode>* Gs, StaticArray<StableNode>* Ks) {

  if (!_codeAreaCacheValid) {
    UnstableNode temp(vm, _body);
    CodeAreaProvider provider = temp;
    BuiltinResult result = provider.getCodeAreaInfo(
      vm, &_start, &_Xcount, &_Ks);

    if (!result.isProceed())
      return result;

    _codeAreaCacheValid = true;
  }

  *arity = _arity;
  *body = &_body;
  *start = _start;
  *Xcount = _Xcount;
  *Gs = self.getArray();
  *Ks = _Ks;

  return BuiltinResult::proceed();
}

#endif // __CALLABLES_H
