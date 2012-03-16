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

#ifndef __EXCHELPERS_H
#define __EXCHELPERS_H

#include "exchelpers-decl.hh"

#include "coreinterfaces.hh"

namespace mozart {

BuiltinResult raiseAtom(VM vm, const char16_t* atom) {
  UnstableNode exception;
  exception.make<Atom>(vm, atom);

  return BuiltinResult::raise(vm, exception);
}

BuiltinResult raiseTypeError(VM vm, const char16_t* expected, RichNode actual) {
  UnstableNode label;
  label.make<Atom>(vm, u"typeError");

  UnstableNode exception;
  exception.make<Tuple>(vm, 2, &label);

  ArrayInitializer initializer = exception;

  UnstableNode arg;
  arg.make<Atom>(vm, expected);
  initializer.initElement(vm, 0, &arg);

  initializer.initElement(vm, 1, &actual.origin());

  return BuiltinResult::raise(vm, exception);
}

}

#endif // __EXCHELPERS_H
