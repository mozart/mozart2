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

#ifndef __MODTHREAD_H
#define __MODTHREAD_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////
// Thread module //
///////////////////

class ModThread: public Module {
public:
  ModThread(): Module("Thread") {}

  class Create: public Builtin<Create> {
  public:
    Create(): Builtin("create") {}

    OpResult operator()(VM vm, In target) {
      MOZART_CHECK_OPRESULT(expectCallable(vm, target, 0));

      new (vm) Thread(vm, vm->getCurrentSpace(), target);

      return OpResult::proceed();
    }
  };

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    OpResult operator()(VM vm, In value, Out result) {
      return ThreadLike(value).isThread(vm, result);
    }
  };

  class This: public Builtin<This> {
  public:
    This(): Builtin("this") {}

    OpResult operator()(VM vm, Out result) {
      result = ReifiedThread::build(vm, vm->getCurrentThread());
      return OpResult::proceed();
    }
  };

  class GetPriority: public Builtin<GetPriority> {
  public:
    GetPriority(): Builtin("getPriority") {}

    OpResult operator()(VM vm, In thread, Out result) {
      ThreadPriority prio = tpMiddle;
      MOZART_CHECK_OPRESULT(ThreadLike(thread).getThreadPriority(vm, prio));

      switch (prio) {
        case tpLow: result = trivialBuild(vm, u"low"); break;
        case tpMiddle: result = trivialBuild(vm, u"medium"); break;
        case tpHi: result = trivialBuild(vm, u"high"); break;

        default: assert(false);
      }

      return OpResult::proceed();
    }
  };

  class SetPriority: public Builtin<SetPriority> {
  public:
    SetPriority(): Builtin("setPriority") {}

    OpResult operator()(VM vm, In thread, In priority) {
      using namespace patternmatching;

      ThreadPriority prio = tpMiddle;
      OpResult res = OpResult::proceed();

      if (matches(vm, res, priority, u"low")) {
        prio = tpLow;
      } else if (matches(vm, res, priority, u"medium")) {
        prio = tpMiddle;
      } else if (matches(vm, res, priority, u"high")) {
        prio = tpHi;
      } else {
        return matchTypeError(vm, res, priority, u"low, medium or high");
      }

      return ThreadLike(thread).setThreadPriority(vm, prio);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODTHREAD_H
