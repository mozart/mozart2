// Copyright © 2012, Université catholique de Louvain
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

#ifndef __STRING_DECL_H
#define __STRING_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

////////////
// String //
////////////

class String;

#ifndef MOZART_GENERATOR
#include "String-implem-decl.hh"
#endif

template <>
class Implementation<String>: WithValueBehavior {
public:
  typedef SelfType<String>::Self Self;
public:
  static constexpr UUID uuid = "{163123b5-feaa-4e1d-8917-f74d81e11236}";

  Implementation(VM vm, const LString<nchar>& string) : _string(string) {}

  inline
  Implementation(VM vm, GR gr, Self self);

public:
  inline
  bool equals(VM vm, Self right);

  inline
  int compareFeatures(VM vm, Self right);

public:
  // Comparable interface

  //inline
  //OpResult compare(Self self, VM vm, RichNode right, int& result);

public:
  // StringLike interface
  OpResult isString(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult toAtom(Self self, VM vm, UnstableNode& result);

public:
  // Dottable interface

  // (can't implement IntegerDottableHelper because .dotNumber() may raise
  //  exceptions).

  inline
  OpResult dotNumber(Self self, VM vm, nativeint feature, UnstableNode& result);

  inline
  OpResult dot(Self self, VM vm, RichNode feature, UnstableNode& result);

  inline
  OpResult hasFeature(RichNode self, VM vm, RichNode feature, bool& result);

public:
  // RecordLike interface
  OpResult isRecord(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  OpResult isTuple(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult label(Self self, VM vm, UnstableNode& result);

  inline
  OpResult width(Self self, VM vm, size_t& result);

  inline
  OpResult arityList(Self self, VM vm, UnstableNode& result);

  inline
  OpResult clone(Self self, VM vm, UnstableNode& result);

  inline
  OpResult waitOr(Self self, VM vm, UnstableNode& result);

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
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

  const LString<nchar>& getString() const { return _string; }

private:
  LString<nchar> _string;
};

#ifndef MOZART_GENERATOR
#include "String-implem-decl-after.hh"
#endif

}

#endif // __STRING_DECL_H
