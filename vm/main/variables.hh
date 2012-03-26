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

#ifndef __VARIABLES_H
#define __VARIABLES_H

#include "variables-decl.hh"

#include "coreinterfaces.hh"

namespace mozart {

//////////////////////
// Inline Variable ///
//////////////////////

#ifndef MOZART_GENERATOR
#include "Variable-implem.hh"
#endif

Implementation<Variable>::Implementation(VM vm, GC gc, Self from) {
  gc->gcSpace(from->_home, _home);

  for (auto iterator = from->pendingThreads.begin();
       iterator != from->pendingThreads.end();
       iterator++) {
    pendingThreads.push_back(vm, *iterator);
    gc->gcThread(pendingThreads.back(), pendingThreads.back());
  }
}

void Implementation<Variable>::addToSuspendList(Self self, VM vm,
                                                Runnable* thread) {
  thread->unsetRunnable();
  pendingThreads.push_back(vm, thread);
}

void Implementation<Variable>::addToSuspendList(Self self, VM vm,
                                                RichNode variable) {
  pendingVariables.push_back(vm, variable.getStableRef(vm));
}

BuiltinResult Implementation<Variable>::bind(Self self, VM vm, RichNode src) {
  // Actual binding
  RichNode(self).reinit(vm, src);

  // If the value we were bound to is a Variable too, we have to transfer the
  // threads waiting for this so that they wait for the other Variable.
  // Otherwise, we wake up the threads.
  src.update();
  if (src.type() == Variable::type()) {
    src.as<Variable>().transferPendings(vm, pendingThreads, pendingVariables);
  } else {
    resumePendings(vm);
  }

  return BuiltinResult::proceed();
}

void Implementation<Variable>::resumePendings(VM vm) {
  // Wake up threads

  ThreadPool& threadPool = vm->getThreadPool();

  for (auto iter = pendingThreads.begin();
       iter != pendingThreads.end(); iter++) {

    (*iter)->setRunnable();
    threadPool.schedule(*iter);
  }

  pendingThreads.clear(vm);

  // "Wake up", i.e., bind control variables

  for (auto iter = pendingVariables.begin();
       iter != pendingVariables.end(); iter++) {
    UnstableNode unstableVar(vm, **iter);
    RichNode variable = unstableVar;

    if (variable.type()->isTransient()) {
      UnstableNode unit = UnstableNode::build<SmallInt>(vm, 0);
      DataflowVariable(variable).bind(vm, unit);
    }
  }

  pendingVariables.clear(vm);
}

/////////////////////
// Inline Unbound ///
/////////////////////

#ifndef MOZART_GENERATOR
#include "Unbound-implem.hh"
#endif

SpaceRef Implementation<Unbound>::build(VM vm, GC gc, Self from) {
  SpaceRef home;
  gc->gcSpace(from.get().home(), home);
  return home;
}

void Implementation<Unbound>::addToSuspendList(Self self, VM vm,
                                               Runnable* thread) {
  self.remake<Variable>(vm);
  DataflowVariable(self).addToSuspendList(vm, thread);
}

void Implementation<Unbound>::addToSuspendList(Self self, VM vm,
                                               RichNode variable) {
  self.remake<Variable>(vm);
  DataflowVariable(self).addToSuspendList(vm, variable);
}

BuiltinResult Implementation<Unbound>::bind(Self self, VM vm, RichNode src) {
  RichNode(self).reinit(vm, src);

  return BuiltinResult::proceed();
}

}

#endif // __VARIABLES_H
