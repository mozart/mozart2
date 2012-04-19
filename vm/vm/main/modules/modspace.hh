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

#ifndef __MODSPACE_H
#define __MODSPACE_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////
// Space module //
///////////////////

class ModSpace: public Module {
public:
  ModSpace(): Module("Space") {}

  class New: public Builtin<New> {
  public:
    New(): Builtin("new") {}

    OpResult operator()(VM vm, In target, Out result) {
      MOZART_CHECK_OPRESULT(expectCallable(vm, target, 1));

      Space* currentSpace = vm->getCurrentSpace();

      // Create the space
      Space* space = new (vm) Space(vm, currentSpace);

      // Create the thread {Proc Root}
      UnstableNode rootVar(vm, *space->getRootVar());
      UnstableNode* threadArgs[] = { &rootVar };

      new (vm) Thread(vm, space, target.getStableRef(vm), 1, threadArgs);

      // Create the reification of the space
      result.make<ReifiedSpace>(vm, space);

      return OpResult::proceed();
    }
  };

  class Ask: public Builtin<Ask> {
  public:
    Ask(): Builtin("ask") {}

    OpResult operator()(VM vm, In space, Out result) {
      return SpaceLike(space).askSpace(vm, &result);
    }
  };

  class AskVerbose: public Builtin<AskVerbose> {
  public:
    AskVerbose(): Builtin("askVerbose") {}

    OpResult operator()(VM vm, In space, Out result) {
      return SpaceLike(space).askVerboseSpace(vm, &result);
    }
  };

  class Merge: public Builtin<Merge> {
  public:
    Merge(): Builtin("merge") {}

    OpResult operator()(VM vm, In space, Out result) {
      return SpaceLike(space).mergeSpace(vm, &result);
    }
  };

  class Clone: public Builtin<Clone> {
  public:
    Clone(): Builtin("clone") {}

    OpResult operator()(VM vm, In space, Out result) {
      return SpaceLike(space).cloneSpace(vm, &result);
    }
  };

  class Commit: public Builtin<Commit> {
  public:
    Commit(): Builtin("commit") {}

    OpResult operator()(VM vm, In space, In value) {
      return SpaceLike(space).commitSpace(vm, &value.origin());
    }
  };

  class Choose: public Builtin<Choose> {
  public:
    Choose(): Builtin("choose") {}

    OpResult operator()(VM vm, In alts, Out result) {
      nativeint alternatives = 0;
      MOZART_GET_ARG(alternatives, alts, u"integer");

      Space* space = vm->getCurrentSpace();

      if (space->isTopLevel()) {
        result.make<Unbound>(vm);
      } else if (space->hasDistributor()) {
        return raise(vm, u"spaceDistributor");
      } else {
        ChooseDistributor* distributor =
          new (vm) ChooseDistributor(vm, space, alternatives);

        space->setDistributor(distributor);
        result.copy(vm, *distributor->getVar());
      }

      return OpResult::proceed();
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODSPACE_H
