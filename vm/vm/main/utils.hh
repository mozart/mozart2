// Copyright © 2012, Université catholique de Louvain
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

#ifndef __UTILS_H
#define __UTILS_H

#include "mozart.hh"

#include <type_traits>

#ifndef MOZART_GENERATOR

namespace mozart {

// getArgument -----------------------------------------------------------------

template <class T>
void getArgument(VM vm, T& argVar, RichNode argValue,
                 const nchar* expectedType) {
  using namespace patternmatching;

  if (!matches(vm, argValue, capture(argVar)))
    return raiseTypeError(vm, expectedType, argValue);
}

// requireFeature --------------------------------------------------------------

void requireFeature(VM vm, RichNode feature) {
  if (!feature.isFeature())
    PotentialFeature(feature).makeFeature(vm);
}

// ozListForEach ---------------------------------------------------------------

template <class F, class G>
void ozListForEach(VM vm, RichNode cons, const F& onHead, const G& onTail) {
  while (true) {
    using namespace patternmatching;

    typename std::remove_reference<
      typename function_traits<F>::template arg<0>::type>::type head;
    UnstableNode tail;

    if (matchesCons(vm, cons, capture(head), capture(tail))) {
      onHead(head);
      cons = tail;
    } else if (matches(vm, cons, vm->coreatoms.nil)) {
      return;
    } else {
      return onTail(cons);
    }
  }
}

template <class F>
void ozListForEach(VM vm, RichNode cons, const F& onHead,
                   const nchar* expectedType) {
  return ozListForEach(vm, cons, onHead, [=](RichNode node) {
    return raiseTypeError(vm, expectedType, node);
  });
}

void ozListLength(VM vm, RichNode list, size_t& result) {
  result = 0;

  UnstableNode nextList;

  while (true) {
    using namespace patternmatching;

    UnstableNode tail;

    if (matchesCons(vm, list, wildcard(), capture(tail))) {
      result++;
      nextList = std::move(tail);
      list = nextList;
    } else if (matches(vm, list, vm->coreatoms.nil)) {
      return;
    } else {
      return raiseTypeError(vm, MOZART_STR("list"), list);
    }
  }
}

namespace internal {
  template <class C>
  struct VSToStringHelper {
    inline
    static void call(VM vm, RichNode vs, std::basic_string<C>& result);
  };

  template <>
  struct VSToStringHelper<nchar> {
    static void call(VM vm, RichNode vs, std::basic_string<nchar>& result) {
      std::basic_stringstream<nchar> buffer;
      VirtualString(vs).toString(vm, buffer);

      result = buffer.str();
    }
  };

  template <class C>
  void VSToStringHelper<C>::call(VM vm, RichNode vs,
                                 std::basic_string<C>& result) {
    std::basic_string<nchar> nresult;
    VSToStringHelper<nchar>::call(vm, vs, nresult);

    auto str = toUTF<C>(makeLString(nresult.c_str(), nresult.size()));
    result = std::basic_string<C>(str.string, str.length);
  }
}

template <class C>
void vsToString(VM vm, RichNode vs, std::basic_string<C>& result) {
  return internal::VSToStringHelper<C>::call(vm, vs, result);
}

}

#endif

#endif // __UTILS_H
