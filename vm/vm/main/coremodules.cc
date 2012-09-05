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

#include "mozart.hh"
#include "coremodules.hh"

namespace mozart {

namespace builtins {

#include "mozartbuiltins.cc"

} // namespace builtins

void registerCoreModules(VM vm) {
  using namespace mozart::builtins::biref;

  registerBuiltinModArray(vm);
  registerBuiltinModAtom(vm);
  registerBuiltinModBoot(vm);
  registerBuiltinModCell(vm);
  registerBuiltinModChunk(vm);
  registerBuiltinModCoders(vm);
  registerBuiltinModCompactString(vm);
  registerBuiltinModCompilerSupport(vm);
  registerBuiltinModDebug(vm);
  registerBuiltinModDictionary(vm);
  registerBuiltinModException(vm);
  registerBuiltinModInt(vm);
  registerBuiltinModFloat(vm);
  registerBuiltinModForeignPointer(vm);
  registerBuiltinModGNode(vm);
  registerBuiltinModLiteral(vm);
  registerBuiltinModName(vm);
  registerBuiltinModNumber(vm);
  registerBuiltinModObject(vm);
  registerBuiltinModPort(vm);
  registerBuiltinModProcedure(vm);
  registerBuiltinModProperty(vm);
  registerBuiltinModRecord(vm);
  registerBuiltinModReflection(vm);
  registerBuiltinModSerializer(vm);
  registerBuiltinModSpace(vm);
  registerBuiltinModSystem(vm);
  registerBuiltinModThread(vm);
  registerBuiltinModTime(vm);
  registerBuiltinModTuple(vm);
  registerBuiltinModValue(vm);
  registerBuiltinModVirtualByteString(vm);
  registerBuiltinModVirtualString(vm);
}

} // namespace mozart
