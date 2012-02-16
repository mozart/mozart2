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

#ifndef __CODEAREA_DECL_H
#define __CODEAREA_DECL_H

#include "store.hh"
#include "opcodes.hh"
#include "arrays.hh"

#include <cstring>

//////////////
// CodeArea //
//////////////

class CodeArea;

#ifndef MOZART_GENERATOR
#include "CodeArea-implem-decl.hh"
#endif

template <>
class Implementation<CodeArea>: StoredWithArrayOf<StableNode> {
public:
  typedef SelfType<CodeArea>::Self Self;
public:
  Implementation(VM vm, size_t Kc, StaticArray<StableNode> _Ks,
                 ByteCode* codeBlock, int size, int Xcount)
    : _size(size), _Xcount(Xcount), _Kc(Kc) {

    _setCodeBlock(vm, codeBlock, size);
  }

  size_t getArraySize() {
    return _Kc;
  }

  inline
  BuiltinResult initElement(Self self, VM vm, size_t index,
                            UnstableNode* value);

  inline
  BuiltinResult getCodeAreaInfo(Self self, VM vm,
                                ProgramCounter* start, int* Xcount,
                                StaticArray<StableNode>* Ks);
private:
  void _setCodeBlock(VM vm, ByteCode* codeBlock, size_t size) {
    _codeBlock = new (vm) ByteCode[size / sizeof(ByteCode)];
    std::memcpy(_codeBlock, codeBlock, size);
  }

  ByteCode* _codeBlock; // actual byte-code in this code area
  int _size;            // size of the codeBlock

  int _Xcount; // number of X registers used in this area
  size_t _Kc;  // number of K registers
};

#endif // __CODEAREA_DECL_H
