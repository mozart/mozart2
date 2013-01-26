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

#ifndef __BOOLEAN_DECL_H
#define __BOOLEAN_DECL_H

#include "mozartcore-decl.hh"

#include "datatypeshelpers-decl.hh"

namespace mozart {

#ifndef MOZART_GENERATOR
#include "Boolean-implem-decl.hh"
#endif

class Boolean: public DataType<Boolean>, public LiteralHelper<Boolean>,
  StoredAs<bool>, WithValueBehavior {
public:
  constexpr static UUID uuid = "{ce34f46e-4751-4f2d-b6fd-0522198a4810}";

  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("name")); // compatibility with Mozart 1.4.0
  }

  explicit Boolean(bool value) : _value(value) {}

  static void create(bool& self, VM, bool value) {
    self = value;
  }

  inline
  static void create(bool& self, VM vm, GR gr, Boolean from);

public:
  bool value() const { return _value; }

  inline
  bool equals(VM vm, RichNode right);

  inline
  int compareFeatures(VM vm, RichNode right);

public:
  // NameLike interface

  bool isName(VM vm) {
    return true;
  }

public:
  // Miscellaneous

  inline
  UnstableNode serialize(VM vm, SE se);

  void printReprToStream(VM vm, std::ostream& out, int depth, int width) {
    out << (value() ? "true" : "false");
  }

private:
  const bool _value;
};

#ifndef MOZART_GENERATOR
#include "Boolean-implem-decl-after.hh"
#endif

}

#endif // __BOOLEAN_DECL_H
