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

void OptName::create(SpaceRef& self, VM vm, GR gr, OptName from) {
  gr->copySpace(self, from.home());
}

void OptName::makeFeature(RichNode self, VM vm) {
  self.become(vm, GlobalName::build(vm));
}

GlobalNode* OptName::globalize(RichNode self, VM vm) {
  self.become(vm, GlobalName::build(vm));
  return self.as<GlobalName>().globalize(vm);
}

////////////////
// GlobalName //
////////////////

#include "GlobalName-implem.hh"

GlobalName::GlobalName(VM vm, GR gr, GlobalName& from):
  WithHome(vm, gr, from) {

  if (gr->kind() == GraphReplicator::grkSpaceCloning)
    _uuid = vm->genUUID();
  else
    _uuid = from._uuid;
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

GlobalNode* GlobalName::globalize(RichNode self, VM vm) {
  GlobalNode* result;
  if (!GlobalNode::get(vm, _uuid, result)) {
    result->self.init(vm, self);
    result->protocol.init(vm, MOZART_STR("immval"));
  }
  return result;
}

///////////////
// NamedName //
///////////////

#include "NamedName-implem.hh"

NamedName::NamedName(VM vm, GR gr, NamedName& from):
  WithHome(vm, gr, from) {

  _printName = vm->getAtom(from._printName.length(),
                           from._printName.contents());

  if (gr->kind() == GraphReplicator::grkSpaceCloning)
    _uuid = vm->genUUID();
  else
    _uuid = from._uuid;
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

atom_t NamedName::getPrintName(VM vm) {
  return _printName;
}

UnstableNode NamedName::serialize(VM vm, SE se) {
  return buildTuple(vm, MOZART_STR("namedname"), _printName);
}

GlobalNode* NamedName::globalize(RichNode self, VM vm) {
  GlobalNode* result;
  if (!GlobalNode::get(vm, _uuid, result)) {
    result->self.init(vm, self);
    result->protocol.init(vm, MOZART_STR("immval"));
  }
  return result;
}

////////////////
// UniqueName //
////////////////

#include "UniqueName-implem.hh"

void UniqueName::create(unique_name_t& self, VM vm, GR gr, UniqueName from) {
  unique_name_t fromValue = from.value();
  self = vm->getUniqueName(fromValue.length(), fromValue.contents());
}

bool UniqueName::equals(VM vm, RichNode right) {
  return value() == right.as<UniqueName>().value();
}

int UniqueName::compareFeatures(VM vm, RichNode right) {
  return value().compare(right.as<UniqueName>().value());
}

atom_t UniqueName::getPrintName(VM vm) {
  return atom_t(value());
}

UnstableNode UniqueName::serialize(VM vm, SE se) {
  return buildTuple(vm, MOZART_STR("uniquename"), atom_t(value()));
}

void UniqueName::printReprToStream(VM vm, std::ostream& out,
                                   int depth, int width) {
  out << value();
}

}

#endif // MOZART_GENERATOR

#endif // __NAMES_H
