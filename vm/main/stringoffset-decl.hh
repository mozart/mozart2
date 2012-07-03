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

#ifndef __STRINGOFFSET_DECL_H
#define __STRINGOFFSET_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

//////////////////
// StringOffset //
//////////////////

class StringOffset;

#ifndef MOZART_GENERATOR
#include "StringOffset-implem-decl.hh"
#endif

template <>
class Implementation<StringOffset>: WithValueBehavior {
public:
  typedef SelfType<StringOffset>::Self Self;
public:
  static constexpr UUID uuid = "{1939b59d-f39a-43a2-b0d2-57a21bb52c74}";

  inline
  Implementation(VM vm, nativeint offset, RichNode refString, nativeint index=-1);

  inline
  Implementation(VM vm, GR gr, Self from);

public:
  inline
  bool equals(VM vm, Self right);

  inline
  int compareFeatures(VM vm, Self right);

public:
  // Comparable
  inline
  OpResult compare(Self self, VM vm, RichNode right, int& result);

public:
  // StringOffsetLike
  OpResult isStringOffset(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult toStringOffset(Self self, VM vm, RichNode string, nativeint& offset);

  inline
  OpResult getCharIndex(Self self, VM vm, nativeint& index);

  inline
  OpResult stringOffsetAdvance(Self self, VM vm,
                               RichNode string, nativeint delta,
                               UnstableNode& result);

public:
  // Miscellaneous
  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  inline
  void resolveCharIndex(VM vm);

  inline
  bool refIs(VM vm, RichNode rhs);

  nativeint _offset;
  nativeint _index;
  StableNode _ref;
};

#ifndef MOZART_GENERATOR
#include "StringOffset-implem-decl-after.hh"
#endif

}

#endif

