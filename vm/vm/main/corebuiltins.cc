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
#include "unify.hh"

namespace mozart {

namespace builtins {

/////////////////////////
// Unification-related //
/////////////////////////

BuiltinResult equals(VM vm, UnstableNode* args[]) {
  RichNode left = *args[0];
  RichNode right = *args[1];
  bool result = false;

  BuiltinResult res = mozart::equals(vm, left, right, &result);
  if (res.isProceed())
    args[2]->make<Boolean>(vm, result);
  return res;
}

BuiltinResult notEquals(VM vm, UnstableNode* args[]) {
  RichNode left = *args[0];
  RichNode right = *args[1];
  bool result = false;

  BuiltinResult res = mozart::notEquals(vm, left, right, &result);
  if (res.isProceed())
    args[2]->make<Boolean>(vm, result);
  return res;
}

//////////////////
// Value status //
//////////////////

BuiltinResult wait(VM vm, UnstableNode* args[]) {
  RichNode value = *args[0];

  if (value.type()->isTransient())
    return BuiltinResult::waitFor(vm, value);
  else
    return BuiltinResult::proceed();
}

BuiltinResult waitOr(VM vm, UnstableNode* args[]) {
  return RecordLike(*args[0]).waitOr(vm, args[1]);
}

BuiltinResult isDet(VM vm, UnstableNode* args[]) {
  RichNode value = *args[0];
  args[1]->make<Boolean>(vm, !value.type()->isTransient());
  return BuiltinResult::proceed();
}

////////////////
// Arithmetic //
////////////////

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

/////////////
// Records //
/////////////

BuiltinResult label(VM vm, UnstableNode* args[]) {
  return RecordLike(*args[0]).label(vm, args[1]);
}

BuiltinResult width(VM vm, UnstableNode* args[]) {
  RecordLike x = *args[0];
  return x.width(vm, args[1]);
}

BuiltinResult dot(VM vm, UnstableNode* args[]) {
  RecordLike x = *args[0];
  return x.dot(vm, args[1], args[2]);
}

/////////////
// Threads //
/////////////

BuiltinResult createThread(VM vm, UnstableNode* args[]) {
  RichNode target = *args[0];

  BuiltinResult result = expectCallable(vm, target, 0);
  if (!result.isProceed())
    return result;

  new (vm) Thread(vm, vm->getCurrentSpace(), target.getStableRef(vm));

  return BuiltinResult::proceed();
}

///////////////////
// Miscellaneous //
///////////////////

BuiltinResult show(VM vm, UnstableNode* args[]) {
  RichNode arg = *args[0];
  printReprToStream(vm, arg, std::cout);
  std::cout << std::endl;
  return BuiltinResult::proceed();
}

////////////
// Spaces //
////////////

BuiltinResult newSpace(VM vm, UnstableNode* args[]) {
  RichNode target = *args[0];

  BuiltinResult result = expectCallable(vm, target, 1);
  if (!result.isProceed())
    return result;

  // Create the space
  Space* space = new (vm) Space(vm->getCurrentSpace());
  space->getRootVar()->make<Unbound>(vm);

  // Create the thread {Proc Root}
  UnstableNode rootVar(vm, *space->getRootVar());
  UnstableNode* threadArgs[] = { &rootVar };

  new (vm) Thread(vm, space, target.getStableRef(vm), 1, threadArgs);

  // Create the reification of the space
  args[1]->make<ReifiedSpace>(vm, space);

  return BuiltinResult::preempt();
}

BuiltinResult askSpace(VM vm, UnstableNode* args[]) {
  return BuiltinResult::proceed();
}

BuiltinResult mergeSpace(VM vm, UnstableNode* args[]) {
  return BuiltinResult::proceed();
}

///////////
// Utils //
///////////

BuiltinResult expectCallable(VM vm, RichNode target, int expectedArity) {
  int arity = 0;
  StableNode* body;
  ProgramCounter start;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  BuiltinResult result = Callable(target).getCallInfo(
    vm, &arity, &body, &start, &Xcount, &Gs, &Ks);

  if (!result.isProceed())
    return result;

  if (arity != expectedArity)
    return raiseIllegalArity(vm, expectedArity, arity);

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

}
