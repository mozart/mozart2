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

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

template <class LT, class... Args>
void raise(VM vm, LT&& label, Args&&... args) {
  UnstableNode exception = buildTuple(vm, std::forward<LT>(label),
                                      std::forward<Args>(args)...);
  raise(vm, RichNode(exception));
}

template <class LT, class... Args>
void raiseError(VM vm, LT&& label, Args&&... args) {
  UnstableNode exception = buildTuple(vm, std::forward<LT>(label),
                                      std::forward<Args>(args)...);

  UnstableNode error = buildRecord(
    vm, buildArity(vm, vm->coreatoms.error, 1, vm->coreatoms.debug),
    std::move(exception), unit);

  raise(vm, RichNode(error));
}

template <class LT, class... Args>
void raiseSystem(VM vm, LT&& label, Args&&... args) {
  UnstableNode exception = buildTuple(vm, std::forward<LT>(label),
                                      std::forward<Args>(args)...);

  UnstableNode error = buildRecord(
    vm, buildArity(vm, vm->coreatoms.system, 1, vm->coreatoms.debug),
    std::move(exception), unit);

  raise(vm, RichNode(error));
}

template <class... Args>
void raiseKernelError(VM vm, Args&&... args) {
  raiseError(vm, vm->coreatoms.kernel, std::forward<Args>(args)...);
}

template <class Expected, class Actual>
void raiseTypeError(VM vm, Expected&& expected, Actual&& actual) {
  raiseKernelError(vm, MOZART_STR("type"),
                   unit,
                   buildList(vm, std::forward<Actual>(actual)),
                   std::forward<Expected>(expected),
                   1,
                   vm->coreatoms.nil);
}

void raiseIllegalArity(VM vm, RichNode target, size_t actualArgCount,
                       RichNode actualArgs[]) {
  raiseKernelError(vm, MOZART_STR("arity"),
                   target,
                   buildListDynamic(vm, actualArgCount, actualArgs));
}

template <class... Args>
void raiseUnicodeError(VM vm, UnicodeErrorReason reason, Args&&... args) {
  atom_t reasonAtom;
  switch (reason) {
    case UnicodeErrorReason::outOfRange:
      reasonAtom = vm->coreatoms.outOfRange;
      break;
    case UnicodeErrorReason::surrogate:
      reasonAtom = vm->coreatoms.surrogate;
      break;
    case UnicodeErrorReason::invalidUTF8:
      reasonAtom = vm->coreatoms.invalidUTF8;
      break;
    case UnicodeErrorReason::invalidUTF16:
      reasonAtom = vm->coreatoms.invalidUTF16;
      break;
    case UnicodeErrorReason::truncated:
      reasonAtom = vm->coreatoms.truncated;
      break;
    default:    // shouldn't reach here.
      assert(false);
      reasonAtom = vm->coreatoms.nil;
  }

  raiseSystem(vm, vm->coreatoms.unicodeError,
              reasonAtom, std::forward<Args>(args)...);
}

template <class... Args>
void raiseIndexOutOfBounds(VM vm, Args&&... args) {
  raise(vm, vm->coreatoms.indexOutOfBounds, std::forward<Args>(args)...);
}

}

#endif // MOZART_GENERATOR

#endif // __EXCHELPERS_H
