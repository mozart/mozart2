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

#ifndef __RECORDS_H
#define __RECORDS_H

#include "records-decl.hh"

#include "coreinterfaces.hh"
#include "smallint.hh"
#include "boolean.hh"
#include "corebuiltins.hh"

namespace mozart {

//////////////////
// Inline Tuple //
//////////////////

#ifndef MOZART_GENERATOR
#include "Tuple-implem.hh"
#endif

Implementation<Tuple>::Implementation(VM vm, size_t width,
                                      StaticArray<StableNode> _elements,
                                      UnstableNode* label) {
  _label.init(vm, *label);
  _width = width;

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < width; i++)
    _elements[i].make<SmallInt>(vm, 0);
}

Implementation<Tuple>::Implementation(VM vm, size_t width,
                                      StaticArray<StableNode> _elements,
                                      GC gc, Self from) {
  _width = width;
  gc->gcStableNode(from->_label, _label);

  for (size_t i = 0; i < width; i++)
    gc->gcStableNode(from[i], _elements[i]);
}

BuiltinResult Implementation<Tuple>::width(Self self, VM vm,
                                           UnstableNode* result) {
  result->make<SmallInt>(vm, _width);
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Tuple>::initElement(Self self, VM vm,
                                                 size_t index,
                                                 UnstableNode* value) {
  self[index].init(vm, *value);
  return BuiltinResult::proceed();
}

BuiltinResult Implementation<Tuple>::dot(Self self, VM vm,
                                         UnstableNode* feature,
                                         UnstableNode* result) {
  nativeint featureIntValue = 0;
  IntegerValue featureValue = *feature;

  BuiltinResult res = featureValue.intValue(vm, &featureIntValue);
  if (!res.isProceed())
    return res;

  return dotNumber(self, vm, featureIntValue, result);
}

BuiltinResult Implementation<Tuple>::dotNumber(Self self, VM vm,
                                               nativeint feature,
                                               UnstableNode* result) {
  if ((feature > 0) && ((size_t) feature <= _width)) {
    // Inside bounds
    result->copy(vm, self[(size_t) feature - 1]);
    return BuiltinResult::proceed();
  } else {
    // Out of bounds
    return raiseAtom(vm, u"illegalFieldSelection");
  }
}

void Implementation<Tuple>::printReprToStream(Self self, VM vm,
                                              std::ostream* _out, int depth) {
  std::ostream& out = *_out;

  UnstableNode label(vm, _label);
  builtins::printReprToStream(vm, label, out, depth-1);
  out << "(";

  if (depth <= 1) {
    out << "...";
  } else {
    for (size_t i = 0; i < _width; i++) {
      if (i > 0)
        out << ", ";

      UnstableNode element(vm, self[i]);
      builtins::printReprToStream(vm, element, out, depth-1);
    }
  }

  out << ")";
}

}

#endif // __RECORDS_H
