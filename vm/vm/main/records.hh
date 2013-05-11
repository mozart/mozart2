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
StableNode* BaseRecord<T>::getElement(size_t index) {
  return &getThis()->getElementsArray()[index];
}

template <class T>
size_t BaseRecord<T>::width(VM vm) {
  return getWidth();
}

template <class T>
UnstableNode BaseRecord<T>::arityList(VM vm) {
  UnstableNode result = buildNil(vm);

  for (size_t i = getWidth(); i > 0; i--) {
    auto feature = getThis()->getFeatureAt(vm, i-1);

    UnstableNode temp = buildCons(vm, std::move(feature), std::move(result));
    result = std::move(temp);
  }

  return result;
}

template <class T>
UnstableNode BaseRecord<T>::waitOr(VM vm) {
  StaticArray<StableNode> elements = getThis()->getElementsArray();

  // If there is a field which is bound, then return its feature
  for (size_t i = 0; i < getWidth(); i++) {
    RichNode element = elements[i];
    if (!element.isTransient()) {
      return static_cast<T*>(this)->getFeatureAt(vm, i);
    } else if (element.is<FailedValue>()) {
      waitFor(vm, element);
    }
  }

  // Create the control variable
  UnstableNode unstableControlVar = Variable::build(vm);
  RichNode controlVar = unstableControlVar;
  controlVar.ensureStable(vm);

  // Add the control variable to the suspension list of all the fields
  for (size_t i = 0; i < getWidth(); i++) {
    DataflowVariable(elements[i]).addToSuspendList(vm, controlVar);
  }

  // Wait for the control variable
  waitFor(vm, controlVar);
}

///////////
// Tuple //
///////////

#include "Tuple-implem.hh"

template <typename L>
Tuple::Tuple(VM vm, size_t width, L&& label) {
  _label.init(vm, std::forward<L>(label));
  _width = width;

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < width; i++)
    getElements(i).init(vm);
}

Tuple::Tuple(VM vm, size_t width, GR gr, Tuple& from) {
  _width = width;
  gr->copyStableNode(_label, from._label);

  gr->copyStableNodes(getElementsArray(), from.getElementsArray(), width);
}

bool Tuple::equals(VM vm, RichNode right, WalkStack& stack) {
  auto rhs = right.as<Tuple>();

  if (getWidth() != rhs.getWidth())
    return false;

  stack.pushArray(vm, getElementsArray(), rhs.getElementsArray(), getWidth());
  stack.push(vm, getLabel(), rhs.getLabel());

  return true;
}

UnstableNode Tuple::getValueAt(VM vm, nativeint feature) {
  return { vm, getElements((size_t) feature - 1) };
}

UnstableNode Tuple::getFeatureAt(VM vm, size_t index) {
  return SmallInt::build(vm, index+1);
}

UnstableNode Tuple::label(VM vm) {
  return { vm, _label };
}

UnstableNode Tuple::clone(VM vm) {
  auto result = Tuple::build(vm, _width, _label);

  auto elements = RichNode(result).as<Tuple>().getElementsArray();
  for (size_t i = 0; i < _width; i++)
    elements[i].init(vm, OptVar::build(vm));

  return result;
}

bool Tuple::testRecord(VM vm, RichNode arity) {
  return false;
}

bool Tuple::testTuple(VM vm, RichNode label, size_t width) {
  return (width == _width) && mozart::equals(vm, _label, label);
}

bool Tuple::testLabel(VM vm, RichNode label) {
  return mozart::equals(vm, _label, label);
}

void Tuple::printReprToStream(VM vm, std::ostream& out, int depth, int width) {
  using namespace patternmatching;

  if (_width > 1 && matches(vm, _label, vm->coreatoms.sharp)) {
    // Use the infix # notation
    for (size_t i = 0; i < _width; ++i) {
        if (i > 0)
          out << "#";

        if ((nativeint) i >= width) {
          out << "...";
          break;
        }

        RichNode element = getElements(i);
        bool paren;
        if (element.is<Cons>())
          paren = true;
        else if (element.is<Tuple>())
          paren = element.as<Tuple>().hasSharpRepr(vm, depth-1);
        else
          paren = false;

        if (paren)
          out << "(" << repr(vm, element, depth, width) << ")";
        else
          out << repr(vm, element, depth, width);
    }
  } else {
    // Use standard tuple notation
    out << repr(vm, _label, depth+1, width) << "(";

    if (depth <= 0) {
      out << "...";
    } else {
      for (size_t i = 0; i < _width; i++) {
        if (i > 0)
          out << " ";

        if ((nativeint) i >= width) {
          out << "...";
          break;
        }

        out << repr(vm, getElements(i), depth, width);
      }
    }

    out << ")";
  }
}

