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

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

///////////
// Tuple //
///////////

#include "Tuple-implem.hh"

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
                                      GR gr, Self from) {
  _width = width;
  gr->copyStableNode(_label, from->_label);

  for (size_t i = 0; i < width; i++)
    gr->copyStableNode(_elements[i], from[i]);
}

StableNode* Implementation<Tuple>::getElement(Self self, size_t index) {
  return &self[index];
}

bool Implementation<Tuple>::equals(Self self, VM vm, Self right,
                                   WalkStack& stack) {
  if (_width != right->_width)
    return false;

  stack.pushArray(vm, self.getArray(), right.getArray(), _width);
  stack.push(vm, &_label, &right->_label);

  return true;
}

OpResult Implementation<Tuple>::label(Self self, VM vm,
                                      UnstableNode* result) {
  result->copy(vm, _label);
  return OpResult::proceed();
}

OpResult Implementation<Tuple>::width(Self self, VM vm,
                                      UnstableNode* result) {
  result->make<SmallInt>(vm, _width);
  return OpResult::proceed();
}

OpResult Implementation<Tuple>::initElement(Self self, VM vm,
                                            size_t index,
                                            UnstableNode* value) {
  self[index].init(vm, *value);
  return OpResult::proceed();
}

OpResult Implementation<Tuple>::dot(Self self, VM vm,
                                    UnstableNode* feature,
                                    UnstableNode* result) {
  nativeint featureIntValue = 0;
  MOZART_GET_ARG(featureIntValue, *feature, u"integer");

  return dotNumber(self, vm, featureIntValue, result);
}

OpResult Implementation<Tuple>::dotNumber(Self self, VM vm,
                                          nativeint feature,
                                          UnstableNode* result) {
  if ((feature > 0) && ((size_t) feature <= _width)) {
    // Inside bounds
    result->copy(vm, self[(size_t) feature - 1]);
    return OpResult::proceed();
  } else {
    // Out of bounds
    return raise(vm, u"illegalFieldSelection", self, feature);
  }
}

OpResult Implementation<Tuple>::waitOr(Self self, VM vm,
                                       UnstableNode* result) {
  // If there is a field which is bound, then return its feature
  for (size_t i = 0; i < _width; i++) {
    UnstableNode field(vm, self[i]);
    if (!RichNode(field).isTransient()) {
      result->make<SmallInt>(vm, i+1);
      return OpResult::proceed();
    }
  }

  // Create the control variable
  UnstableNode unstableControlVar;
  unstableControlVar.make<Variable>(vm);
  RichNode controlVar = unstableControlVar;
  controlVar.getStableRef(vm);
  controlVar.update();

  // Add the control variable to the suspension list of all the fields
  for (size_t i = 0; i < _width; i++) {
    UnstableNode field(vm, self[i]);
    DataflowVariable(field).addToSuspendList(vm, controlVar);
  }

  // Wait for the control variable
  return OpResult::waitFor(vm, controlVar);
}

void Implementation<Tuple>::printReprToStream(Self self, VM vm,
                                              std::ostream& out, int depth) {
  out << repr(vm, _label, depth) << "(";

  if (depth <= 1) {
    out << "...";
  } else {
    for (size_t i = 0; i < _width; i++) {
      if (i > 0)
        out << ", ";
      out << repr(vm, self[i], depth);
    }
  }

  out << ")";
}

}

#endif // MOZART_GENERATOR

#endif // __RECORDS_H
