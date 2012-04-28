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

////////////////
// BaseRecord //
////////////////

template <class T>
StableNode* BaseRecord<T>::getElement(Self self, size_t index) {
  return &self[index];
}

template <class T>
OpResult BaseRecord<T>::width(Self self, VM vm,
                              UnstableNode& result) {
  result.make<SmallInt>(vm, getWidth());
  return OpResult::proceed();
}

template <class T>
OpResult BaseRecord<T>::initElement(Self self, VM vm,
                                    size_t index, RichNode value) {
  self[index].init(vm, value);
  return OpResult::proceed();
}

template <class T>
OpResult BaseRecord<T>::waitOr(Self self, VM vm,
                               UnstableNode& result) {
  // If there is a field which is bound, then return its feature
  for (size_t i = 0; i < getArraySize(); i++) {
    UnstableNode field(vm, self[i]);
    if (!RichNode(field).isTransient()) {
      static_cast<Implementation<T>*>(this)->getFeatureAt(self, vm, i, result);
      return OpResult::proceed();
    }
  }

  // Create the control variable
  UnstableNode unstableControlVar = Variable::build(vm);
  RichNode controlVar = unstableControlVar;
  controlVar.ensureStable(vm);

  // Add the control variable to the suspension list of all the fields
  for (size_t i = 0; i < getArraySize(); i++) {
    UnstableNode field(vm, self[i]);
    DataflowVariable(field).addToSuspendList(vm, controlVar);
  }

  // Wait for the control variable
  return OpResult::waitFor(vm, controlVar);
}

///////////
// Tuple //
///////////

#include "Tuple-implem.hh"

