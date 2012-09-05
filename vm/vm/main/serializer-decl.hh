// Copyright © 2012, Université catholique de Louvain
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

#ifndef __SERIALIZER_DECL_H
#define __SERIALIZER_DECL_H

#include "mozartcore-decl.hh"

#include "memmanlist.hh"

#include <cassert>

namespace mozart {

///////////////////////////
// SerializationCallback //
///////////////////////////

class SerializationCallback {
private:
  inline
  explicit SerializationCallback(VM vm);

public:
  inline
  void copy(RichNode to, RichNode from);

private:
  friend class Serializer;

  MemoryManager& secondMM;
  MemManagedList<RichNode> todoFrom;
  MemManagedList<RichNode> todoTo;
};

////////////////
// Serialized //
////////////////

#ifndef MOZART_GENERATOR
#include "Serialized-implem-decl.hh"
#endif

class Serialized: public DataType<Serialized>, StoredAs<nativeint> {
public:
  explicit Serialized(nativeint n) : _n(n) {}

  static void create(nativeint& self, VM vm, nativeint n) {
    self = n;
  }

  static void create(nativeint& self, VM vm, GR gr, Serialized from) {
    assert(false);
  }

  nativeint n() const { return _n; }

private:
  nativeint _n;
};

#ifndef MOZART_GENERATOR
#include "Serialized-implem-decl-after.hh"
#endif

////////////////
// Serializer //
////////////////

#ifndef MOZART_GENERATOR
#include "Serializer-implem-decl.hh"
#endif

class Serializer: public DataType<Serializer> {
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("serializer"));
  }

  inline
  explicit Serializer(VM vm);

  inline
  Serializer(VM vm, GR gr, Serializer& from);

public:
  UnstableNode doSerialize(VM vm, RichNode todo);

private:
  UnstableNode done;
};

#ifndef MOZART_GENERATOR
#include "Serializer-implem-decl-after.hh"
#endif

}

#endif // __SERIALIZER_DECL_H
