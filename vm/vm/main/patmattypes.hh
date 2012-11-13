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

void PatMatCapture::create(nativeint& self, VM vm, GR gr, PatMatCapture from) {
  self = from.index();
}

bool PatMatCapture::equals(VM vm, RichNode right) {
  return index() == right.as<PatMatCapture>().index();
}

void PatMatCapture::printReprToStream(VM vm, std::ostream& out, int depth) {
  out << "<Capture/" << index() << ">";
}

///////////////////////
// PatMatConjunction //
///////////////////////

#include "PatMatConjunction-implem.hh"

PatMatConjunction::PatMatConjunction(VM vm, size_t count) {
  _count = count;

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < count; i++)
    getElements(i).init(vm);
}

PatMatConjunction::PatMatConjunction(VM vm, size_t count, GR gr,
                                     PatMatConjunction& from) {
  _count = count;

  gr->copyStableNodes(getElementsArray(), from.getElementsArray(), count);
}

StableNode* PatMatConjunction::getElement(size_t index) {
  return &getElements(index);
}

bool PatMatConjunction::equals(VM vm, RichNode right, WalkStack& stack) {
  auto rhs = right.as<PatMatConjunction>();

  if (getCount() != rhs.getCount())
    return false;

  stack.pushArray(vm, getElementsArray(), rhs.getElementsArray(), getCount());

  return true;
}

void PatMatConjunction::printReprToStream(VM vm, std::ostream& out, int depth) {
  out << "<PatMatConjunction>(";

  if (depth <= 1) {
    out << "...";
  } else {
    for (size_t i = 0; i < _count; i++) {
      if (i > 0)
        out << ", ";
      out << repr(vm, getElements(i), depth);
    }
  }

  out << ")";
}

//////////////////////
// PatMatOpenRecord //
//////////////////////

#include "PatMatOpenRecord-implem.hh"

template <typename A>
PatMatOpenRecord::PatMatOpenRecord(VM vm, size_t width, A&& arity) {
  _arity.init(vm, std::forward<A>(arity));
  _width = width;

  assert(RichNode(_arity).is<Arity>());

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < width; i++)
    getElements(i).init(vm);
}

PatMatOpenRecord::PatMatOpenRecord(VM vm, size_t width, GR gr,
                                   PatMatOpenRecord& from) {
  gr->copyStableNode(_arity, from._arity);
  _width = width;

  gr->copyStableNodes(getElementsArray(), from.getElementsArray(), width);
}

StableNode* PatMatOpenRecord::getElement(size_t index) {
  return &getElements(index);
}

void PatMatOpenRecord::printReprToStream(VM vm, std::ostream& out, int depth) {
  auto arity = RichNode(_arity).as<Arity>();

  out << "<PatMatOpenRecord " << repr(vm, *arity.getLabel(), depth) << "(";

  for (size_t i = 0; i < _width; i++) {
    out << repr(vm, *arity.getElement(i), depth) << ":";
    out << repr(vm, getElements(i), depth) << " ";
  }

  out << "...)>";
}

}

#endif // MOZART_GENERATOR

#endif // __PATMATTYPES_H
