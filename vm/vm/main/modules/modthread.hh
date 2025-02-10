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

#ifndef MOZART_MODTHREAD_H
#define MOZART_MODTHREAD_H

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

    static void call(VM vm, In target) {
      ozcalls::asyncOzCall(vm, target);
    }
  };

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, ThreadLike(value).isThread(vm));
    }
  };

  class This: public Builtin<This> {
  public:
    This(): Builtin("this") {}

    static void call(VM vm, Out result) {
      result = ReifiedThread::build(vm, vm->getCurrentThread());
    }
  };

  class GetPriority: public Builtin<GetPriority> {
  public:
    GetPriority(): Builtin("getPriority") {}

    static void call(VM vm, In thread, Out result) {
      ThreadPriority prio = ThreadLike(thread).getThreadPriority(vm);

      switch (prio) {
        case tpLow: result = build(vm, "low"); break;
        case tpMiddle: result = build(vm, "medium"); break;
        case tpHi: result = build(vm, "high"); break;

        default: assert(false);
      }
    }
  };

  class SetPriority: public Builtin<SetPriority> {
  public:
    SetPriority(): Builtin("setPriority") {}

    static void call(VM vm, In thread, In priority) {
      using namespace patternmatching;

      ThreadPriority prio = tpMiddle;

      if (matches(vm, priority, "low")) {
        prio = tpLow;
      } else if (matches(vm, priority, "medium")) {
        prio = tpMiddle;
      } else if (matches(vm, priority, "high")) {
        prio = tpHi;
      } else {
        raiseTypeError(vm, "low, medium or high", priority);
      }

      ThreadLike(thread).setThreadPriority(vm, prio);
    }
  };

  class InjectException: public Builtin<InjectException> {
  public:
    InjectException(): Builtin("injectException") {}

    static void call(VM vm, In thread, In exception) {
      ThreadLike(thread).injectException(vm, exception);
    }
  };

  class State: public Builtin<State> {
  public:
    State(): Builtin("state") {}

    static void call(VM vm, In thread, Out result) {
      Runnable* runnable = getArgument<Runnable*>(vm, thread);

      if (runnable->isTerminated())
        result = build(vm, "terminated");
      else if (runnable->isRunnable())
        result = build(vm, "runnable");
      else
        result = build(vm, "blocked");
    }
  };

  class Suspend: public Builtin<Suspend> {
  public:
    Suspend(): Builtin("suspend") {}

    static void call(VM vm, In thread) {
      Runnable* runnable = getArgument<Runnable*>(vm, thread);

      runnable->suspend();
    }
  };

  class Resume: public Builtin<Resume> {
  public:
    Resume(): Builtin("resume") {}

    static void call(VM vm, In thread) {
      Runnable* runnable = getArgument<Runnable*>(vm, thread);

      runnable->resume();
    }
  };

  class IsSuspended: public Builtin<IsSuspended> {
  public:
    IsSuspended(): Builtin("isSuspended") {}

    static void call(VM vm, In thread, Out result) {
      Runnable* runnable = getArgument<Runnable*>(vm, thread);

      // FIXME: This is O(threads scheduled).
      // Consider adding a field to the Runnable class.
      result = build(vm, vm->getThreadPool().isScheduled(runnable));
    }
  };

  class Preempt: public Builtin<Preempt> {
  public:
    Preempt(): Builtin("preempt") {}

    static void call(VM vm) {
      vm->requestPreempt();
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // MOZART_MODTHREAD_H
