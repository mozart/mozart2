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

//////////////////////
// Inline Variable ///
//////////////////////

BuiltinResult Implementation<Variable>::wait(Self self, VM vm,
                                             Suspendable* thread) {
  thread->unsetRunnable();
  pendingThreads.push_back(thread);

  return self;
}

BuiltinResult Implementation<Variable>::bind(Self self, VM vm, Node* src) {
  // Actual binding
  if (!src->type->isCopiable())
    Reference::makeFor(vm, *src);
  *self = *src;

  // If the value we were bound to is a Variable too, we have to transfer the
  // threads waiting for this so that they wait for the other Variable.
  // Otherwise, we wake up the threads.
  Node& node = Reference::dereference(*self);
  if (node.type == Variable::type) {
    IMPLNOSELF(void, Variable, transferPendingThreads, &node,
               vm, pendingThreads);
  } else {
    resumePendingThreads(vm);
  }

  return BuiltinResultContinue;
}

void Implementation<Variable>::resumePendingThreads(VM vm) {
  ThreadPool& threadPool = vm->getThreadPool();

  for (auto iter = pendingThreads.cbegin();
       iter != pendingThreads.cend(); iter++) {

    (*iter)->setRunnable();
    threadPool.schedule(*iter);
  }

  pendingThreads.clear();
}

/////////////////////
// Inline Unbound ///
/////////////////////

BuiltinResult Implementation<Unbound>::wait(Self self, VM vm,
                                            Suspendable* thread) {
  self->make<Variable>(vm);

  DataflowVariable var = *self;
  return var.wait(vm, thread);
}

BuiltinResult Implementation<Unbound>::bind(Self self, VM vm, Node* src) {
  if (!src->type->isCopiable())
    Reference::makeFor(vm, *src);
  *self = *src;

  return BuiltinResultContinue;
}

#endif // __VARIABLES_H
