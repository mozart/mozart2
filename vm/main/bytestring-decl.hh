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

// Note: these magic numbers are to be known in the Oz side as well.
enum ByteStringEncoding : nativeint {
  latin1 = 0,
  utf8 = 1,
  utf16 = 2,
  utf32 = 3
};

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

  Implementation(VM vm, LString<char>&& bytes) : _bytes(std::move(bytes)) {}

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
  // ByteStringLike interface
  OpResult isByteString(Self self, VM vm, bool& result) {
    result = true;
    return OpResult::proceed();
  }

  inline
  OpResult bsGet(Self self, VM vm, nativeint index, char& result);

  inline
  OpResult bsAppend(Self self, VM vm, RichNode right, UnstableNode& result);

  OpResult bsLength(Self self, VM vm, nativeint& length) {
    return vsLength(self, vm, length);
  }

  inline
  OpResult bsDecode(Self self, VM vm,
                    ByteStringEncoding encoding, bool isLittleEndian, bool hasBOM,
                    UnstableNode& result);

  inline
  OpResult bsSlice(Self self, VM vm, nativeint from, nativeint to, UnstableNode& result);

  inline
  OpResult bsStrChr(Self self, VM vm,
                    nativeint from, char character, UnstableNode& res);


public:
  // VirtualString interface
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

  const LString<char>& getBytes() const { return _bytes; }

private:
  LString<char> _bytes;
};

static
OpResult encodeToBytestring(VM vm, const LString<nchar>& input,
                            ByteStringEncoding encoding, bool isLittleEndian, bool hasBOM,
                            UnstableNode& result);

#ifndef MOZART_GENERATOR
#include "ByteString-implem-decl-after.hh"
#endif

}

#endif // __STRING_DECL_H
