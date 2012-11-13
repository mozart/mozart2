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

#ifndef __NAMES_H
#define __NAMES_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

/////////////
// OptName //
/////////////

#include "OptName-implem.hh"

void OptName::create(SpaceRef& self, VM vm, GR gr, Self from) {
  gr->copySpace(self, from.get().home());
}

void OptName::makeFeature(RichNode self, VM vm) {
  self.become(vm, GlobalName::build(vm));
}

////////////////
// GlobalName //
////////////////

#include "GlobalName-implem.hh"

GlobalName::GlobalName(VM vm, GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  if (gr->kind() == GraphReplicator::grkSpaceCloning)
    _uuid = vm->genUUID();
  else
    _uuid = from->_uuid;
}

int GlobalName::compareFeatures(VM vm, RichNode right) {
  const UUID& rhsUUID = right.as<GlobalName>().getUUID();

  if (_uuid == rhsUUID)
    return 0;
  else if (_uuid < rhsUUID)
    return -1;
  else
    return 1;
}

///////////////
// NamedName //
///////////////

#include "NamedName-implem.hh"

NamedName::NamedName(VM vm, GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  gr->copyStableNode(_printName, from->_printName);

  if (gr->kind() == GraphReplicator::grkSpaceCloning)
    _uuid = vm->genUUID();
  else
    _uuid = from->_uuid;
}

int NamedName::compareFeatures(VM vm, RichNode right) {
  const UUID& rhsUUID = right.as<NamedName>().getUUID();

  if (_uuid == rhsUUID)
    return 0;
  else if (_uuid < rhsUUID)
    return -1;
  else
    return 1;
}

////////////////
// UniqueName //
////////////////

#include "UniqueName-implem.hh"

void UniqueName::create(unique_name_t& self, VM vm, GR gr, Self from) {
  unique_name_t fromValue = from.get().value();
  self = vm->getUniqueName(fromValue.length(), fromValue.contents());
}

bool UniqueName::equals(VM vm, RichNode right) {
  return value() == right.as<UniqueName>().value();
}

int UniqueName::compareFeatures(VM vm, RichNode right) {
  return value().compare(right.as<UniqueName>().value());
}

void UniqueName::printReprToStream(VM vm, std::ostream& out, int depth) {
  out << "<UniqueName '";
  out << toUTF<char>(makeLString(value().contents(), value().length()));
  out << "'>";
}

}

#endif // MOZART_GENERATOR

#endif // __NAMES_H
