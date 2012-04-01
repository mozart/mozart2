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

#include "mozartcore.hh"

namespace mozart {

//////////////////
// ReifiedSpace //
//////////////////

class ReifiedSpace;

#ifndef MOZART_GENERATOR
#include "ReifiedSpace-implem-decl.hh"
#endif

template <>
class Implementation<ReifiedSpace> {
public:
  typedef SelfType<ReifiedSpace>::Self Self;

  enum Status {
    ssNormal, ssFailed, ssMerged
  };
public:
  Implementation(VM, Space* space) : _space(space), _status(ssNormal) {}

  inline
  Implementation(VM vm, GC gc, Self from);

  Space* getSpace() {
    return _space;
  }

  Status status() {
    return _status;
  }

  bool isFailed() {
    return status() == ssFailed;
  }

  bool isMerged() {
    return status() == ssMerged;
  }
public:
  inline
  BuiltinResult isSpace(VM vm, UnstableNode* result);

  inline
  BuiltinResult askVerboseSpace(Self self, VM vm, UnstableNode* result);

  inline
  BuiltinResult mergeSpace(Self self, VM vm, UnstableNode* result);
private:
  SpaceRef _space;
  Status _status;
};

#ifndef MOZART_GENERATOR
#include "ReifiedSpace-implem-decl-after.hh"
#endif

}

#endif // __REIFIEDSPACE_DECL_H
