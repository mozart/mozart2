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

#ifndef __UNIT_H
#define __UNIT_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

//////////
// Unit //
//////////

#include "Unit-implem.hh"

void Implementation<Unit>::build(unit_t& self, VM vm, GR gr, Self from) {
}

bool Implementation<Unit>::equals(VM vm, Self right) {
  return true;
}

int Implementation<Unit>::compareFeatures(VM vm, Self right) {
  return 0;
}

OpResult Implementation<Unit>::toString(Self self, VM vm,
                                        std::basic_ostream<nchar>& sink) {
  sink << MOZART_STR("unit");
  return OpResult::proceed();
}

OpResult Implementation<Unit>::vsLength(Self self, VM vm, nativeint& result) {
  result = 4;
  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __UNIT_H
