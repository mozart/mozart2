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

#ifndef __GCTYPES_DECL_H
#define __GCTYPES_DECL_H

#include "vm-decl.hh"
#include "type.hh"

namespace mozart {

//////////////////
// GCedToStable //
//////////////////

class GCedToStable;

class GCedToStableBase: public Type {
public:
  GCedToStableBase(std::string name, bool copiable, bool transient) :
    Type(name, copiable, transient) {}

  inline
  void gCollect(GC gc, RichNode from, StableNode& to) const;

  inline
  void gCollect(GC gc, RichNode from, UnstableNode& to) const;
};

#ifndef MOZART_GENERATOR
#include "GCedToStable-implem-decl.hh"
#endif

template <>
class Implementation<GCedToStable>: StoredAs<StableNode*>,
  NoAutoGCollect, BasedOn<GCedToStableBase> {
public:
  typedef SelfType<GCedToStable>::Self Self;
public:
  Implementation(StableNode* dest) : _dest(dest) {}

  static StableNode* build(VM vm, StableNode* dest) { return dest; }

  StableNode* dest() const { return _dest; }
private:
  StableNode* _dest;
};

#ifndef MOZART_GENERATOR
#include "GCedToStable-implem-decl-after.hh"
#endif

////////////////////
// GCedToUnstable //
////////////////////

class GCedToUnstable;

class GCedToUnstableBase: public Type {
public:
  GCedToUnstableBase(std::string name, bool copiable, bool transient) :
    Type(name, copiable, transient) {}

  inline
  void gCollect(GC gc, RichNode from, StableNode& to) const;

  inline
  void gCollect(GC gc, RichNode from, UnstableNode& to) const;
};

#ifndef MOZART_GENERATOR
#include "GCedToUnstable-implem-decl.hh"
#endif

template <>
class Implementation<GCedToUnstable>: StoredAs<UnstableNode*>,
  NoAutoGCollect, BasedOn<GCedToUnstableBase> {
public:
  typedef SelfType<GCedToUnstable>::Self Self;
public:
  Implementation(UnstableNode* dest) : _dest(dest) {}

  static UnstableNode* build(VM vm, UnstableNode* dest) { return dest; }

  UnstableNode* dest() const { return _dest; }
private:
  UnstableNode* _dest;
};

#ifndef MOZART_GENERATOR
#include "GCedToUnstable-implem-decl-after.hh"
#endif

}

#endif // __GCTYPES_DECL_H
