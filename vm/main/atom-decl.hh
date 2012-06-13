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

#ifndef __ATOM_DECL_H
#define __ATOM_DECL_H

#include "mozartcore-decl.hh"

#include "datatypeshelpers-decl.hh"

#include <string>
#include <ostream>

namespace mozart {

class Atom;

#ifndef MOZART_GENERATOR
#include "Atom-implem-decl.hh"
#endif

template <>
class Implementation<Atom>: public LiteralHelper<Atom>,
  Copyable, StoredAs<AtomImpl*>, WithValueBehavior {
public:
  typedef SelfType<Atom>::Self Self;
public:
  static constexpr UUID uuid = "{55ed333b-1eaf-4c8a-a151-626d3f96efe8}";

  Implementation(const AtomImpl* value) : _value(value) {}

  static void build(AtomImpl*& self, VM vm, std::size_t length,
                    const nchar* contents) {
    self = vm->atomTable.get(vm, length, contents);
  }

  static void build(AtomImpl*& self, VM vm, const nchar* contents) {
    self = vm->atomTable.get(vm, contents);
  }

  static void build(AtomImpl*& self, VM vm, AtomImpl* value) {
    self = value;
  }

  inline
  static void build(AtomImpl*& self, VM vm, GR gr, Self from);

public:
  const AtomImpl* value() const { return _value; }

  inline
  bool equals(VM vm, Self right);

  inline
  int compareFeatures(VM vm, Self right);

public:
  // AtomLike interface

  OpResult isAtom(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

public:
  // Comparable interface

  inline
  OpResult compare(Self self, VM vm, RichNode right, int& result);

public:
  // VirtualString inteface
  OpResult isVirtualString(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult toString(Self self, VM vm, std::basic_ostream<nchar>& sink);

  inline
  OpResult vsLength(Self self, VM vm, nativeint& result);

  inline
  OpResult vsChangeSign(Self self, VM vm,
                        RichNode replacement, UnstableNode& result);

public:
  // Miscellaneous

  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  const AtomImpl* _value;
};

#ifndef MOZART_GENERATOR
#include "Atom-implem-decl-after.hh"
#endif

}

#endif // __ATOM_DECL_H
