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

#ifndef __CELL_H
#define __CELL_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

//////////
// Cell //
//////////

#include "Cell-implem.hh"

Cell::Cell(VM vm, GR gr, Self from):
  WithHome(vm, gr, from->home()) {

  gr->copyUnstableNode(_value, from->_value);
}

UnstableNode Cell::exchange(VM vm, RichNode newValue) {
  if (!isHomedInCurrentSpace(vm))
    raise(vm, MOZART_STR("globalState"), MOZART_STR("cell"));

  auto oldValue = std::move(_value);
  _value.copy(vm, newValue);
  return oldValue;
}

UnstableNode Cell::access(VM vm) {
  return { vm, _value };
}

void Cell::assign(VM vm, RichNode newValue) {
  if (!isHomedInCurrentSpace(vm))
    raise(vm, MOZART_STR("globalState"), MOZART_STR("cell"));

  _value.copy(vm, newValue);
}

}

#endif // MOZART_GENERATOR

#endif // __CELL_H
