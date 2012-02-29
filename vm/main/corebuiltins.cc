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

#include "corebuiltins.hh"
#include "coreinterfaces.hh"

#include <iostream>

#include "emulate.hh"

namespace builtins {

BuiltinResult equals(VM vm, UnstableNode* args[]) {
  Equatable x = args[0]->node;
  return x.equals(vm, args[1], args[2]);
}

BuiltinResult add(VM vm, UnstableNode* args[]) {
  Numeric x = args[0]->node;
  return x.add(vm, args[1], args[2]);
}

BuiltinResult subtract(VM vm, UnstableNode* args[]) {
  Numeric x = args[0]->node;
  return x.subtract(vm, args[1], args[2]);
}

BuiltinResult divide(VM vm, UnstableNode* args[]) {
  Numeric x = args[0]->node;
  return x.divide(vm, args[1], args[2]);
}

BuiltinResult multiply(VM vm, UnstableNode* args[]) {
  Numeric x = args[0]->node;
  return x.multiply(vm, args[1], args[2]);
}

BuiltinResult modulus(VM vm, UnstableNode* args[]) {
  Numeric x = args[0]->node;
  return x.modulus(vm, args[1], args[2]);
}

BuiltinResult createThread(VM vm, UnstableNode* args[]) {
  int arity;
  StableNode* body;
  ProgramCounter start;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  Callable x = args[0]->node;
  BuiltinResult result = x.getCallInfo(vm, &arity, &body, &start,
                                       &Xcount, &Gs, &Ks);

  if (result != BuiltinResultContinue)
    return result;

  if (arity != 0) {
    cout << "Illegal arity: " << 0 << " expected but ";
    cout << arity << " found" << endl;
    // TODO Raise illegal arity exception
  }

  new (vm) Thread(vm, Reference::getStableRefFor(vm, *args[0]));

  return BuiltinResultContinue;
}

}
