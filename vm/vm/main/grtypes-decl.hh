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

#ifndef __GRTYPES_DECL_H
#define __GRTYPES_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

//////////////////
// GRedToStable //
//////////////////

class GRedToStableBase: public TypeInfo {
public:
  GRedToStableBase(std::string name, const UUID& uuid,
                   bool copyable, bool transient, bool feature,
                   StructuralBehavior structuralBehavior,
                   unsigned char bindingPriority) :
    TypeInfo(name, uuid, copyable, transient, feature,
             structuralBehavior, bindingPriority) {}

  inline
  void gCollect(GC gc, RichNode from, StableNode& to) const;

  inline
  void gCollect(GC gc, RichNode from, UnstableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, StableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, UnstableNode& to) const;
};

#ifndef MOZART_GENERATOR
#include "GRedToStable-implem-decl.hh"
#endif

class GRedToStable: public DataType<GRedToStable>, StoredAs<StableNode*>,
  NoAutoGCollect, NoAutoSClone, BasedOn<GRedToStableBase> {
public:
  typedef SelfType<GRedToStable>::Self Self;
public:
  GRedToStable(StableNode* dest) : _dest(dest) {}

  static void create(StableNode*& self, VM vm, StableNode* dest) {
    self = dest;
  }

  StableNode* dest() const { return _dest; }
private:
  StableNode* _dest;
};

#ifndef MOZART_GENERATOR
#include "GRedToStable-implem-decl-after.hh"
#endif

////////////////////
// GRedToUnstable //
////////////////////

class GRedToUnstableBase: public TypeInfo {
public:
  GRedToUnstableBase(std::string name, const UUID& uuid,
                     bool copyable, bool transient, bool feature,
                     StructuralBehavior structuralBehavior,
                     unsigned char bindingPriority) :
    TypeInfo(name, uuid, copyable, transient, feature,
             structuralBehavior, bindingPriority) {}

  inline
  void gCollect(GC gc, RichNode from, StableNode& to) const;

  inline
  void gCollect(GC gc, RichNode from, UnstableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, StableNode& to) const;

  inline
  void sClone(SC sc, RichNode from, UnstableNode& to) const;
};

#ifndef MOZART_GENERATOR
#include "GRedToUnstable-implem-decl.hh"
#endif

class GRedToUnstable: public DataType<GRedToUnstable>, StoredAs<UnstableNode*>,
  NoAutoGCollect, NoAutoSClone, BasedOn<GRedToUnstableBase> {
public:
  typedef SelfType<GRedToUnstable>::Self Self;
public:
  GRedToUnstable(UnstableNode* dest) : _dest(dest) {}

  static void create(UnstableNode*& self, VM vm, UnstableNode* dest) {
    self = dest;
  }

  UnstableNode* dest() const { return _dest; }
private:
  UnstableNode* _dest;
};

#ifndef MOZART_GENERATOR
#include "GRedToUnstable-implem-decl-after.hh"
#endif

}

#endif // __GRTYPES_DECL_H
