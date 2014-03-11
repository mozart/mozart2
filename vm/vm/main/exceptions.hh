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

#ifndef MOZART_EXCEPTIONS_H
#define MOZART_EXCEPTIONS_H

#include "mozartcore.hh"

namespace mozart {

inline
void MOZART_NORETURN fail(VM vm) {
  UnstableNode info = Unit::build(vm);
  fail(vm, info);
}

inline
void MOZART_NORETURN fail(VM vm, RichNode info) {
  vm->getGlobalExceptionMechanism().throwException(
    ExceptionKind::ekFail, info.getStableRef(vm));
}

inline
void MOZART_NORETURN waitFor(VM vm, RichNode waitee) {
  vm->getGlobalExceptionMechanism().throwException(
    ExceptionKind::ekWaitBefore, waitee.getStableRef(vm));
}

inline
void MOZART_NORETURN waitQuietFor(VM vm, RichNode waitee) {
  vm->getGlobalExceptionMechanism().throwException(
    ExceptionKind::ekWaitQuietBefore, waitee.getStableRef(vm));
}

inline
void MOZART_NORETURN raise(VM vm, RichNode exception) {
  vm->getGlobalExceptionMechanism().throwException(
    ExceptionKind::ekRaise, exception.getStableRef(vm));
}

}

#endif // MOZART_EXCEPTIONS_H
