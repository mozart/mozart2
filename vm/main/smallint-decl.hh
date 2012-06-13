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

#ifndef __SMALLINT_DECL_H
#define __SMALLINT_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

class SmallInt;

#ifndef MOZART_GENERATOR
#include "SmallInt-implem-decl.hh"
#endif

template <>
class Implementation<SmallInt>: Copyable, StoredAs<nativeint>,
  WithValueBehavior {
public:
  typedef SelfType<SmallInt>::Self Self;
public:
  static constexpr UUID uuid = "{00000000-0000-4f00-0000-000000000001}";

  Implementation(nativeint value) : _value(value) {}

  static void build(nativeint& self, VM vm, nativeint value) {
    self = value;
  }

  inline
  static void build(nativeint& self, VM vm, GR gr, Self from);

public:
  nativeint value() const { return _value; }

  inline
  bool equals(VM vm, Self right);

  inline
  int compareFeatures(VM vm, Self right);

public:
  // Comparable interface

  inline
  OpResult compare(Self self, VM vm, RichNode right, int& result);

public:
  // IntegerValue inteface

  OpResult intValue(Self self, VM vm, nativeint& result) {
    result = value();
    return OpResult::proceed();
  }

  inline
  OpResult equalsInteger(Self self, VM vm, nativeint right, bool& result);

public:
  // Numeric inteface

  OpResult isNumber(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  OpResult isInt(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  OpResult isFloat(Self self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  inline
  OpResult opposite(Self self, VM vm, UnstableNode& result);

  inline
  OpResult add(Self self, VM vm, RichNode right, UnstableNode& result);

  inline
  OpResult addValue(Self self, VM vm, nativeint b, UnstableNode& result);

  inline
  OpResult subtract(Self self, VM vm, RichNode right, UnstableNode& result);

  inline
  OpResult subtractValue(Self self, VM vm, nativeint b, UnstableNode& result);

  inline
  OpResult multiply(Self self, VM vm, RichNode right, UnstableNode& result);

  inline
  OpResult multiplyValue(Self self, VM vm, nativeint b, UnstableNode& result);

  inline
  OpResult divide(Self self, VM vm, RichNode right, UnstableNode& result);

  inline
  OpResult div(Self self, VM vm, RichNode right, UnstableNode& result);

  inline
  OpResult divValue(Self self, VM vm, nativeint b, UnstableNode& result);

  inline
  OpResult mod(Self self, VM vm, RichNode right, UnstableNode& result);

  inline
  OpResult modValue(Self self, VM vm, nativeint b, UnstableNode& result);

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

public:
  // Miscellaneous

  void printReprToStream(Self self, VM vm, std::ostream& out, int depth) {
    out << value();
  }

private:
  inline
  bool testMultiplyOverflow(nativeint a, nativeint b);

  const nativeint _value;
};

#ifndef MOZART_GENERATOR
#include "SmallInt-implem-decl-after.hh"
#endif

}

#endif // __SMALLINT_DECL_H
