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

#ifndef __NAMES_DECL_H
#define __NAMES_DECL_H

#include "mozartcore-decl.hh"

#include "datatypeshelpers-decl.hh"

namespace mozart {

/////////////
// OptName //
/////////////

#ifndef MOZART_GENERATOR
#include "OptName-implem-decl.hh"
#endif

class OptName: public DataType<OptName>, public WithHome,
  public LiteralHelper<OptName>, StoredAs<SpaceRef> {
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("name"));
  }

  OptName(SpaceRef home): WithHome(home) {}

  static void create(SpaceRef& self, VM vm) {
    self = vm->getCurrentSpace();
  }

  inline
  static void create(SpaceRef& self, VM vm, GR gr, Self from);

public:
  // PotentialFeature interface

  inline
  void makeFeature(Self self, VM vm);

public:
  // NameLike interface

  bool isName(Self self, VM vm) {
    return true;
  }

public:
  // Miscellaneous

  void printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
    out << "<OptName>";
  }
};

#ifndef MOZART_GENERATOR
#include "OptName-implem-decl-after.hh"
#endif

////////////////
// GlobalName //
////////////////

#ifndef MOZART_GENERATOR
#include "GlobalName-implem-decl.hh"
#endif

class GlobalName: public DataType<GlobalName>, public WithHome,
  public LiteralHelper<GlobalName> {
public:
  static constexpr UUID uuid = "{3330919d-1e2f-41a4-a073-620dd36dd582}";

  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("name"));
  }

  GlobalName(VM vm, UUID uuid): WithHome(vm), _uuid(uuid) {}

  GlobalName(VM vm): WithHome(vm), _uuid(vm->genUUID()) {}

  inline
  GlobalName(VM vm, GR gr, Self from);

public:
  const UUID& getUUID() {
    return _uuid;
  }

  inline
  int compareFeatures(VM vm, Self right);

public:
  // NameLike interface

  bool isName(Self self, VM vm) {
    return true;
  }

public:
  // Miscellaneous

  void printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
    out << "<Name>";
  }

private:
  UUID _uuid;
};

#ifndef MOZART_GENERATOR
#include "GlobalName-implem-decl-after.hh"
#endif

///////////////
// NamedName //
///////////////

#ifndef MOZART_GENERATOR
#include "NamedName-implem-decl.hh"
#endif

class NamedName: public DataType<NamedName>, public WithHome,
  public LiteralHelper<NamedName> {
public:
  static constexpr UUID uuid = "{f9873e5a-65db-4894-9dd5-bcd276df14af}";

  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("name"));
  }

  NamedName(VM vm, RichNode printName, UUID uuid):
    WithHome(vm), _uuid(uuid) {
    _printName.init(vm, printName);
  }

  NamedName(VM vm, RichNode printName):
    WithHome(vm), _uuid(vm->genUUID()) {
    _printName.init(vm, printName);
  }

  inline
  NamedName(VM vm, GR gr, Self from);

public:
  const UUID& getUUID() {
    return _uuid;
  }

  inline
  int compareFeatures(VM vm, Self right);

public:
  // NameLike interface

  bool isName(Self self, VM vm) {
    return true;
  }

public:
  // Miscellaneous

  void printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
    out << "<Name/" << repr(vm, _printName) << ">";
  }

private:
  StableNode _printName;
  UUID _uuid;
};

#ifndef MOZART_GENERATOR
#include "NamedName-implem-decl-after.hh"
#endif

////////////////
// UniqueName //
////////////////

#ifndef MOZART_GENERATOR
#include "UniqueName-implem-decl.hh"
#endif

class UniqueName: public DataType<UniqueName>, public LiteralHelper<UniqueName>,
  StoredAs<unique_name_t>, WithValueBehavior {
public:
  static constexpr UUID uuid = "{f6cdb080-98ad-47bf-9e67-629385261e9f}";

  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("name"));
  }

  UniqueName(unique_name_t value) : _value(value) {}

  static void create(unique_name_t& self, VM vm, unique_name_t value) {
    self = value;
  }

  inline
  static void create(unique_name_t& self, VM vm, GR gr, Self from);

public:
  unique_name_t value() const {
    return _value;
  }

  inline
  bool equals(VM vm, Self right);

  inline
  int compareFeatures(VM vm, Self right);

public:
  // NameLike interface

  bool isName(Self self, VM vm) {
    return true;
  }

public:
  // Miscellaneous

  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  unique_name_t _value;
};

#ifndef MOZART_GENERATOR
#include "UniqueName-implem-decl-after.hh"
#endif

}

#endif // __NAMES_DECL_H
