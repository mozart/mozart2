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

#ifndef __STRING_H
#define __STRING_H

#include <string>
#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

////////////
// String //
////////////

#include "String-implem.hh"

// Core methods ----------------------------------------------------------------

Implementation<String>::Implementation(VM vm, GR gr, Self from)
  : _string(vm, from->_string) {}

bool Implementation<String>::equals(VM vm, Self right) {
  return _string == right->_string;
}

// Comparable ------------------------------------------------------------------

OpResult Implementation<String>::compare(Self self, VM vm,
                                         RichNode right, int& result) {
  LString<nchar>* rightString = nullptr;
  MOZART_CHECK_OPRESULT(StringLike(right).stringGet(vm, rightString));
  result = compareByCodePoint(_string, *rightString);
  return OpResult::proceed();
}

// StringLike ------------------------------------------------------------------

OpResult Implementation<String>::toAtom(Self self, VM vm,
                                        UnstableNode& result) {
  result.make<Atom>(vm, _string.length, _string.string);
  return OpResult::proceed();
}

OpResult Implementation<String>::stringGet(Self self, VM vm,
                                           LString<nchar>*& result) {
  result = &_string;
  return OpResult::proceed();
}

// Miscellaneous ---------------------------------------------------------------

void Implementation<String>::printReprToStream(Self self, VM vm,
                                               std::ostream& out, int depth) {
  out << '"' << toUTF<char>(_string) << '"';
}

OpResult Implementation<String>::toString(Self self, VM vm,
                                          std::basic_ostream<nchar>& sink) {
  sink << _string;
  return OpResult::proceed();
}

OpResult Implementation<String>::vsLength(Self self, VM vm, nativeint& result) {
  result = codePointCount(_string);
  return OpResult::proceed();
}

}

#endif // MOZART_GENERATOR

#endif // __STRING_H
