// Copyright © 2013, Université catholique de Louvain
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

#ifndef __WEAKREFS_DECL_H
#define __WEAKREFS_DECL_H

#include "mozartcore-decl.hh"

#include <typeinfo>

namespace mozart {

///////////////////
// WeakReference //
///////////////////

#ifndef MOZART_GENERATOR
#include "WeakReference-implem-decl.hh"
#endif

/**
 * Weak reference that does not maintain its underlying node alive
 */
class WeakReference: public DataType<WeakReference>, StoredAs<StableNode*> {
public:
  explicit WeakReference(StableNode* underlying): _underlying(underlying) {}

  static void create(StableNode*& self, VM vm, StableNode* underlying) {
    self = underlying;
  }

  inline
  static void create(StableNode*& self, VM vm, GR gr, WeakReference from);

public:
  // Will return nullptr when the underlying node is dead
  StableNode* getUnderlying() {
    return _underlying;
  }

private:
  StableNode* _underlying;
};

#ifndef MOZART_GENERATOR
#include "WeakReference-implem-decl-after.hh"
#endif

}

#endif // __WEAKREFS_DECL_H
