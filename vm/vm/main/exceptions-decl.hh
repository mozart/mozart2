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

#ifndef __EXCEPTIONS_DECL_H
#define __EXCEPTIONS_DECL_H

#include "core-forward-decl.hh"
#include "store-decl.hh"

namespace mozart {

/** Base class for Mozart exceptions */
class Exception {
};

class Fail: public Exception {
public:
  Fail(VM vm) {}
};

class WaitBeforeBase: public Exception {
public:
  WaitBeforeBase(VM vm, RichNode waitee, bool quiet):
    _waitee(waitee.getStableRef(vm)), _quiet(quiet) {}

  StableNode* getWaiteeNode() const {
    return _waitee;
  }

  bool isQuiet() const {
    return _quiet;
  }
private:
  StableNode* _waitee;
  bool _quiet;
};

class WaitBefore: public WaitBeforeBase {
public:
  WaitBefore(VM vm, RichNode waitee): WaitBeforeBase(vm, waitee, false) {}
};

class WaitQuietBefore: public WaitBeforeBase {
public:
  WaitQuietBefore(VM vm, RichNode waitee): WaitBeforeBase(vm, waitee, true) {}
};

class Raise: public Exception {
public:
  Raise(VM vm, RichNode exception): _exception(exception.getStableRef(vm)) {}

  StableNode* getException() const {
    return _exception;
  }
private:
  StableNode* _exception;
};

inline
void MOZART_NORETURN fail(VM vm) {
  throw Fail(vm);
}

inline
void MOZART_NORETURN waitFor(VM vm, RichNode waitee) {
  throw WaitBefore(vm, waitee);
}

inline
void MOZART_NORETURN waitQuietFor(VM vm, RichNode waitee) {
  throw WaitQuietBefore(vm, waitee);
}

inline
void MOZART_NORETURN raise(VM vm, RichNode exception) {
  throw Raise(vm, exception);
}

}

#endif // __EXCEPTIONS_DECL_H
