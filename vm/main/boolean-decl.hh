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

#ifndef __BOOLEAN_DECL_H
#define __BOOLEAN_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

class Boolean;

typedef enum BOOL_OR_NOT_BOOL {
  bFalse, bTrue, bNotBool
} BoolOrNotBool;

#ifndef MOZART_GENERATOR
#include "Boolean-implem-decl.hh"
#endif

template <>
class Implementation<Boolean>: Copiable, StoredAs<bool>, WithValueBehavior {
public:
  typedef SelfType<Boolean>::Self Self;
public:
  Implementation(bool value) : _value(value) {}

  static bool build(VM, bool value) { return value; }

  inline
  static bool build(VM vm, GC gc, Self from);

  bool value() const { return _value; }

  inline
  bool equals(VM vm, Self right);

  BuiltinResult boolValue(Self self, VM vm, bool* result) {
    *result = value();
    return BuiltinResult::proceed();
  }

  BuiltinResult valueOrNotBool(Self self, VM vm, BoolOrNotBool* result) {
    *result = value() ? bTrue : bFalse;
    return BuiltinResult::proceed();
  }
private:
  const bool _value;
};

#ifndef MOZART_GENERATOR
#include "Boolean-implem-decl-after.hh"
#endif

}

#endif // __BOOLEAN_DECL_H
