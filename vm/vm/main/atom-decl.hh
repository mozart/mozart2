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

#ifndef MOZART_GENERATOR
#include "Atom-implem-decl.hh"
#endif

class Atom: public DataType<Atom>, public LiteralHelper<Atom>,
  StoredAs<atom_t>, WithValueBehavior {
public:
  static constexpr UUID uuid = "{55ed333b-1eaf-4c8a-a151-626d3f96efe8}";

  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("atom"));
  }

  explicit Atom(atom_t value) : _value(value) {}

  static void create(atom_t& self, VM vm, std::size_t length,
                     const nchar* contents) {
    self = vm->getAtom(length, contents);
  }

  static void create(atom_t& self, VM vm, const nchar* contents) {
    self = vm->getAtom(contents);
  }

  static void create(atom_t& self, VM vm, atom_t value) {
    self = value;
  }

  inline
  static void create(atom_t& self, VM vm, GR gr, Atom from);

public:
  atom_t value() const {
    return _value;
  }

  inline
  bool equals(VM vm, RichNode right);

  inline
  int compareFeatures(VM vm, RichNode right);

public:
  // AtomLike interface

  bool isAtom(VM vm) {
    return true;
  }

public:
  // Comparable interface

  inline
  int compare(VM vm, RichNode right);

public:
  // Miscellaneous

  inline
  void printReprToStream(VM vm, std::ostream& out, int depth, int width);

private:
  atom_t _value;
};

#ifndef MOZART_GENERATOR
#include "Atom-implem-decl-after.hh"
#endif

}

#endif // __ATOM_DECL_H