bool Tuple::hasSharpRepr(VM vm, int depth) {
  using namespace patternmatching;

  return (_width > 1) && matches(vm, _label, vm->coreatoms.sharp);
}

UnstableNode Tuple::serialize(VM vm, SE se) {
  UnstableNode r = makeTuple(vm, MOZART_STR("tuple"), _width+1);
  auto elements=RichNode(r).as<Tuple>().getElementsArray();
  for (size_t i=0; i< _width; ++i) {
    se->copy(elements[i], getElements(i));
  }
  se->copy(elements[_width], _label);
  return r;
}

//////////
// Cons //
//////////

#include "Cons-implem.hh"

template <typename Head, typename Tail, typename>
Cons::Cons(VM vm, Head&& head, Tail&& tail) {
  _elements[0].init(vm, std::forward<Head>(head));
  _elements[1].init(vm, std::forward<Tail>(tail));
}

Cons::Cons(VM vm) {
  _elements[0].init(vm);
  _elements[1].init(vm);
}

Cons::Cons(VM vm, GR gr, Cons& from) {
  gr->copyStableNode(_elements[0], from._elements[0]);
  gr->copyStableNode(_elements[1], from._elements[1]);
}

bool Cons::equals(VM vm, RichNode right, WalkStack& stack) {
  auto rhs = right.as<Cons>();

  stack.push(vm, getTail(), rhs.getTail());
  stack.push(vm, getHead(), rhs.getHead());

  return true;
}

UnstableNode Cons::getValueAt(VM vm, nativeint feature) {
  return { vm, _elements[feature-1] };
}

UnstableNode Cons::label(VM vm) {
  return Atom::build(vm, vm->coreatoms.pipe);
}

size_t Cons::width(VM vm) {
  return 2;
}

UnstableNode Cons::arityList(VM vm) {
  return buildList(vm, 1, 2);
}

UnstableNode Cons::clone(VM vm) {
  return buildCons(vm, OptVar::build(vm), OptVar::build(vm));
}

UnstableNode Cons::waitOr(VM vm) {
  RichNode head = _elements[0];
  RichNode tail = _elements[1];

  // If there is a field which is bound, then return its feature
  if (!head.isTransient()) {
    return SmallInt::build(vm, 1);
  } else if (!tail.isTransient()) {
    return SmallInt::build(vm, 2);
  }

  // If there is a feature which is a failed value, wait for it
  if (head.is<FailedValue>())
    waitFor(vm, head);
  else if (tail.is<FailedValue>())
    waitFor(vm, tail);

  // Create the control variable
  UnstableNode unstableControlVar = Variable::build(vm);
  RichNode controlVar = unstableControlVar;
  controlVar.ensureStable(vm);

  // Add the control variable to the suspension list of both fields
  DataflowVariable(head).addToSuspendList(vm, controlVar);
  DataflowVariable(tail).addToSuspendList(vm, controlVar);

  // Wait for the control variable
  waitFor(vm, controlVar);
}

bool Cons::testRecord(VM vm, RichNode arity) {
  return false;
}

bool Cons::testTuple(VM vm, RichNode label, size_t width) {
  return (width == 2) && label.is<Atom>() &&
    (label.as<Atom>().value() == vm->coreatoms.pipe);
}

bool Cons::testLabel(VM vm, RichNode label) {
  return label.is<Atom>() && (label.as<Atom>().value() == vm->coreatoms.pipe);
}

