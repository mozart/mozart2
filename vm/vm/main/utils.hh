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

#ifndef MOZART_GENERATOR

namespace mozart {

// ozListForEach ---------------------------------------------------------------

template <class F, class G>
OpResult ozListForEach(VM vm, RichNode cons, const F& onHead, const G& onTail) {
  while (true) {
    using namespace patternmatching;

    OpResult matchRes = OpResult::proceed();
    typename function_traits<F>::template arg<0>::type head;
    UnstableNode tail;

    if (matchesCons(vm, matchRes, cons, capture(head), capture(tail))) {
      MOZART_CHECK_OPRESULT(onHead(head));
      cons = tail;

    } else if (matches(vm, matchRes, cons, vm->coreatoms.nil)) {
      return OpResult::proceed();

    } else {
      if (matchRes.isProceed())
        return onTail(cons);
      else
        return matchRes;
    }
  }
}

template <class F>
OpResult ozListForEach(VM vm, RichNode cons, const F& onHead,
                       const nchar* expectedType) {
  return ozListForEach(vm, cons, onHead, [=](RichNode node) {
    return raiseTypeError(vm, expectedType, node);
  });
}

}

#endif

#endif // __UTILS_H
