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

#ifndef __ATOM_H
#define __ATOM_H

#include "atom-decl.hh"

#include "boolean.hh"
#include "variables.hh"

namespace mozart {

#ifndef MOZART_GENERATOR
#include "Atom-implem.hh"
#endif

AtomImpl* Implementation<Atom>::build(VM vm, GC gc, Self from) {
  const AtomImpl* fromValue = from.get().value();
  return build(vm, fromValue->length(), fromValue->contents());
}

bool Implementation<Atom>::equals(VM vm, Self right) {
  return value() == right.get().value();
}

BuiltinResult Implementation<Atom>::label(Self self, VM vm,
                                          UnstableNode* result) {
  result->copy(vm, self);
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Atom>::width(Self self, VM vm,
                                          UnstableNode* result) {
  result->make<SmallInt>(vm, 0);
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Atom>::dot(Self self, VM vm,
                                        UnstableNode* feature,
                                        UnstableNode* result) {
  // Always out of bounds
  return raise(vm, u"illegalFieldSelection", self, *feature);
}

BuiltinResult Implementation<Atom>::dotNumber(Self self, VM vm,
                                              nativeint feature,
                                              UnstableNode* result) {
  // Always out of bounds
  return raise(vm, u"illegalFieldSelection", self, feature);
}

BuiltinResult Implementation<Atom>::waitOr(Self self, VM vm,
                                           UnstableNode* result) {
  // Wait forever
  UnstableNode dummyVar = UnstableNode::build<Variable>(vm);
  return BuiltinResult::waitFor(vm, dummyVar);
}

void Implementation<Atom>::printReprToStream(Self self, VM vm,
                                             std::ostream* _out, int depth) {
  std::ostream& out = *_out;

  out << "'";
  for (size_t i = 0; i < value()->length(); i++)
    out << (char) value()->contents()[i];
  out << "'";
}

}

#endif // __ATOM_H