void Cons::printReprToStream(VM vm, std::ostream& out, int depth, int width) {
  if (hasListRepr(vm, depth)) {
    out << "[" << repr(vm, _elements[0], depth, width);
    ozListForEach(vm, _elements[1],
      [vm, &out, depth, width] (RichNode element) {
        out << " " << repr(vm, element, depth, width);
      },
      MOZART_STR("list")
    );
    out << "]";
  } else {
    if (RichNode(_elements[0]).is<Cons>()) {
      out << "(" << repr(vm, _elements[0], depth, width) << ")";
    } else {
      out << repr(vm, _elements[0], depth, width);
    }

    out << "|" << repr(vm, _elements[1], depth, width);
  }
}

bool Cons::hasListRepr(VM vm, int depth) {
  using namespace patternmatching;

  RichNode tail = _elements[1];
  int i = 1;
  while (i < depth && !tail.isTransient()) {
    RichNode next;
    if (matchesCons(vm, tail, wildcard(), capture(next)))
      tail = next;
    else if (matches(vm, tail, vm->coreatoms.nil))
      return true;
    else
      return false;
    ++i;
  }

  return false;
}

UnstableNode Cons::serialize(VM vm, SE se) {
  auto result = buildTuple(vm, MOZART_STR("cons"),
                           OptVar::build(vm), OptVar::build(vm));
  auto elements = RichNode(result).as<Tuple>().getElementsArray();
  se->copy(elements[0], _elements[0]);
  se->copy(elements[1], _elements[1]);
  return result;
}

///////////
// Arity //
///////////

#include "Arity-implem.hh"

template <typename L>
Arity::Arity(VM vm, size_t width, L&& label) {
  _label.init(vm, std::forward<L>(label));
  _width = width;

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < width; i++)
    getElements(i).init(vm);
}

Arity::Arity(VM vm, size_t width, GR gr, Arity& from) {
  _width = width;
  gr->copyStableNode(_label, from._label);

  gr->copyStableNodes(getElementsArray(), from.getElementsArray(), width);
}

StableNode* Arity::getElement(size_t index) {
  return &getElements(index);
}

bool Arity::equals(VM vm, RichNode right, WalkStack& stack) {
  auto rhs = right.as<Arity>();

  if (getWidth() != rhs.getWidth())
    return false;

  stack.pushArray(vm, getElementsArray(), rhs.getElementsArray(), getWidth());
  stack.push(vm, getLabel(), rhs.getLabel());

  return true;
}

bool Arity::lookupFeature(VM vm, RichNode feature, size_t& offset) {
  requireFeature(vm, feature);

  // Dichotomic search
  size_t lo = 0;
  size_t hi = getWidth();

  while (lo < hi) {
    size_t mid = (lo + hi) / 2; // no need to worry about overflow, here
    int comparison = compareFeatures(vm, feature, getElements(mid));

    if (comparison == 0) {
      offset = mid;
      return true;
    } else if (comparison < 0) {
      hi = mid;
    } else {
      lo = mid+1;
    }
  }

  return false;
}

void Arity::printReprToStream(VM vm, std::ostream& out, int depth, int width) {
  out << "<Arity " << repr(vm, _label, depth+1, width) << "(";

  if (depth <= 0) {
    out << "...";
  } else {
    for (size_t i = 0; i < _width; i++) {
      if (i > 0)
        out << " ";

      if ((nativeint) i >= width) {
        out << "...";
        break;
      }

      out << repr(vm, getElements(i), depth, width);
    }
  }

  out << ")>";
}

UnstableNode Arity::serialize(VM vm, SE se) {
  UnstableNode r = makeTuple(vm, MOZART_STR("arity"), _width+1);
  auto elements=RichNode(r).as<Tuple>().getElementsArray();
  for (size_t i=0; i< _width; ++i) {
    se->copy(elements[i], getElements(i));
  }
  se->copy(elements[_width], _label);
  return r;
}

////////////
// Record //
////////////

#include "Record-implem.hh"

template <typename A>
Record::Record(VM vm, size_t width, A&& arity) {
  _arity.init(vm, std::forward<A>(arity));
  _width = width;

  assert(RichNode(_arity).is<Arity>());

  // Initialize elements with non-random data
  // TODO An Uninitialized type?
  for (size_t i = 0; i < width; i++)
    getElements(i).init(vm);
}

