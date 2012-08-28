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

void Array::getValueAt(Self self, VM vm, nativeint feature,
                       UnstableNode& result) {
  result.copy(vm, self[indexToOffset(feature)]);
}

void Array::arrayLow(Self self, VM vm, UnstableNode& result) {
  result = SmallInt::build(vm, getLow());
}

void Array::arrayHigh(Self self, VM vm, UnstableNode& result) {
  result = SmallInt::build(vm, getHigh());
}

void Array::arrayGet(Self self, VM vm, RichNode index,
                     UnstableNode& result) {
  size_t offset = 0;
  getOffset(self, vm, index, offset);

  result.copy(vm, self[offset]);
}

void Array::arrayPut(Self self, VM vm, RichNode index, RichNode value) {
  if (!isHomedInCurrentSpace(vm))
    return raise(vm, MOZART_STR("globalState"), "array");

  size_t offset = 0;
  getOffset(self, vm, index, offset);

  self[offset].copy(vm, value);
}

void Array::arrayExchange(Self self, VM vm, RichNode index,
                          RichNode newValue, UnstableNode& oldValue) {
  if (!isHomedInCurrentSpace(vm))
    return raise(vm, MOZART_STR("globalState"), "array");

  size_t offset = 0;
  getOffset(self, vm, index, offset);

  oldValue.copy(vm, self[offset]);
  self[offset].copy(vm, newValue);
}

void Array::getOffset(Self self, VM vm, RichNode index, size_t& offset) {
  nativeint indexIntValue = 0;
  getArgument(vm, indexIntValue, index, MOZART_STR("integer"));

  if (!isIndexInRange(indexIntValue))
    return raise(vm, MOZART_STR("arrayIndexOutOfBounds"), self, index);

  offset = indexToOffset(indexIntValue);
}

void Array::printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
  out << "<Array " << getLow() << ".." << getHigh() << ">";
}

}

#endif // MOZART_GENERATOR

#endif // __ARRAY_H
