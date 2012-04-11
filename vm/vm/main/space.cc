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

namespace mozart {

///////////
// Space //
///////////

// Operations

void Space::failInternal(VM vm) {
  assert(!isTopLevel());

  Space* parent = getParent();
  _status = ssFailed;
  parent->decRunnableThreadCount();

  deinstallThisFailed();
  vm->setCurrentSpace(parent);

  bindStatusVar(vm, trivialBuild(vm, u"failed"));
}

// Status variable

void Space::clearStatusVar(VM vm) {
  _statusVar.make<Unbound>(vm);
}

void Space::bindStatusVar(VM vm, RichNode value) {
  RichNode statusVar = *getStatusVar();
  assert(statusVar.type()->isTransient());
  DataflowVariable(statusVar).bind(vm, value);
}

void Space::bindStatusVar(VM vm, UnstableNode&& value) {
  bindStatusVar(vm, RichNode(value));
}

UnstableNode Space::genSucceeded(VM vm, bool isEntailed) {
  return buildTuple(vm, u"succeeded", isEntailed ? u"entailed" : u"stuck");
}

// Stability detection

void Space::checkStability() {
  assert(!isTopLevel());
  assert(status() == ssNormal);

  Space* parent = getParent();

  if (isStable()) {
    // Succeeded
    vm->setCurrentSpace(parent);

    if (hasDistributor()) {
      nativeint alternatives = getDistributor()->getAlternatives();
      UnstableNode newStatus = buildTuple(vm, u"alternatives", alternatives);
      bindStatusVar(vm, newStatus);
    } else {
      bindStatusVar(vm, genSucceeded(vm, getThreadCount() == 0));
    }
  } else {
    deinstallTo(parent); // TODO Why !?

    if (!hasRunnableThreads()) {
      // No runnable threads: suspended

      UnstableNode newStatusVar = UnstableNode::build<Unbound>(vm, parent);
      bindStatusVar(vm, buildTuple(vm, u"suspended", newStatusVar));
      _statusVar = std::move(newStatusVar);
    }
  }
}

// Installation and deinstallation

bool Space::install() {
  Space* from = vm->getCurrentSpace();
  if (from == this)
    return true;

  if (!isAlive())
    return false;

  Space* ancestor = findCommonAncestor(from);

  from->deinstallTo(ancestor);
  return this->installFrom(ancestor);
}

Space* Space::findCommonAncestor(Space* other) {
  // Set marks in all ancestors of other
  for (Space* s = other; s != nullptr; s = s->getParent())
    s->setMark();

  // Find the common ancestor, it's the first of my ancestors which is marked
  Space* result = this;
  while (!result->hasMark())
    result = result->getParent();

  // Unset marks
  for (Space* s = other; s != nullptr; s = s->getParent())
    s->unsetMark();

  return result;
}

void Space::deinstallTo(Space* ancestor) {
  for (Space* s = this; s != ancestor; ) {
    s->deinstallThis();
    s = s->getParent();
    vm->setCurrentSpace(s);
  }
}

bool Space::installFrom(Space* ancestor) {
  if (this == ancestor)
    return true;

  if (!getParent()->installFrom(ancestor))
    return false;

  vm->setCurrentSpace(this);

  return installThis();
}

namespace {
  void createPropagateThreadOnceAndSuspendItOnVar(VM vm, Space* space,
                                                  Runnable*& propagateThread,
                                                  RichNode variable) {
    if (variable.type()->isTransient()) {
      if (propagateThread == nullptr)
        propagateThread = new internal::DummyThread(vm, space);
      DataflowVariable(variable).addToSuspendList(vm, propagateThread);
    }
  }
}

void Space::deinstallThis() {
  bool hasNoRunnableThreads = !hasRunnableThreads();
  Runnable* propagateThread = nullptr;

  while (!trail.empty()) {
    TrailEntry& trailEntry = trail.front();
    ScriptEntry& scriptEntry = script.append(vm);

    scriptEntry.left.node = trailEntry.node->node;
    trailEntry.node->node = trailEntry.saved;
    scriptEntry.right.make<Reference>(vm, trailEntry.node);

    if (hasNoRunnableThreads) {
      createPropagateThreadOnceAndSuspendItOnVar(vm, this, propagateThread,
                                                 scriptEntry.left);
      createPropagateThreadOnceAndSuspendItOnVar(vm, this, propagateThread,
                                                 scriptEntry.right);
    }

    trail.remove_front(vm);
  }
}

void Space::deinstallThisFailed() {
  while (!trail.empty()) {
    TrailEntry& trailEntry = trail.front();
    trailEntry.node->node = trailEntry.saved;
    trail.remove_front(vm);
  }
}

bool Space::installThis(bool isMerge) {
  bool result = true;

  for (auto iter = script.begin(); iter != script.end(); ++iter) {
    BuiltinResult res = unify(vm, iter->left, iter->right);

    if (!res.isProceed()) {
      assert(res.isFailed());
      fail(vm);
      result = false;
      break;
    }
  }

  script.clear(vm);

  return result;
}

}
