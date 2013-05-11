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

#include <setjmp.h>

#include "core-forward-decl.hh"
#include "store-decl.hh"

namespace mozart {

enum class ExceptionKind {
  ekFail, ekWaitBefore, ekWaitQuietBefore, ekRaise
};

struct ExceptionHandler {
  jmp_buf jumpBuffer;
  ExceptionHandler* nextHandler;
};

class GlobalExceptionMechanism {
public:
  GlobalExceptionMechanism(): _topHandler(nullptr),
    _exceptionKind(ExceptionKind::ekFail), _dataNode(nullptr) {}

  void pushHandler(ExceptionHandler& handler) {
    handler.nextHandler = _topHandler;
    _topHandler = &handler;
  }

  void popHandler(ExceptionHandler& handler) {
    assert(_topHandler == &handler);
    popHandler();
  }

  void popHandler() {
    _topHandler = _topHandler->nextHandler;
  }

  void MOZART_NORETURN throwException(ExceptionKind kind,
                                      StableNode* dataNode = nullptr) {
    _exceptionKind = kind;
    _dataNode = dataNode;
    rethrow();
  }

  void MOZART_NORETURN rethrow() {
    ExceptionHandler* handler = _topHandler;
    assert(handler != nullptr);
    _topHandler = handler->nextHandler;
    longjmp(handler->jumpBuffer, 1);
  }

  ExceptionKind getExceptionKind() {
    return _exceptionKind;
  }

  StableNode* getDataNode() {
    return _dataNode;
  }

  StableNode* getWaiteeNode() {
    assert(_exceptionKind == ExceptionKind::ekWaitBefore ||
      _exceptionKind == ExceptionKind::ekWaitQuietBefore);
    return _dataNode;
  }

  StableNode* getExceptionNode() {
    assert(_exceptionKind == ExceptionKind::ekRaise);
    return _dataNode;
  }

private:
  ExceptionHandler* _topHandler;
  ExceptionKind _exceptionKind;
  StableNode* _dataNode;
};

inline
void MOZART_NORETURN fail(VM vm);

inline
void MOZART_NORETURN waitFor(VM vm, RichNode waitee);

inline
void MOZART_NORETURN waitQuietFor(VM vm, RichNode waitee);

inline
void MOZART_NORETURN raise(VM vm, RichNode exception);

}

#define MOZART_TRY(vm) \
  do { \
    ::mozart::ExceptionHandler __Mozart_exc_handler; \
    if (::setjmp(__Mozart_exc_handler.jumpBuffer) == 0) { \
      (vm)->getGlobalExceptionMechanism().pushHandler(__Mozart_exc_handler);

#define MOZART_CATCH(vm, kind, node) \
      (vm)->getGlobalExceptionMechanism().popHandler(__Mozart_exc_handler); \
    } else { \
      auto __attribute__((unused)) kind = \
        (vm)->getGlobalExceptionMechanism().getExceptionKind(); \
      auto __attribute__((unused)) node = \
        (vm)->getGlobalExceptionMechanism().getDataNode(); \

#define MOZART_ENDTRY(vm) \
    } \
  } while (false)

#define MOZART_RETHROW(vm) \
  do { \
    (vm)->getGlobalExceptionMechanism().rethrow(); \
  } while (false)

#define MOZART_RETURN_IN_TRY(vm, value) \
  do { \
    auto __Mozart_exc_value = (value); \
    (vm)->getGlobalExceptionMechanism().popHandler(); \
    return __Mozart_exc_value; \
  } while (false)

#endif // __EXCEPTIONS_DECL_H
