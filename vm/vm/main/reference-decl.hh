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

#ifndef __REFERENCE_DECL_H
#define __REFERENCE_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

///////////////
// Reference //
///////////////

#ifndef MOZART_GENERATOR
#include "Reference-implem-decl.hh"
#endif

class Reference: public DataType<Reference>, Copyable, StoredAs<StableNode*> {
public:
  typedef SelfType<Reference>::Self Self;
public:
  Reference(StableNode* dest) : _dest(dest) {}

  static void create(StableNode*& self, VM, StableNode* dest) {
    self = dest;
  }

  static void create(StableNode*& self, VM vm, GR gr, Self from) {
    assert(false);
    self = nullptr;
  }

  StableNode* dest() const { return _dest; }
private:
  StableNode* _dest;
};

#ifndef MOZART_GENERATOR
#include "Reference-implem-decl-after.hh"
#endif

}

#endif // __REFERENCE_DECL_H
