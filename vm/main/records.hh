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
OpResult BaseRecord<T>::width(Self self, VM vm, size_t& result) {
  result = getWidth();
  return OpResult::proceed();
}

template <class T>
OpResult BaseRecord<T>::arityList(Self self, VM vm,
                                  UnstableNode& result) {
  UnstableNode res = trivialBuild(vm, vm->coreatoms.nil);

  for (size_t i = getWidth(); i > 0; i--) {
    UnstableNode feature;
    static_cast<Implementation<T>*>(this)->getFeatureAt(self, vm, i-1, feature);

    UnstableNode temp = buildCons(vm, std::move(feature), std::move(res));
    res = std::move(temp);
  }

  result = std::move(res);
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

void Implementation<Tuple>::getValueAt(Self self, VM vm,
                                       nativeint feature,
                                       UnstableNode& result) {
  result.copy(vm, self[(size_t) feature - 1]);
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

OpResult Implementation<Tuple>::clone(Self self, VM vm,
                                      UnstableNode& result) {
  UnstableNode tempLabel(vm, _label);
  result.make<Tuple>(vm, _width, tempLabel);

  auto tuple = RichNode(result).as<Tuple>();
  for (size_t i = 0; i < _width; i++)
    tuple.getElement(i)->make<Unbound>(vm);

  return OpResult::proceed();
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
// Cons //
///////////

#include "Cons-implem.hh"

Implementation<Cons>::Implementation(VM vm, RichNode head, RichNode tail) {
  _head.init(vm, head);
  _tail.init(vm, tail);
}

Implementation<Cons>::Implementation(VM vm, GR gr, Self from) {
  gr->copyStableNode(_head, from->_head);
  gr->copyStableNode(_tail, from->_tail);
}

bool Implementation<Cons>::equals(Self self, VM vm, Self right,
                                  WalkStack& stack) {
  stack.push(vm, &_tail, &right->_tail);
  stack.push(vm, &_head, &right->_head);

  return true;
}

void Implementation<Cons>::getValueAt(Self self, VM vm,
                                      nativeint feature,
                                      UnstableNode& result) {
  if (feature == 1)
    result.copy(vm, _head);
  else
    result.copy(vm, _tail);
}

OpResult Implementation<Cons>::label(Self self, VM vm,
                                     UnstableNode& result) {
  result = Atom::build(vm, vm->coreatoms.pipe);
  return OpResult::proceed();
}

OpResult Implementation<Cons>::width(Self self, VM vm, size_t& result) {
  result = 2;
  return OpResult::proceed();
}

OpResult Implementation<Cons>::arityList(Self self, VM vm,
                                         UnstableNode& result) {
  result = buildCons(vm, 1, buildCons(vm, 2, vm->coreatoms.nil));
  return OpResult::proceed();
}

OpResult Implementation<Cons>::clone(Self self, VM vm,
                                     UnstableNode& result) {
  result = buildCons(vm, Unbound::build(vm), Unbound::build(vm));
  return OpResult::proceed();
}

OpResult Implementation<Cons>::waitOr(Self self, VM vm,
                                      UnstableNode& result) {
  UnstableNode tempHead(vm, _head);
  UnstableNode tempTail(vm, _tail);

  RichNode head = tempHead;
  RichNode tail = tempTail;

  // If there is a field which is bound, then return its feature
  if (!head.isTransient()) {
    result = SmallInt::build(vm, 1);
    return OpResult::proceed();
  } else if (!tail.isTransient()) {
    result = SmallInt::build(vm, 2);
    return OpResult::proceed();
  }

  // Create the control variable
  UnstableNode unstableControlVar = Variable::build(vm);
  RichNode controlVar = unstableControlVar;
  controlVar.ensureStable(vm);

  // Add the control variable to the suspension list of both fields
  DataflowVariable(head).addToSuspendList(vm, controlVar);
  DataflowVariable(tail).addToSuspendList(vm, controlVar);

  // Wait for the control variable
  return OpResult::waitFor(vm, controlVar);
}

void Implementation<Cons>::printReprToStream(Self self, VM vm,
                                             std::ostream& out, int depth) {
  out << repr(vm, _head, depth) << "|" << repr(vm, _tail, depth);
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

OpResult Implementation<Arity>::lookupFeature(VM vm, RichNode feature,
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

  return OpResult::fail();
}

OpResult Implementation<Arity>::requireFeature(VM vm, RichNode container,
                                               RichNode feature,
                                               size_t& result) {
  OpResult res = lookupFeature(vm, feature, result);

  if (res.kind() == OpResult::orFail)
    return raise(vm, vm->coreatoms.illegalFieldSelection, container, feature);
  else
    return res;
}

OpResult Implementation<Arity>::hasFeature(VM vm, RichNode feature,
                                           bool& result) {
  size_t dummy;
  return lookupFeature(vm, feature, dummy).mapProceedFailToTrueFalse(result);
}

void Implementation<Arity>::getFeatureAt(Self self, VM vm, size_t index,
                                         UnstableNode& result) {
  UnstableNode tempTuple(vm, _tuple);
  MOZART_ASSERT_PROCEED(RichNode(tempTuple).as<Tuple>().dotNumber(
    vm, index+1, result));
}

void Implementation<Arity>::printReprToStream(Self self, VM vm,
                                              std::ostream& out, int depth) {
  out << "<Arity/" << repr(vm, _tuple, depth) << ">";
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

OpResult Implementation<Record>::clone(Self self, VM vm,
                                       UnstableNode& result) {
  UnstableNode tempArity(vm, _arity);
  result.make<Record>(vm, _width, tempArity);

  auto record = RichNode(result).as<Record>();
  for (size_t i = 0; i < _width; i++)
    record.getElement(i)->make<Unbound>(vm);

  return OpResult::proceed();
}

OpResult Implementation<Record>::dot(Self self, VM vm,
                                     RichNode feature, UnstableNode& result) {
  UnstableNode temp(vm, _arity);

  size_t index = 0;
  MOZART_CHECK_OPRESULT(RichNode(temp).as<Arity>().requireFeature(
    vm, self, feature, index));

  result.copy(vm, self[index]);
  return OpResult::proceed();
}

OpResult Implementation<Record>::hasFeature(Self self, VM vm, RichNode feature,
                                            bool& result) {
  UnstableNode temp(vm, _arity);
  return RichNode(temp).as<Arity>().hasFeature(vm, feature, result);
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

///////////
// Chunk //
///////////

#include "Chunk-implem.hh"

void Implementation<Chunk>::build(StableNode*& self, VM vm, GR gr, Self from) {
  gr->copyStableRef(self, from.get().getUnderlying());
}

OpResult Implementation<Chunk>::dot(Self self, VM vm,
                                    RichNode feature, UnstableNode& result) {
  UnstableNode underlying(vm, *_underlying);
  return Dottable(underlying).dot(vm, feature, result);
}

OpResult Implementation<Chunk>::hasFeature(Self self, VM vm, RichNode feature,
                                           bool& result) {
  UnstableNode underlying(vm, *_underlying);
  return Dottable(underlying).hasFeature(vm, feature, result);
}

}

#endif // MOZART_GENERATOR

#endif // __RECORDS_H
