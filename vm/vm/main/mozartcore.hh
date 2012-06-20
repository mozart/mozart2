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

#ifndef __MOZARTCORE_H
#define __MOZARTCORE_H

#include "mozartcore-decl.hh"

#include "coredatatypes-decl.hh"
#include "corebuilders.hh"
#include "exchelpers-decl.hh"
#include "coreinterfaces.hh"
#include "matchdsl.hh"
#include "builtins-decl.hh"
#include "builtinutils-decl.hh"
#include "dynbuilders-decl.hh"
#include "utils-decl.hh"

//////////////////////
// Some more macros //
//////////////////////

#define MOZART_GET_ARG(argVar, argValue, expectedType) \
  do { \
    using namespace ::mozart; \
    using namespace ::mozart::patternmatching; \
    OpResult _macroOpResult = OpResult::proceed(); \
    RichNode _macroValue = (argValue); \
    if (!matches(vm, _macroOpResult, _macroValue, capture(argVar))) \
      return matchTypeError(vm, _macroOpResult, _macroValue, (expectedType)); \
  } while (false)

#define MOZART_REQUIRE_FEATURE(featureValue) \
  do { \
    using namespace ::mozart; \
    RichNode _macroValue = (featureValue); \
    if (!_macroValue.isFeature()) { \
      MOZART_CHECK_OPRESULT(PotentialFeature(_macroValue).makeFeature(vm)); \
    } \
  } while (false)

#endif // __MOZARTCORE_H
