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

#ifndef __OPRESULT_DECL_H
#define __OPRESULT_DECL_H

#include "core-forward-decl.hh"
#include "store-decl.hh"

namespace mozart {

//////////////
// OpResult //
//////////////

/**
 * Result of an operation acting on Oz values.
 */
struct OpResult {
public:
  enum Kind {
    orProceed,    // Proceed, aka success
    orFail,       // Fail, aka failure
    orWaitBefore, // Need an unbound variable, I want you to wait on that one
    orRaise,      // Raise an exception
  };
public:
  static OpResult proceed() {
    return OpResult(orProceed);
  }

  static OpResult fail() {
    return OpResult(orFail);
  }

  static OpResult waitFor(VM vm, RichNode node) {
    return OpResult(orWaitBefore, node.getStableRef(vm));
  }

  static OpResult raise(VM vm, RichNode node) {
    return OpResult(orRaise, node.getStableRef(vm));
  }

  bool isProceed() {
    return _kind == orProceed;
  }

  Kind kind() {
    return _kind;
  }

  /** If kind() == orWaitBefore, the node that must be waited upon */
  StableNode* getWaiteeNode() {
    assert(kind() == orWaitBefore);
    return _node;
  }

  /** If kind() == orRaise, the node containing the exception to raise */
  StableNode* getExceptionNode() {
    assert(kind() == orRaise);
    return _node;
  }
private:
  OpResult(Kind kind): _kind(kind) {}
  OpResult(Kind kind, StableNode* node): _kind(kind), _node(node) {}

  Kind _kind;
  StableNode* _node;
};

}

//////////////////////////////
// Basic macros on OpResult //
//////////////////////////////

#define MOZART_CHECK_OPRESULT(operation) \
  do { \
    ::mozart::OpResult macroTempOpResult = (operation); \
    if (!macroTempOpResult.isProceed()) \
      return macroTempOpResult; \
  } while (false)

#ifdef NDEBUG

#define MOZART_ASSERT_PROCEED(operation) \
  do { \
    operation; \
  } while (false)

#else

#define MOZART_ASSERT_PROCEED(operation) \
  do { \
    ::mozart::OpResult macroTempOpResult = (operation); \
    assert(macroTempOpResult.isProceed()); \
  } while (false)

#endif

#endif // __OPRESULT_DECL_H
