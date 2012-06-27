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

#include "datatypeshelpers-decl.hh"

namespace mozart {

class Boolean;

typedef enum BOOL_OR_NOT_BOOL {
  bFalse, bTrue, bNotBool
} BoolOrNotBool;

#ifndef MOZART_GENERATOR
#include "Boolean-implem-decl.hh"
#endif

template <>
class Implementation<Boolean>: public LiteralHelper<Boolean>,
  Copyable, StoredAs<bool>, WithValueBehavior {
public:
  typedef SelfType<Boolean>::Self Self;
public:
  constexpr static UUID uuid = "{ce34f46e-4751-4f2d-b6fd-0522198a4810}";

  Implementation(bool value) : _value(value) {}

  static void build(bool& self, VM, bool value) {
    self = value;
  }

  inline
  static void build(bool& self, VM vm, GR gr, Self from);

public:
  bool value() const { return _value; }

  inline
  bool equals(VM vm, Self right);

  inline
  int compareFeatures(VM vm, Self right);

public:
  // BooleanValue interface

  OpResult boolValue(Self self, VM vm, bool& result) {
    result = value();
    return OpResult::proceed();
  }

  OpResult valueOrNotBool(Self self, VM vm, BoolOrNotBool& result) {
    result = value() ? bTrue : bFalse;
    return OpResult::proceed();
  }

public:
  // VirtualString inteface
  OpResult isVirtualString(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult toString(Self self, VM vm, std::basic_ostream<nchar>& sink);

  inline
  OpResult vsLength(Self self, VM vm, nativeint& result);

  inline
  OpResult vsChangeSign(Self self, VM vm,
                        RichNode replacement, UnstableNode& result);

public:
  // Miscellaneous

  void printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
    out << (value() ? "true" : "false");
  }

private:
  const bool _value;
};

#ifndef MOZART_GENERATOR
#include "Boolean-implem-decl-after.hh"
#endif

}

#endif // __BOOLEAN_DECL_H
