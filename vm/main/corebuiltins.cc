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
#include "exchelpers.hh"

namespace builtins {

BuiltinResult equals(VM vm, UnstableNode* args[]) {
  Equatable x = *args[0];
  return x.equals(vm, args[1], args[2]);
}

BuiltinResult notEquals(VM vm, UnstableNode* args[]) {
  Equatable x = *args[0];
  BuiltinResult result = x.equals(vm, args[1], args[2]);

  if (result.isProceed()) {
    RichNode richResult = *args[2];
    assert(richResult.type() == Boolean::type());
    bool equalsResult = richResult.as<Boolean>().value();
    args[2]->make<Boolean>(vm, !equalsResult);
  }

  return result;
}

BuiltinResult add(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.add(vm, args[1], args[2]);
}

BuiltinResult subtract(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.subtract(vm, args[1], args[2]);
}

BuiltinResult multiply(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.multiply(vm, args[1], args[2]);
}

BuiltinResult divide(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.divide(vm, args[1], args[2]);
}

BuiltinResult div(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.div(vm, args[1], args[2]);
}

BuiltinResult mod(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.mod(vm, args[1], args[2]);
}

BuiltinResult width(VM vm, UnstableNode* args[]) {
  RecordLike x = *args[0];
  return x.width(vm, args[1]);
}

BuiltinResult dot(VM vm, UnstableNode* args[]) {
  RecordLike x = *args[0];
  return x.dot(vm, args[1], args[2]);
}

BuiltinResult createThread(VM vm, UnstableNode* args[]) {
  int arity;
  StableNode* body;
  ProgramCounter start;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  Callable x = *args[0];
  BuiltinResult result = x.getCallInfo(vm, &arity, &body, &start,
                                       &Xcount, &Gs, &Ks);

  if (!result.isProceed())
    return result;

  if (arity != 0)
    return raiseAtom(vm, u"illegalArity");

  new (vm) Thread(vm, Reference::getStableRefFor(vm, *args[0]));

  return BuiltinResult::proceed();
}

BuiltinResult show(VM vm, UnstableNode* args[]) {
  RichNode arg = *args[0];
  printReprToStream(vm, arg, std::cout);
  std::cout << std::endl;
  return BuiltinResult::proceed();
}

void printReprToStream(VM vm, RichNode arg,
                       std::ostream& out, int depth) {
  if (depth <= 0) {
    out << "...";
    return;
  }

  if (arg.type() == SmallInt::type()) {
    out << arg.as<SmallInt>().value();
  } else if (arg.type() == Boolean::type()) {
    out << (arg.as<Boolean>().value() ? "true" : "false");
  } else if (arg.type() == Float::type()) {
    out << arg.as<Float>().value();
  } else if (arg.type() == Atom::type()) {
    arg.as<Atom>().printReprToStream(vm, &out, depth);
  } else if (arg.type() == Tuple::type()) {
    arg.as<Tuple>().printReprToStream(vm, &out, depth);
  } else if (arg.type()->isTransient()) {
    out << "_";
  } else {
    out << "<" << arg.type()->getName() << ">";
  }
}

}
