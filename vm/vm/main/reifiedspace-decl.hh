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

#ifndef __REIFIEDSPACE_DECL_H
#define __REIFIEDSPACE_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

//////////////////
// ReifiedSpace //
//////////////////

class ReifiedSpace;

#ifndef MOZART_GENERATOR
#include "ReifiedSpace-implem-decl.hh"
#endif

template <>
class Implementation<ReifiedSpace>: public WithHome, StoredAs<SpaceRef> {
public:
  typedef SelfType<ReifiedSpace>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("space"));
  }

  Implementation(SpaceRef space):
    WithHome(space->getParent()), _space(space) {}

  static void build(SpaceRef& self, VM vm, SpaceRef space) {
    self = space;
  }

  inline
  static void build(SpaceRef& self, VM vm, GR gr, Self from);
public:
  Space* getSpace() {
    return _space;
  }
public:
  OpResult isSpace(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult askSpace(Self self, VM vm, UnstableNode& result);

  inline
  OpResult askVerboseSpace(Self self, VM vm, UnstableNode& result);

  inline
  OpResult mergeSpace(Self self, VM vm, UnstableNode& result);

  inline
  OpResult commitSpace(Self self, VM vm, RichNode value);

  inline
  OpResult cloneSpace(Self self, VM vm, UnstableNode& result);

  inline
  OpResult killSpace(Self self, VM vm);
private:
  SpaceRef _space;
};

#ifndef MOZART_GENERATOR
#include "ReifiedSpace-implem-decl-after.hh"
#endif

//////////////////
// DeletedSpace //
//////////////////

class DeletedSpace;

enum DeletedSpaceKind {
  dsFailed, dsMerged
};

#ifndef MOZART_GENERATOR
#include "DeletedSpace-implem-decl.hh"
#endif

template <>
class Implementation<DeletedSpace>: StoredAs<DeletedSpaceKind> {
public:
  typedef SelfType<DeletedSpace>::Self Self;
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("space"));
  }

  Implementation(DeletedSpaceKind kind): _kind(kind) {}

  static void build(DeletedSpaceKind& self, VM vm, DeletedSpaceKind kind) {
    self = kind;
  }

  inline
  static void build(DeletedSpaceKind& self, VM vm, GR gr, Self from);
public:
  DeletedSpaceKind kind() {
    return _kind;
  }
public:
  OpResult isSpace(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult askSpace(Self self, VM vm, UnstableNode& result);

  inline
  OpResult askVerboseSpace(Self self, VM vm, UnstableNode& result);

  inline
  OpResult mergeSpace(Self self, VM vm, UnstableNode& result);

  inline
  OpResult commitSpace(Self self, VM vm, RichNode value);

  inline
  OpResult cloneSpace(Self self, VM vm, UnstableNode& result);

  inline
  OpResult killSpace(Self self, VM vm);
private:
  DeletedSpaceKind _kind;
};

#ifndef MOZART_GENERATOR
#include "DeletedSpace-implem-decl-after.hh"
#endif

}

#endif // __REIFIEDSPACE_DECL_H
