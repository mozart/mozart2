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

#ifndef __BYTESTRING_DECL_H
#define __BYTESTRING_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

////////////////
// ByteString //
////////////////

enum class ByteStringEncoding {
  latin1,
  utf8,
  utf16,
  utf32
};

enum EncodingVariant : uintptr_t;

class ByteString;

#ifndef MOZART_GENERATOR
#include "ByteString-implem-decl.hh"
#endif

template <>
class Implementation<ByteString>: WithValueBehavior {
public:
  typedef SelfType<ByteString>::Self Self;
public:
  static constexpr UUID uuid = "{2ca6b7da-7a3f-4f65-be2f-75bb6f704c47}";

  Implementation(VM vm, const LString<unsigned char>& bytes) : _bytes(bytes) {}

  inline
  Implementation(VM vm, GR gr, Self self);

public:
  inline
  bool equals(VM vm, Self right);

  inline
  int compareFeatures(VM vm, Self right);

public:
  // Comparable interface
  inline
  OpResult compare(Self self, VM vm, RichNode right, int& result);

public:
  // StringLike interface
  OpResult isString(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  OpResult isByteString(Self self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  inline
  OpResult stringCharAt(Self self, VM vm, RichNode offset, nativeint& character);

  inline
  OpResult stringAppend(Self self, VM vm, RichNode right, UnstableNode& result);

  inline
  OpResult stringSlice(Self self, VM vm,
                       RichNode from, RichNode to, UnstableNode& result);

  inline
  OpResult stringSearch(Self self, VM vm, RichNode from, RichNode needle,
                        UnstableNode& begin, UnstableNode& end);

  inline
  OpResult stringEnd(Self self, VM vm, UnstableNode& result);

  inline
  OpResult stringGet(Self self, VM vm, LString<nchar>*& result);

  inline
  OpResult stringGet(Self self, VM vm, LString<unsigned char>*& result);

  inline
  OpResult stringHasPrefix(Self self, VM vm, RichNode prefix, bool& result);

  inline
  OpResult stringHasSuffix(Self self, VM vm, RichNode suffix, bool& result);

public:
  // Dottable interface
  // (can't implement IntegerDottableHelper because of StringOffset)

  inline
  OpResult dot(Self self, VM vm, RichNode feature, UnstableNode& result);

  inline
  OpResult hasFeature(RichNode self, VM vm, RichNode feature, bool& result);

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
  inline
  OpResult decode(Self self, VM vm,
                  ByteStringEncoding encoding, EncodingVariant variant,
                  UnstableNode& result);

  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

  const LString<unsigned char>& value() const { return _bytes; }

private:
  LString<unsigned char> _bytes;
};

static
OpResult encodeToBytestring(VM vm, const BaseLString<nchar>& input,
                            ByteStringEncoding encoding, EncodingVariant variant,
                            UnstableNode& result);

#ifndef MOZART_GENERATOR
#include "ByteString-implem-decl-after.hh"
#endif

}

#endif // __STRING_DECL_H
