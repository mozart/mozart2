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

#ifndef __ARRAY_H
#define __ARRAY_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

///////////
// Array //
///////////

#include "Array-implem.hh"

Array::Array(VM vm, size_t width, StaticArray<UnstableNode> _elements,
             nativeint low, RichNode initValue):
  WithHome(vm) {

  _width = width;
  _low = low;

  for (size_t i = 0; i < width; i++)
    _elements[i].init(vm, initValue);
}

Array::Array(VM vm, size_t width, StaticArray<UnstableNode> _elements,
             GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  _width = width;
  _low = from->_low;

  for (size_t i = 0; i < width; i++)
    gr->copyUnstableNode(_elements[i], from[i]);
}

UnstableNode Array::getValueAt(Self self, VM vm, nativeint feature) {
  return { vm, self[indexToOffset(feature)] };
}

UnstableNode Array::arrayLow(Self self, VM vm) {
  return mozart::build(vm, getLow());
}

UnstableNode Array::arrayHigh(Self self, VM vm) {
  return mozart::build(vm, getHigh());
}

UnstableNode Array::arrayGet(Self self, VM vm, RichNode index) {
  return { vm, self[getOffset(self, vm, index)] };
}

void Array::arrayPut(Self self, VM vm, RichNode index, RichNode value) {
  if (!isHomedInCurrentSpace(vm))
    raise(vm, MOZART_STR("globalState"), MOZART_STR("array"));

  self[getOffset(self, vm, index)].copy(vm, value);
}

UnstableNode Array::arrayExchange(Self self, VM vm, RichNode index,
                                  RichNode newValue) {
  if (!isHomedInCurrentSpace(vm))
    raise(vm, MOZART_STR("globalState"), MOZART_STR("array"));

  size_t offset = getOffset(self, vm, index);

  auto oldValue = std::move(self[offset]);
  self[offset].copy(vm, newValue);
  return oldValue;
}

size_t Array::getOffset(Self self, VM vm, RichNode index) {
  auto indexIntValue = getArgument<nativeint>(vm, index, MOZART_STR("integer"));

  if (!isIndexInRange(indexIntValue))
    raise(vm, MOZART_STR("arrayIndexOutOfBounds"), self, index);

  return indexToOffset(indexIntValue);
}

void Array::printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
  out << "<Array " << getLow() << ".." << getHigh() << ">";
}

}

#endif // MOZART_GENERATOR

#endif // __ARRAY_H
