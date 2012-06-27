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

#ifndef __UTILS_DECL_H
#define __UTILS_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

template <typename T>
struct function_traits;

/**
 * Apply a function on a list.
 *
 * For example, if the list is `a|b|c|d|rest`, then this function is equivalent
 * to::
 *
 *      MOZART_CHECK_OPRESULT(onHead(a));
 *      MOZART_CHECK_OPRESULT(onHead(b));
 *      MOZART_CHECK_OPRESULT(onHead(c));
 *      MOZART_CHECK_OPRESULT(onHead(d));
 *      return onTail(rest);
 *
 * The function onTail will **not** be called if the last element is `nil`. It
 * assumes the list all have the same type "T".
 */
template <class F, class G>
static
OpResult ozListForEach(VM vm, RichNode list, const F& onHead, const G& onTail);

template <class F>
static
OpResult ozListForEach(VM vm, RichNode list, const F& onHead,
                       const nchar* expectedType);

}

#endif

