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

#ifndef __GCTYPES_H
#define __GCTYPES_H

#include "gctypes-decl.hh"

#ifndef MOZART_GENERATOR
#include "GCedToStable-implem.hh"
#endif

//////////////////
// GCedToStable //
//////////////////

void GCedToStableBase::gCollect(GC gc, Node& from, StableNode& to) const {
  StableNode* dest = IMPLNOSELF(StableNode*, GCedToStable, dest, &from);
  to.init(gc->vm, *dest);
}

void GCedToStableBase::gCollect(GC gc, Node& from, UnstableNode& to) const {
  StableNode* dest = IMPLNOSELF(StableNode*, GCedToStable, dest, &from);
  to.copy(gc->vm, *dest);
}

//////////////////
// GCedToStable //
//////////////////

void GCedToUnstableBase::gCollect(GC gc, Node& from, StableNode& to) const {
  UnstableNode* dest = IMPLNOSELF(UnstableNode*, GCedToUnstable, dest, &from);
  to.init(gc->vm, *dest);
}

void GCedToUnstableBase::gCollect(GC gc, Node& from, UnstableNode& to) const {
  UnstableNode* dest = IMPLNOSELF(UnstableNode*, GCedToUnstable, dest, &from);
  to.copy(gc->vm, *dest);
}

#endif // __GCTYPES_H
