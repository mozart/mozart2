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
  result.make<Tuple>(vm, width, label);
  auto tuple = RichNode(result).as<Tuple>();

  for (size_t i = 0; i < width; i++)
    tuple.getElement(i)->init(vm, elemToValue(elements[i]));

  return OpResult::proceed();
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
OpResult buildArityDynamic(VM vm, UnstableNode& result,
                           RichNode label, size_t width, T elements[]) {
  using internal::featureOf;

  // Check that all features are features
  for (size_t i = 0; i < width; i++)
    MOZART_REQUIRE_FEATURE(featureOf(elements[i]));

  // Sort the features
  sortFeatures(vm, width, elements);

  // Make the tuple
  UnstableNode tuple;
  MOZART_CHECK_OPRESULT(buildTupleDynamic(
    vm, tuple, label, width, elements,
    [] (T& element) -> UnstableNode& { return featureOf(element); }));

  // Make the result
  result.make<Arity>(vm, tuple);

  return OpResult::proceed();
}

OpResult buildRecordDynamic(VM vm, UnstableNode& result,
                            RichNode label, size_t width,
                            UnstableField elements[]) {
  // Make the arity - this sorts elements along the way
  UnstableNode arity;
  MOZART_CHECK_OPRESULT(buildArityDynamic(
    vm, arity, label, width, elements));

  // Allocate the record
  result.make<Record>(vm, width, arity);
  auto record = RichNode(result).as<Record>();

  // Fill the elements
  for (size_t i = 0; i < width; i++)
    record.getElement(i)->init(vm, elements[i].value);

  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __DYNBUILDERS_H
