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

#ifndef __PATMATTYPES_H
#define __PATMATTYPES_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

///////////////////
// PatMatCapture //
///////////////////

#include "PatMatCapture-implem.hh"

void PatMatCapture::create(nativeint& self, VM vm, GR gr, Self from) {
  self = from.get().index();
}

bool PatMatCapture::equals(VM vm, Self right) {
  return index() == right.get().index();
}

void PatMatCapture::printReprToStream(Self self, VM vm, std::ostream& out,
                                      int depth) {
  out << "<Capture/" << index() << ">";
}

///////////////////////
// PatMatConjunction //
///////////////////////

#include "PatMatConjunction-implem.hh"

PatMatConjunction::PatMatConjunction(VM vm, size_t count,
                                     StaticArray<StableNode> _elements) {
  _count = count;

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < count; i++)
    _elements[i].init(vm);
}

PatMatConjunction::PatMatConjunction(VM vm, size_t count,
                                     StaticArray<StableNode> _elements,
                                     GR gr, Self from) {
  _count = count;

  for (size_t i = 0; i < count; i++)
    gr->copyStableNode(_elements[i], from[i]);
}

StableNode* PatMatConjunction::getElement(Self self, size_t index) {
  return &self[index];
}

StaticArray<StableNode> PatMatConjunction::getElementsArray(Self self) {
  return self.getArray();
}

bool PatMatConjunction::equals(Self self, VM vm, Self right, WalkStack& stack) {
  if (_count != right->_count)
    return false;

  stack.pushArray(vm, self.getArray(), right.getArray(), _count);

  return true;
}

void PatMatConjunction::printReprToStream(Self self, VM vm, std::ostream& out,
                                          int depth) {
  out << "<PatMatConjunction>(";

  if (depth <= 1) {
    out << "...";
  } else {
    for (size_t i = 0; i < _count; i++) {
      if (i > 0)
        out << ", ";
      out << repr(vm, self[i], depth);
    }
  }

  out << ")";
}

//////////////////////
// PatMatOpenRecord //
//////////////////////

#include "PatMatOpenRecord-implem.hh"

template <typename A>
PatMatOpenRecord::PatMatOpenRecord(VM vm, size_t width,
                                   StaticArray<StableNode> _elements,
                                   A&& arity) {
  _arity.init(vm, std::forward<A>(arity));
  _width = width;

  assert(RichNode(_arity).is<Arity>());

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < width; i++)
    _elements[i].init(vm);
}

PatMatOpenRecord::PatMatOpenRecord(VM vm, size_t width,
                                   StaticArray<StableNode> _elements,
                                   GR gr, Self from) {
  gr->copyStableNode(_arity, from->_arity);
  _width = width;

  for (size_t i = 0; i < width; i++)
    gr->copyStableNode(_elements[i], from[i]);
}

StableNode* PatMatOpenRecord::getElement(Self self, size_t index) {
  return &self[index];
}

StaticArray<StableNode> PatMatOpenRecord::getElementsArray(Self self) {
  return self.getArray();
}

void PatMatOpenRecord::printReprToStream(Self self, VM vm, std::ostream& out,
                                         int depth) {
  auto arity = RichNode(_arity).as<Arity>();

  out << "<PatMatOpenRecord " << repr(vm, *arity.getLabel(), depth) << "(";

  for (size_t i = 0; i < _width; i++) {
    out << repr(vm, *arity.getElement(i), depth) << ":";
    out << repr(vm, self[i], depth) << " ";
  }

  out << "...)>";
}

}

#endif // MOZART_GENERATOR

#endif // __PATMATTYPES_H
