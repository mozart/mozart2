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

#ifndef __LSTRING_H
#define __LSTRING_H

#include <vector>
#include <algorithm>

#include "mozartcore.hh"

namespace mozart {

/////////////
// LString //
/////////////

template <class C>
void LString<C>::free(VM vm) {
  if (length >= 0)
    vm->free(const_cast<C*>(string), length * sizeof(C));
  string = nullptr;
  length = 0;
}

template <class C>
LString<C>::LString(VM vm, LString<C> other) : length(other.length) {
  if (other.isErrorOrEmpty()) {
    string = nullptr;
  } else {
    void* memory = vm->malloc(other.bytesCount());
    memcpy(memory, other.string, other.bytesCount());
    string = static_cast<const C*>(memory);
  }
}

template <class C>
std::basic_ostream<C>& operator<<(std::basic_ostream<C>& out,
                                  LString<C> input) {
  return out.write(input.string, input.length);
}

template <class C>
bool operator==(LString<C> a, LString<C> b) {
  if (a.length != b.length)
    return false;
  if (a.string == b.string)
    return true;
  return memcmp(a.string, b.string, a.length*sizeof(C)) == 0;
}

template <class C>
bool operator!=(LString<C> a, LString<C> b) {
  return !(a == b);
}

}

#endif // __LSTRING_H
