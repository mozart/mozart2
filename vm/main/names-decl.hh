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

namespace mozart {

/////////////
// OptName //
/////////////

class OptName;

#ifndef MOZART_GENERATOR
#include "OptName-implem-decl.hh"
#endif

template <>
class Implementation<OptName>: public WithHome, StoredAs<SpaceRef> {
public:
  typedef SelfType<OptName>::Self Self;
public:
  Implementation(SpaceRef home): WithHome(home) {}

  static SpaceRef build(VM vm) {
    return vm->getCurrentSpace();
  }

  inline
  static SpaceRef build(VM vm, GR gr, Self from);

public:
  inline
  OpResult makeFeature(Self self, VM vm);

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

class GlobalName;

#ifndef MOZART_GENERATOR
#include "GlobalName-implem-decl.hh"
#endif

template <>
class Implementation<GlobalName>: public WithHome {
public:
  typedef SelfType<GlobalName>::Self Self;
public:
  static constexpr UUID uuid = "{3330919d-1e2f-41a4-a073-620dd36dd582}";

  Implementation(VM vm, UUID uuid): WithHome(vm), _uuid(uuid) {}

  Implementation(VM vm): WithHome(vm), _uuid(vm->genUUID()) {}

  inline
  Implementation(VM vm, GR gr, Self from);

public:
  const UUID& getUUID() {
    return _uuid;
  }

  inline
  int compareFeatures(VM vm, Self right);

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

}

#endif // __NAMES_DECL_H
