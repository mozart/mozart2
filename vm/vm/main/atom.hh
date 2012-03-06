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

#ifndef MOZART_GENERATOR
#include "Atom-implem.hh"
#endif

AtomImpl* Implementation<Atom>::build(VM vm, GC gc, SelfReadOnlyView from) {
  return build(vm, from.get().value()->size, from.get().value()->data);
}

BuiltinResult Implementation<Atom>::equals(Self self, VM vm,
					   UnstableNode* right,
					   UnstableNode* result) {
  Node& rightNode = Reference::dereference(right->node);

  if (rightNode.type == Atom::type()) {
    const AtomImpl* r = IMPLNOSELF(const AtomImpl*, Atom, value, &rightNode);
    result->make<Boolean>(vm, value()==r);
    return BuiltinResult::proceed();
  } else if (rightNode.type->isTransient()) {
    return BuiltinResult::waitFor(&rightNode);
  } else {
    // TODO Atom == non-Atom
    result->make<Boolean>(vm, false);
    return BuiltinResult::proceed();
  }
}

#endif // __ATOM_H