Implementation<Tuple>::Implementation(VM vm, size_t width,
                                      StaticArray<StableNode> _elements,
                                      RichNode label) {
  _label.init(vm, label);
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

bool Implementation<Tuple>::equals(Self self, VM vm, Self right,
                                   WalkStack& stack) {
  if (_width != right->_width)
    return false;

  stack.pushArray(vm, self.getArray(), right.getArray(), _width);
  stack.push(vm, &_label, &right->_label);

  return true;
}

void Implementation<Tuple>::getFeatureAt(Self self, VM vm, size_t index,
                                         UnstableNode& result) {
  result = SmallInt::build(vm, index+1);
}

OpResult Implementation<Tuple>::label(Self self, VM vm,
                                      UnstableNode& result) {
  result.copy(vm, _label);
  return OpResult::proceed();
}

OpResult Implementation<Tuple>::dot(Self self, VM vm,
                                    RichNode feature, UnstableNode& result) {
  using namespace patternmatching;

  OpResult res = OpResult::proceed();
  nativeint featureIntValue = 0;

  // Fast-path for the integer case
  if (matches(vm, res, feature, capture(featureIntValue))) {
    return dotNumber(self, vm, featureIntValue, result);
  } else {
    MOZART_REQUIRE_FEATURE(feature);
    return raise(vm, u"illegalFieldSelection", self, feature);
  }
}

OpResult Implementation<Tuple>::dotNumber(Self self, VM vm,
                                          nativeint feature,
                                          UnstableNode& result) {
  if ((feature > 0) && ((size_t) feature <= _width)) {
    // Inside bounds
    result.copy(vm, self[(size_t) feature - 1]);
    return OpResult::proceed();
  } else {
    // Out of bounds
    return raise(vm, u"illegalFieldSelection", self, feature);
  }
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

///////////
// Arity //
///////////

#include "Arity-implem.hh"

Implementation<Arity>::Implementation(VM vm, RichNode tuple) {
  assert(tuple.is<Tuple>());

  _tuple.init(vm, tuple);
}

Implementation<Arity>::Implementation(VM vm, GR gr, Self from) {
  gr->copyStableNode(_tuple, from->_tuple);
}

bool Implementation<Arity>::equals(Self self, VM vm, Self right,
                                   WalkStack& stack) {
  stack.push(vm, &_tuple, &right->_tuple);

  return true;
}

OpResult Implementation<Arity>::label(Self self, VM vm,
                                      UnstableNode& result) {
  UnstableNode temp(vm, _tuple);
  return RichNode(temp).as<Tuple>().label(vm, result);
}

OpResult Implementation<Arity>::lookupFeature(VM vm, RichNode record,
                                              RichNode feature,
                                              size_t& result) {
  MOZART_REQUIRE_FEATURE(feature);

  UnstableNode tempTuple(vm, _tuple);
  auto tuple = RichNode(tempTuple).as<Tuple>();

  // Dichotomic search
  size_t lo = 0;
  size_t hi = tuple.getArraySize();

  while (lo < hi) {
    size_t mid = (lo + hi) / 2; // no need to worry about overflow, here
    UnstableNode temp(vm, *tuple.getElement(mid));
    int comparison = compareFeatures(vm, feature, temp);

    if (comparison == 0) {
      result = mid;
      return OpResult::proceed();
    } else if (comparison < 0) {
      hi = mid;
    } else {
      lo = mid+1;
    }
  }

  return raise(vm, u"illegalFieldSelection", record, feature);
}

void Implementation<Arity>::getFeatureAt(Self self, VM vm, size_t index,
                                         UnstableNode& result) {
  UnstableNode tempTuple(vm, _tuple);
  MOZART_ASSERT_PROCEED(RichNode(tempTuple).as<Tuple>().dotNumber(
    vm, index+1, result));
}

void Implementation<Arity>::printReprToStream(Self self, VM vm,
                                              std::ostream& out, int depth) {
  UnstableNode label;
  out << "<Arity/" << repr(vm, label, depth) << ">";
}

////////////
// Record //
////////////

#include "Record-implem.hh"

Implementation<Record>::Implementation(VM vm, size_t width,
                                       StaticArray<StableNode> _elements,
                                       RichNode arity) {
  assert(arity.is<Arity>());

  _arity.init(vm, arity);
  _width = width;

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < width; i++)
    _elements[i].make<SmallInt>(vm, 0);
}

Implementation<Record>::Implementation(VM vm, size_t width,
                                       StaticArray<StableNode> _elements,
                                       GR gr, Self from) {
  gr->copyStableNode(_arity, from->_arity);
  _width = width;

  for (size_t i = 0; i < width; i++)
    gr->copyStableNode(_elements[i], from[i]);
}

bool Implementation<Record>::equals(Self self, VM vm, Self right,
                                    WalkStack& stack) {
  if (_width != right->_width)
    return false;

  stack.pushArray(vm, self.getArray(), right.getArray(), _width);
  stack.push(vm, &_arity, &right->_arity);

  return true;
}

void Implementation<Record>::getFeatureAt(Self self, VM vm, size_t index,
                                          UnstableNode& result) {
  UnstableNode temp(vm, _arity);
  RichNode(temp).as<Arity>().getFeatureAt(vm, index, result);
}

OpResult Implementation<Record>::label(Self self, VM vm,
                                       UnstableNode& result) {
  UnstableNode temp(vm, _arity);
  return RichNode(temp).as<Arity>().label(vm, result);
}

OpResult Implementation<Record>::dot(Self self, VM vm,
                                     RichNode feature, UnstableNode& result) {
  UnstableNode temp(vm, _arity);

  size_t index = 0;
  MOZART_CHECK_OPRESULT(RichNode(temp).as<Arity>().lookupFeature(
    vm, self, feature, index));

  result.copy(vm, self[index]);
  return OpResult::proceed();
}

OpResult Implementation<Record>::dotNumber(Self self, VM vm,
                                           nativeint feature,
                                           UnstableNode& result) {
  UnstableNode featureNode = SmallInt::build(vm, feature);
  return dot(self, vm, featureNode, result);
}

void Implementation<Record>::printReprToStream(Self self, VM vm,
                                               std::ostream& out, int depth) {
  UnstableNode label;
  MOZART_ASSERT_PROCEED(this->label(self, vm, label));

  out << repr(vm, label, depth) << "(";

  if (depth <= 1) {
    out << "...";
  } else {
    for (size_t i = 0; i < _width; i++) {
      if (i > 0)
        out << ", ";

      UnstableNode feature;
      getFeatureAt(self, vm, i, feature);

      out << repr(vm, feature, depth) << ":" << repr(vm, self[i], depth);
    }
  }

  out << ")";
}

}

#endif // MOZART_GENERATOR

#endif // __RECORDS_H
