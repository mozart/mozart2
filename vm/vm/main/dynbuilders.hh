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

#ifndef __DYNBUILDERS_H
#define __DYNBUILDERS_H

#include "mozartcore.hh"

#include <algorithm>

#ifndef MOZART_GENERATOR

namespace mozart {

////////////
// Tuples //
////////////

OpResult requireLiteral(VM vm, RichNode label) {
  bool isLiteral = false;
  MOZART_CHECK_OPRESULT(Literal(label).isLiteral(vm, isLiteral));

  if (isLiteral)
    return OpResult::proceed();
  else
    return raiseTypeError(vm, MOZART_STR("literal"), label);
}

namespace internal {
  inline
  bool isPipeAtom(VM vm, RichNode label) {
    using namespace patternmatching;

    OpResult res = OpResult::proceed();
    return matches(vm, res, label, vm->coreatoms.pipe);
  }
}

inline
OpResult makeTuple(VM vm, UnstableNode& result, RichNode label, size_t width) {
  MOZART_CHECK_OPRESULT(requireLiteral(vm, label));

  if (width == 0) {
    result.copy(vm, label);
    return OpResult::proceed();
  }

  if ((width == 2) && internal::isPipeAtom(vm, label)) {
    UnstableNode head = OptVar::build(vm);
    UnstableNode tail = OptVar::build(vm);
    result = Cons::build(vm, head, tail);

    return OpResult::proceed();
  }

  result = Tuple::build(vm, width, label);
  auto tuple = RichNode(result).as<Tuple>();

  for (size_t i = 0; i < width; i++)
    tuple.getElement(i)->init(vm, OptVar::build(vm));

  return OpResult::proceed();
}

template <class T>
inline
OpResult buildTupleDynamic(VM vm, UnstableNode& result, RichNode label,
                           size_t width, T elements[]) {
  return buildTupleDynamic(vm, result, label, width, elements, identity<T&>);
}

template <class T, class ElemToValue>
inline
OpResult buildTupleDynamic(VM vm, UnstableNode& result, RichNode label,
                           size_t width, T elements[],
                           ElemToValue elemToValue) {
  MOZART_CHECK_OPRESULT(requireLiteral(vm, label));

  if (width == 0) {
    result.copy(vm, label);
    return OpResult::proceed();
  }

  if ((width == 2) && internal::isPipeAtom(vm, label)) {
    UnstableNode head(vm, elemToValue(elements[0]));
    UnstableNode tail(vm, elemToValue(elements[1]));
    result = Cons::build(vm, head, tail);

    return OpResult::proceed();
  }

  result = Tuple::build(vm, width, label);
  auto tuple = RichNode(result).as<Tuple>();

  for (size_t i = 0; i < width; i++)
    tuple.getElement(i)->init(vm, elemToValue(elements[i]));

  return OpResult::proceed();
}

///////////
// Lists //
///////////

template <class T>
UnstableNode buildListDynamic(VM vm, size_t length, T elements[]) {
  UnstableNode result = build(vm, vm->coreatoms.nil);

  for (size_t i = length; i > 0; i--)
    result = buildCons(vm, elements[i-1], std::move(result));

  return result;
}

template <class T, class ElemToValue>
UnstableNode buildListDynamic(VM vm, size_t length, T elements[],
                              ElemToValue elemToValue) {
  UnstableNode result = build(vm, vm->coreatoms.nil);

  for (size_t i = length; i > 0; i--)
    result = buildCons(vm, elemToValue(elements[i-1]), std::move(result));

  return result;
}

/////////////
// Records //
/////////////

namespace internal {
  inline
  UnstableNode& featureOf(const UnstableNode& element) {
    return const_cast<UnstableNode&>(element);
  }

  inline
  UnstableNode& featureOf(const UnstableField& element) {
    return const_cast<UnstableNode&>(element.feature);
  }

  template <class T>
  inline
  bool isTupleFeatureArray(VM vm, size_t width, T elements[]) {
    using namespace patternmatching;

    OpResult res = OpResult::proceed();

    for (size_t i = 0; i < width; i++) {
      if (!matches(vm, res, featureOf(elements[i]), i+1))
        return false;
    }

    return true;
  }
}

template <class T>
void sortFeatures(VM vm, size_t width, T features[]) {
  using internal::featureOf;

  std::sort(features, features+width,
    [vm] (const T& lhs, const T& rhs) -> bool {
      return compareFeatures(vm, featureOf(lhs), featureOf(rhs)) < 0;
    }
  );
}

template <class T>
OpResult buildArityDynamic(VM vm, bool& isTuple, UnstableNode& result,
                           RichNode label, size_t width, T elements[]) {
  using internal::featureOf;

  // Check that the label is a literal
  MOZART_CHECK_OPRESULT(requireLiteral(vm, label));

  // Check that all features are features
  for (size_t i = 0; i < width; i++)
    MOZART_REQUIRE_FEATURE(featureOf(elements[i]));

  // Sort the features
  sortFeatures(vm, width, elements);

  // Check if the corresponding record should be a Tuple instead
  isTuple = internal::isTupleFeatureArray(vm, width, elements);
  if (isTuple)
    return OpResult::proceed();

  // Make the arity
  result = Arity::build(vm, width, label);
  auto arity = RichNode(result).as<Arity>();

  for (size_t i = 0; i < width; i++)
    arity.getElement(i)->init(vm, featureOf(elements[i]));

  return OpResult::proceed();
}

OpResult buildRecordDynamic(VM vm, UnstableNode& result,
                            RichNode label, size_t width,
                            UnstableField elements[]) {
  // Make the arity - this sorts elements along the way
  bool isTuple = false;
  UnstableNode arity;
  MOZART_CHECK_OPRESULT(buildArityDynamic(
    vm, isTuple, arity, label, width, elements));

  // Optimized representation for tuples
  if (isTuple) {
    return buildTupleDynamic(vm, result, label, width, elements,
      [] (UnstableField& element) -> UnstableNode& { return element.value; });
  }

  // Allocate the record
  result = Record::build(vm, width, arity);
  auto record = RichNode(result).as<Record>();

  // Fill the elements
  for (size_t i = 0; i < width; i++)
    record.getElement(i)->init(vm, elements[i].value);

  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __DYNBUILDERS_H
