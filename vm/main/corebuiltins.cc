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

#include <iostream>

namespace mozart {

namespace builtins {

/////////////////////////
// Unification-related //
/////////////////////////

OpResult equals(VM vm, UnstableNode* args[]) {
  RichNode left = *args[0];
  RichNode right = *args[1];
  bool result = false;

  MOZART_CHECK_OPRESULT(mozart::equals(vm, left, right, &result));

  args[2]->make<Boolean>(vm, result);
  return OpResult::proceed();
}

OpResult notEquals(VM vm, UnstableNode* args[]) {
  RichNode left = *args[0];
  RichNode right = *args[1];
  bool result = false;

  MOZART_CHECK_OPRESULT(mozart::notEquals(vm, left, right, &result));

  args[2]->make<Boolean>(vm, result);
  return OpResult::proceed();
}

//////////////////
// Value status //
//////////////////

OpResult wait(VM vm, UnstableNode* args[]) {
  RichNode value = *args[0];

  if (value.isTransient())
    return OpResult::waitFor(vm, value);
  else
    return OpResult::proceed();
}

OpResult waitOr(VM vm, UnstableNode* args[]) {
  return RecordLike(*args[0]).waitOr(vm, args[1]);
}

OpResult isDet(VM vm, UnstableNode* args[]) {
  RichNode value = *args[0];
  args[1]->make<Boolean>(vm, !value.isTransient());
  return OpResult::proceed();
}

////////////////
// Arithmetic //
////////////////

OpResult add(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.add(vm, args[1], args[2]);
}

OpResult subtract(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.subtract(vm, args[1], args[2]);
}

OpResult multiply(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.multiply(vm, args[1], args[2]);
}

OpResult divide(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.divide(vm, args[1], args[2]);
}

OpResult div(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.div(vm, args[1], args[2]);
}

OpResult mod(VM vm, UnstableNode* args[]) {
  Numeric x = *args[0];
  return x.mod(vm, args[1], args[2]);
}

/////////////
// Records //
/////////////

OpResult label(VM vm, UnstableNode* args[]) {
  return RecordLike(*args[0]).label(vm, args[1]);
}

OpResult width(VM vm, UnstableNode* args[]) {
  RecordLike x = *args[0];
  return x.width(vm, args[1]);
}

OpResult dot(VM vm, UnstableNode* args[]) {
  RecordLike x = *args[0];
  return x.dot(vm, args[1], args[2]);
}

/////////////
// Threads //
/////////////

OpResult createThread(VM vm, UnstableNode* args[]) {
  RichNode target = *args[0];

  MOZART_CHECK_OPRESULT(expectCallable(vm, target, 0));

  new (vm) Thread(vm, vm->getCurrentSpace(), target.getStableRef(vm));

  return OpResult::proceed();
}

///////////////////
// Miscellaneous //
///////////////////

OpResult show(VM vm, UnstableNode* args[]) {
  std::cout << repr(vm, *args[0]) << std::endl;
  return OpResult::proceed();
}

////////////
// Spaces //
////////////

OpResult newSpace(VM vm, UnstableNode* args[]) {
  RichNode target = *args[0];

  MOZART_CHECK_OPRESULT(expectCallable(vm, target, 1));

  Space* currentSpace = vm->getCurrentSpace();

  // Create the space
  Space* space = new (vm) Space(vm, currentSpace);

  // Create the thread {Proc Root}
  UnstableNode rootVar(vm, *space->getRootVar());
  UnstableNode* threadArgs[] = { &rootVar };

  new (vm) Thread(vm, space, target.getStableRef(vm), 1, threadArgs);

  // Create the reification of the space
  args[1]->make<ReifiedSpace>(vm, space);

  return OpResult::proceed();
}

OpResult askSpace(VM vm, UnstableNode* args[]) {
  return SpaceLike(*args[0]).askSpace(vm, args[1]);
}

OpResult askVerboseSpace(VM vm, UnstableNode* args[]) {
  return SpaceLike(*args[0]).askVerboseSpace(vm, args[1]);
}

OpResult mergeSpace(VM vm, UnstableNode* args[]) {
  return SpaceLike(*args[0]).mergeSpace(vm, args[1]);
}

OpResult commitSpace(VM vm, UnstableNode* args[]) {
  return SpaceLike(*args[0]).commitSpace(vm, args[1]);
}

OpResult cloneSpace(VM vm, UnstableNode* args[]) {
  return SpaceLike(*args[0]).cloneSpace(vm, args[1]);
}

OpResult chooseSpace(VM vm, UnstableNode* args[]) {
  nativeint alternatives = 0;
  MOZART_GET_ARG(alternatives, *args[0], u"integer");

  Space* space = vm->getCurrentSpace();

  if (space->isTopLevel()) {
    args[1]->make<Unbound>(vm);
  } else if (space->hasDistributor()) {
    return raise(vm, u"spaceDistributor");
  } else {
    ChooseDistributor* distributor =
      new (vm) ChooseDistributor(vm, space, alternatives);

    space->setDistributor(distributor);
    args[1]->copy(vm, *distributor->getVar());
  }

  return OpResult::proceed();
}

///////////
// Utils //
///////////

OpResult expectCallable(VM vm, RichNode target, int expectedArity) {
  int arity = 0;
  StableNode* body;
  ProgramCounter start;
  int Xcount;
  StaticArray<StableNode> Gs;
  StaticArray<StableNode> Ks;

  MOZART_CHECK_OPRESULT(Callable(target).getCallInfo(
    vm, &arity, &body, &start, &Xcount, &Gs, &Ks));

  if (arity != expectedArity)
    return raiseIllegalArity(vm, expectedArity, arity);

  return OpResult::proceed();
}

}

}
