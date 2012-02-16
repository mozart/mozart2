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

#include <iostream>

#include "coreinterfaces.hh"
#include "smallint-decl.hh"

/////////////////////////////
// Inline BuiltinProcedure //
/////////////////////////////

#ifndef MOZART_GENERATOR
#include "BuiltinProcedure-implem.hh"
#endif

BuiltinResult Implementation<BuiltinProcedure>::arity(Self self, VM vm,
                                                      UnstableNode* result) {
  result->make<SmallInt>(vm, _arity);
  return BuiltinResultContinue;
}

BuiltinResult Implementation<BuiltinProcedure>::raiseIllegalArity(int argc) {
  // TODO raiseIllegalArity
  return BuiltinResultContinue;
}

////////////////////////
// Inline Abstraction //
////////////////////////

#ifndef MOZART_GENERATOR
#include "Abstraction-implem.hh"
#endif

BuiltinResult Implementation<Abstraction>::arity(Self self, VM vm,
                                                 UnstableNode* result) {
  result->make<SmallInt>(vm, _arity);
  return BuiltinResultContinue;
}

/////////////////////
// Inline CodeArea //
/////////////////////

BuiltinResult Implementation<Abstraction>::initElement(Self self, VM vm,
                                                       size_t index,
                                                       UnstableNode* value) {
  self[index].init(vm, *value);
  return BuiltinResultContinue;
}

BuiltinResult Implementation<Abstraction>::getCallInfo(
  Self self, VM vm, int* arity, StableNode** body, ProgramCounter* start,
  int* Xcount, StaticArray<StableNode>* Gs, StaticArray<StableNode>* Ks) {

  if (!_codeAreaCacheValid) {
    CodeAreaProvider provider = _body.node;
    BuiltinResult result = provider.getCodeAreaInfo(
      vm, &_start, &_Xcount, &_Ks);

    if (result != BuiltinResultContinue)
      return result;

    _codeAreaCacheValid = true;
  }

  *arity = _arity;
  *body = &_body;
  *start = _start;
  *Xcount = _Xcount;
  *Gs = self.getArray(_Gc);
  *Ks = _Ks;

  return BuiltinResultContinue;
}

#endif // __CALLABLES_H