Record::Record(VM vm, size_t width, GR gr, Record& from) {
  gr->copyStableNode(_arity, from._arity);
  _width = width;

  gr->copyStableNodes(getElementsArray(), from.getElementsArray(), width);
}

bool Record::equals(VM vm, RichNode right, WalkStack& stack) {
  auto rhs = right.as<Record>();

  if (getWidth() != rhs.getWidth())
    return false;

  stack.pushArray(vm, getElementsArray(), rhs.getElementsArray(), getWidth());
  stack.push(vm, getArity(), rhs.getArity());

  return true;
}

UnstableNode Record::getFeatureAt(VM vm, size_t index) {
  return { vm, *RichNode(_arity).as<Arity>().getElement(index) };
}

bool Record::lookupFeature(VM vm, RichNode feature,
                           nullable<UnstableNode&> value) {
  size_t offset = 0;
  if (RichNode(_arity).as<Arity>().lookupFeature(vm, feature, offset)) {
    if (value.isDefined())
      value.get().copy(vm, getElements(offset));
    return true;
  } else {
    return false;
  }
}

bool Record::lookupFeature(VM vm, nativeint feature,
                           nullable<UnstableNode&> value) {
  UnstableNode featureNode = mozart::build(vm, feature);
  return lookupFeature(vm, featureNode, value);
}

UnstableNode Record::label(VM vm) {
  return { vm, *RichNode(_arity).as<Arity>().getLabel() };
}

UnstableNode Record::clone(VM vm) {
  auto result = Record::build(vm, _width, _arity);

  auto elements = RichNode(result).as<Record>().getElementsArray();
  for (size_t i = 0; i < _width; i++)
    elements[i].init(vm, OptVar::build(vm));

  return result;
}

bool Record::testRecord(VM vm, RichNode arity) {
  return mozart::equals(vm, _arity, arity);
}

bool Record::testTuple(VM vm, RichNode label, size_t width) {
  return false;
}

bool Record::testLabel(VM vm, RichNode label) {
  return mozart::equals(
    vm, *RichNode(_arity).as<Arity>().getLabel(), label);
}

void Record::printReprToStream(VM vm, std::ostream& out, int depth, int width) {
  out << repr(vm, *RichNode(_arity).as<Arity>().getLabel(), depth+1, width);
  out << "(";

  if (depth <= 0) {
    out << "...";
  } else {
    for (size_t i = 0; i < _width; i++) {
      if (i > 0)
        out << " ";

      if ((nativeint) i >= width) {
        out << "...";
        break;
      }

      auto feature = getFeatureAt(vm, i);

      out << repr(vm, feature, depth, width) << ":";
      out << repr(vm, getElements(i), depth, width);
    }
  }

  out << ")";
}

UnstableNode Record::serialize(VM vm, SE se) {
  UnstableNode r = makeTuple(vm, MOZART_STR("record"), _width+1);
  auto elements=RichNode(r).as<Tuple>().getElementsArray();
  for (size_t i=0; i< _width; ++i) {
    se->copy(elements[i], getElements(i));
  }
  se->copy(elements[_width], _arity);
  return r;
}

///////////
// Chunk //
///////////

#include "Chunk-implem.hh"

void Chunk::create(StableNode*& self, VM vm, GR gr, Chunk from) {
  gr->copyStableRef(self, from.getUnderlying());
}

bool Chunk::lookupFeature(VM vm, RichNode feature,
                          nullable<UnstableNode&> value) {
  return Dottable(*_underlying).lookupFeature(vm, feature, value);
}

bool Chunk::lookupFeature(VM vm, nativeint feature,
                          nullable<UnstableNode&> value) {
  return Dottable(*_underlying).lookupFeature(vm, feature, value);
}

UnstableNode Chunk::serialize(VM vm, SE se) {
  auto result = buildTuple(vm, MOZART_STR("chunk"), OptVar::build(vm));
  se->copy(RichNode(result).as<Tuple>().getElements(0), *_underlying);
  return result;
}

}

#endif // MOZART_GENERATOR

#endif // __RECORDS_H
