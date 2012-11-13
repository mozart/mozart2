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

#ifndef __UNIT_DECL_H
#define __UNIT_DECL_H

#include "mozartcore-decl.hh"

#include "datatypeshelpers-decl.hh"

namespace mozart {

#ifndef MOZART_GENERATOR
#include "Unit-implem-decl.hh"
#endif

class Unit: public DataType<Unit>, public LiteralHelper<Unit>,
  StoredAs<unit_t>, WithValueBehavior {
public:
  constexpr static UUID uuid = "{f08642c3-5b42-4f7f-889f-9f43286973b7}";

  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("name")); // compatibility with Mozart 1.4.0
  }

  explicit Unit(unit_t value) {}

  static void create(unit_t& self, VM vm) {
  }

  inline
  static void create(unit_t& self, VM vm, GR gr, Unit from);

public:
  inline
  bool equals(VM vm, RichNode right);

  inline
  int compareFeatures(VM vm, RichNode right);

public:
  // VirtualString inteface

  bool isVirtualString(VM vm) {
    return true;
  }

  inline
  void toString(VM vm, std::basic_ostream<nchar>& sink);

  inline
  nativeint vsLength(VM vm);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth) {
    out << "unit";
  }
};

#ifndef MOZART_GENERATOR
#include "Unit-implem-decl-after.hh"
#endif

}

#endif // __UNIT_DECL_H
