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

#ifndef __CODEAREA_H
#define __CODEAREA_H

#include "codearea-decl.hh"

/////////////////////
// Inline CodeArea //
/////////////////////

#ifndef MOZART_GENERATOR
#include "CodeArea-implem.hh"
#endif

Implementation<CodeArea>::Implementation(VM vm, size_t Kc,
                                         StaticArray<StableNode> _Ks,
                                         GC gc, SelfReadOnlyView from) {
  _size = from->_size;
  _Xcount = from->_Xcount;
  _Kc = Kc;

  _setCodeBlock(vm, from->_codeBlock, _size);

  for (size_t i = 0; i < Kc; i++)
    gc->gcStableNode(from[i], _Ks[i]);
}

BuiltinResult Implementation<CodeArea>::initElement(Self self, VM vm,
                                                    size_t index,
                                                    UnstableNode* value) {
  self[index].init(vm, *value);
  return BuiltinResult::proceed();
}

BuiltinResult
Implementation<CodeArea>::getCodeAreaInfo(Self self, VM vm,
                                          ProgramCounter* start,
                                          int* Xcount,
                                          StaticArray<StableNode>* Ks) {
  *start = _codeBlock;
  *Xcount = _Xcount;
  *Ks = self.getArray();

  return BuiltinResult::proceed();
}

#endif // __CODEAREA_H
