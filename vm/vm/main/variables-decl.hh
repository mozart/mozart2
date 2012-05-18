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

#ifndef __VARIABLES_DECL_H
#define __VARIABLES_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

//////////////
// Variable //
//////////////

class Variable;

#ifndef MOZART_GENERATOR
#include "Variable-implem-decl.hh"
#endif

template <>
class Implementation<Variable>: public WithHome, Transient,
  WithVariableBehavior<90> {
public:
  typedef SelfType<Variable>::Self Self;
public:
  Implementation(VM vm): WithHome(vm) {}

  Implementation(VM vm, Space* home): WithHome(home) {}

  inline
  Implementation(VM vm, GR gr, Self from);

public:
  // Wakeable interface

  inline
  OpResult wakeUp(Self self, VM vm);

  inline
  bool shouldWakeUpUnderSpace(VM vm, Space* space);

public:
  // DataflowVariable interface

  inline
  void addToSuspendList(Self self, VM vm, RichNode variable);

  bool isNeeded(VM vm) {
    return _needed;
  }

  inline
  void markNeeded(Self self, VM vm);

  inline
  OpResult bind(Self self, VM vm, RichNode src);

public:
  // Transfer pendings

  inline
  void transferPendings(VM vm, VMAllocatedList<StableNode*>& src);

  inline
  void transferPendingsSubSpace(VM vm, Space* currentSpace,
                                VMAllocatedList<StableNode*>& src);
public:
  // Miscellaneous

  void printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
    out << "_";
  }
private:
  // TODO Might a good candidate for noinline
  inline
  OpResult bindSubSpace(Self self, VM vm, RichNode src);

  inline
  void wakeUpPendings(VM vm);

  inline
  void wakeUpPendingsSubSpace(VM vm, Space* currentSpace);

  VMAllocatedList<StableNode*> pendings;

  /* TODO maybe we can squeeze this bit of information into pendings
   * Idea: a leading `nullptr` element in pendings? */
  bool _needed;
};

#ifndef MOZART_GENERATOR
#include "Variable-implem-decl-after.hh"
#endif

/////////////
// Unbound //
/////////////

class Unbound;

#ifndef MOZART_GENERATOR
#include "Unbound-implem-decl.hh"
#endif

template <>
class Implementation<Unbound>: public WithHome, Transient, StoredAs<SpaceRef>,
  WithVariableBehavior<100> {
public:
  typedef SelfType<Unbound>::Self Self;
public:
  Implementation(SpaceRef home): WithHome(home) {}

  static SpaceRef build(VM vm) {
    return vm->getCurrentSpace();
  }

  static SpaceRef build(VM vm, Space* home) {
    return home;
  }

  inline
  static SpaceRef build(VM vm, GR gr, Self from);

public:
  // DataflowVariable interface

  inline
  void addToSuspendList(Self self, VM vm, RichNode variable);

  bool isNeeded(VM vm) {
    return false;
  }

  inline
  void markNeeded(Self self, VM vm);

  inline
  OpResult bind(Self self, VM vm, RichNode src);

public:
  // Miscellaneous

  void printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
    out << "_<optimized>";
  }
};

#ifndef MOZART_GENERATOR
#include "Unbound-implem-decl-after.hh"
#endif

/////////////
// Unbound //
/////////////

class ReadOnly;

#ifndef MOZART_GENERATOR
#include "ReadOnly-implem-decl.hh"
#endif

template <>
class Implementation<ReadOnly>: Transient, StoredAs<StableNode*>,
  WithVariableBehavior<80> {
public:
  typedef SelfType<ReadOnly>::Self Self;
public:
  Implementation(StableNode* underlying): _underlying(underlying) {}

  static StableNode* build(VM vm, StableNode* underlying) {
    return underlying;
  }

  inline
  static StableNode* build(VM vm, GR gr, Self from);

public:
  StableNode* getUnderlying() {
    return _underlying;
  }

public:
  // Wakeable interface

  inline
  OpResult wakeUp(Self self, VM vm);

  inline
  bool shouldWakeUpUnderSpace(VM vm, Space* space);

public:
  // DataflowVariable interface

  inline
  void addToSuspendList(Self self, VM vm, RichNode variable);

  inline
  bool isNeeded(VM vm);

  inline
  void markNeeded(Self self, VM vm);

  inline
  OpResult bind(Self self, VM vm, RichNode src);

public:
  // Miscellaneous

  void printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
    out << "!!" << repr(vm, *_underlying, depth);
  }

private:
  StableNode* _underlying;
};

#ifndef MOZART_GENERATOR
#include "ReadOnly-implem-decl-after.hh"
#endif

}

#endif // __VARIABLES_DECL_H
