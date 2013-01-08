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

#ifndef __BUILTINS_H
#define __BUILTINS_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

/////////////////
// BaseBuiltin //
/////////////////

atom_t BaseBuiltin::getModuleNameAtom(VM vm) {
  auto utf8Name = makeLString(_moduleName.c_str(), _moduleName.length());
  auto nativeName = toUTF<nchar>(utf8Name);
  return vm->getAtom(nativeName.length, nativeName.string);
}

atom_t BaseBuiltin::getNameAtom(VM vm) {
  auto utf8Name = makeLString(_name.c_str(), _name.length());
  auto nativeName = toUTF<nchar>(utf8Name);
  return vm->getAtom(nativeName.length, nativeName.string);
}

void BaseBuiltin::getCallInfo(
  RichNode self, VM vm, size_t& arity, ProgramCounter& start, size_t& Xcount,
  StaticArray<StableNode>& Gs, StaticArray<StableNode>& Ks) {

  if (_codeBlock == nullptr)
    buildCodeBlock(vm, self);

  arity = _arity;
  start = _codeBlock;
  Xcount = 2*_arity;
  Gs = nullptr;
  Ks = StaticArray<StableNode>(&*_selfValue, 1);
}

void BaseBuiltin::buildCodeBlock(VM vm, RichNode self) {
  const size_t arity = _arity;

  // Compute size of the code block
  size_t count = 0;
  count += 1 /* opcode */ + 1 /* K(0) */ + (arity > 5 ? 1 : 0) /* arity */;
  count += arity /* actual arguments */;

  for (size_t i = 0; i < arity; i++)
    if (_params[i].kind == ParamInfo::pkOut)
      count += 1 /* opcode */ + 2 /* args */;

  count += 1 /* OpReturn */;

  // Allocate the code block
  _codeBlock = new ByteCode[count];
  size_t index = 0;

  // OpCallBuiltin

  switch (arity) {
    case 0: _codeBlock[index++] = OpCallBuiltin0; break;
    case 1: _codeBlock[index++] = OpCallBuiltin1; break;
    case 2: _codeBlock[index++] = OpCallBuiltin2; break;
    case 3: _codeBlock[index++] = OpCallBuiltin3; break;
    case 4: _codeBlock[index++] = OpCallBuiltin4; break;
    case 5: _codeBlock[index++] = OpCallBuiltin5; break;
    default: _codeBlock[index++] = OpCallBuiltinN; break;
  }

  _codeBlock[index++] = 0; // K(0)

  if (arity > 5)
    _codeBlock[index++] = arity;

  for (size_t i = 0; i < arity; i++) {
    if (_params[i].kind == ParamInfo::pkIn) {
      _codeBlock[index++] = i;
    } else {
      _codeBlock[index++] = i + arity;
    }
  }

  // Unify with outputs

  for (size_t i = 0; i < arity; i++) {
    if (_params[i].kind == ParamInfo::pkOut) {
      _codeBlock[index++] = OpUnifyXX;
      _codeBlock[index++] = i;
      _codeBlock[index++] = i + arity;
    }
  }

  // Return
  _codeBlock[index++] = OpReturn;

  // Finalize
  assert(index == count);

  // Set _selfValue
  _selfValue = vm->protect(self);
}

}

}

#endif // MOZART_GENERATOR

#endif // __BUILTINS_H
