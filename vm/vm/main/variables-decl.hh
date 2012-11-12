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

//////////////////
// VariableBase //
//////////////////

template <class This>
class VariableBase: public WithHome {
private:
  typedef typename SelfType<This>::Self HSelf;
public:
  VariableBase(VM vm): WithHome(vm) {}

  VariableBase(VM vm, Space* home): WithHome(home) {}

  inline
  VariableBase(VM vm, GR gr, HSelf from);

public:
  // DataflowVariable interface

  inline
  void addToSuspendList(VM vm, RichNode variable);

  bool isNeeded(VM vm) {
    return _needed;
  }

  inline
  void markNeeded(VM vm);

  /* To be implemented in subclasses
  inline
  void bind(VM vm, RichNode src);
  */

protected:
  inline
  void doBind(RichNode self, VM vm, RichNode src);

private:
  // TODO Might be a good candidate for noinline
  inline
  void bindSubSpace(RichNode self, VM vm, RichNode src);

  inline
  void wakeUpPendings(VM vm);

  inline
  void wakeUpPendingsSubSpace(VM vm, Space* currentSpace);

  VMAllocatedList<StableNode*> pendings;

  /* TODO maybe we can squeeze this bit of information into pendings
   * Idea: a leading `nullptr` element in pendings? */
  bool _needed;
};

//////////////
// Variable //
//////////////

#ifndef MOZART_GENERATOR
#include "Variable-implem-decl.hh"
#endif

class Variable: public DataType<Variable>, public VariableBase<Variable>,
  Transient, WithVariableBehavior<90> {
public:
  Variable(VM vm): VariableBase(vm) {}

  Variable(VM vm, Space* home): VariableBase(vm, home) {}

  inline
  Variable(VM vm, GR gr, Self from);

public:
  // Wakeable interface

  inline
  void wakeUp(RichNode self, VM vm);

  inline
  bool shouldWakeUpUnderSpace(VM vm, Space* space);

public:
  // DataflowVariable interface

  inline
  void bind(RichNode self, VM vm, RichNode src);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth) {
    out << "_";
  }
};

#ifndef MOZART_GENERATOR
#include "Variable-implem-decl-after.hh"
#endif

//////////////////////
// ReadOnlyVariable //
//////////////////////

#ifndef MOZART_GENERATOR
#include "ReadOnlyVariable-implem-decl.hh"
#endif

class ReadOnlyVariable: public DataType<ReadOnlyVariable>,
  public VariableBase<ReadOnlyVariable>,
  Transient, WithVariableBehavior<80> {
public:
  ReadOnlyVariable(VM vm): VariableBase(vm) {}

  ReadOnlyVariable(VM vm, Space* home): VariableBase(vm, home) {}

  inline
  ReadOnlyVariable(VM vm, GR gr, Self from);

public:
  // DataflowVariable interface

  inline
  void bind(RichNode self, VM vm, RichNode src);

public:
  // BindableReadOnly interface

  inline
  void bindReadOnly(RichNode self, VM vm, RichNode src);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth) {
    out << "!!_";
  }
};

#ifndef MOZART_GENERATOR
#include "ReadOnlyVariable-implem-decl-after.hh"
#endif

////////////
// OptVar //
////////////

#ifndef MOZART_GENERATOR
#include "OptVar-implem-decl.hh"
#endif

class OptVar: public DataType<OptVar>, public WithHome,
  Transient, StoredAs<SpaceRef>, WithVariableBehavior<100> {
public:
  OptVar(SpaceRef home): WithHome(home) {}

  static void create(SpaceRef& self, VM vm) {
    self = vm->getCurrentSpace();
  }

  static void create(SpaceRef& self, VM vm, Space* home) {
    self = home;
  }

  inline
  static void create(SpaceRef& self, VM vm, GR gr, Self from);

public:
  // DataflowVariable interface

  inline
  void addToSuspendList(RichNode self, VM vm, RichNode variable);

  bool isNeeded(VM vm) {
    return false;
  }

  inline
  void markNeeded(RichNode self, VM vm);

  inline
  void bind(RichNode self, VM vm, UnstableNode&& src);

  inline
  void bind(RichNode self, VM vm, RichNode src);

private:
  inline
  void makeBackupForSpeculativeBindingIfNeeded(RichNode self, VM vm);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth) {
    out << "_<optimized>";
  }
};

#ifndef MOZART_GENERATOR
#include "OptVar-implem-decl-after.hh"
#endif

//////////////
// ReadOnly //
//////////////

#ifndef MOZART_GENERATOR
#include "ReadOnly-implem-decl.hh"
#endif

class ReadOnly: public DataType<ReadOnly>, Transient, StoredAs<StableNode*>,
  WithVariableBehavior<80> {
public:
  ReadOnly(StableNode* underlying): _underlying(underlying) {}

  static void create(StableNode*& self, VM vm, StableNode* underlying) {
    self = underlying;
  }

  inline
  static void create(StableNode*& self, VM vm, GR gr, Self from);

public:
  inline
  static void newReadOnly(StableNode& dest, VM vm, RichNode underlying);

  inline
  static UnstableNode newReadOnly(VM vm, RichNode underlying);

private:
  inline
  static bool needsProtection(VM vm, RichNode underlying);

public:
  StableNode* getUnderlying() {
    return _underlying;
  }

public:
  // Wakeable interface

  inline
  void wakeUp(RichNode self, VM vm);

  inline
  bool shouldWakeUpUnderSpace(VM vm, Space* space);

public:
  // DataflowVariable interface

  inline
  void addToSuspendList(VM vm, RichNode variable);

  inline
  bool isNeeded(VM vm);

  inline
  void markNeeded(VM vm);

  inline
  void bind(VM vm, RichNode src);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth) {
    out << "!!" << repr(vm, *_underlying, depth);
  }

private:
  StableNode* _underlying;
};

#ifndef MOZART_GENERATOR
#include "ReadOnly-implem-decl-after.hh"
#endif

/////////////////
// FailedValue //
/////////////////

#ifndef MOZART_GENERATOR
#include "FailedValue-implem-decl.hh"
#endif

class FailedValue: public DataType<FailedValue>,
  Transient, StoredAs<StableNode*>, WithVariableBehavior<10> {
public:
  FailedValue(StableNode* underlying): _underlying(underlying) {}

  static void create(StableNode*& self, VM vm, StableNode* underlying) {
    self = underlying;
  }

  inline
  static void create(StableNode*& self, VM vm, GR gr, Self from);

public:
  StableNode* getUnderlying() {
    return _underlying;
  }

  inline
  void raiseUnderlying(VM vm);

public:
  // DataflowVariable interface

  inline
  void addToSuspendList(VM vm, RichNode variable);

  inline
  bool isNeeded(VM vm);

  inline
  void markNeeded(VM vm);

  inline
  void bind(VM vm, RichNode src);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth) {
    out << "<Failed " << repr(vm, *_underlying, depth) << ">";
  }

private:
  StableNode* _underlying;
};

#ifndef MOZART_GENERATOR
#include "FailedValue-implem-decl-after.hh"
#endif

}

#endif // __VARIABLES_DECL_H
