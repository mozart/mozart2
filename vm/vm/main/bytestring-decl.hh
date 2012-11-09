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

#include "datatypeshelpers-decl.hh"

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

#ifndef MOZART_GENERATOR
#include "ByteString-implem-decl.hh"
#endif

class ByteString: public DataType<ByteString>,
  public IntegerDottableHelper<ByteString>, WithValueBehavior {
public:
  static constexpr UUID uuid = "{2ca6b7da-7a3f-4f65-be2f-75bb6f704c47}";

  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("byteString"));
  }

  ByteString(VM vm, const LString<unsigned char>& bytes) : _bytes(bytes) {}

  inline
  ByteString(VM vm, GR gr, Self self);

public:
  const LString<unsigned char>& value() const { return _bytes; }

  inline
  bool equals(VM vm, Self right);

protected:
  friend class IntegerDottableHelper<ByteString>;

  bool isValidFeature(Self self, VM vm, nativeint feature) {
    return (feature >= 0) && (feature < _bytes.length);
  }

  inline
  UnstableNode getValueAt(Self self, VM vm, nativeint feature);

public:
  // Comparable interface

  inline
  int compare(Self self, VM vm, RichNode right);

public:
  // StringLike interface

  bool isString(Self self, VM vm) {
    return false;
  }

  bool isByteString(Self self, VM vm) {
    return true;
  }

  inline
  LString<nchar>* stringGet(Self self, VM vm);

  inline
  LString<unsigned char>* byteStringGet(Self self, VM vm);

  inline
  nativeint stringCharAt(Self self, VM vm, RichNode offset);

  inline
  UnstableNode stringAppend(Self self, VM vm, RichNode right);

  inline
  UnstableNode stringSlice(Self self, VM vm, RichNode from, RichNode to);

  inline
  void stringSearch(Self self, VM vm, RichNode from, RichNode needle,
                    UnstableNode& begin, UnstableNode& end);

  inline
  bool stringHasPrefix(Self self, VM vm, RichNode prefix);

  inline
  bool stringHasSuffix(Self self, VM vm, RichNode suffix);

public:
  // VirtualString interface

  bool isVirtualString(Self self, VM vm) {
    return true;
  }

  inline
  void toString(Self self, VM vm, std::basic_ostream<nchar>& sink);

  inline
  nativeint vsLength(Self self, VM vm);

public:
  // Miscellaneous

  inline
  UnstableNode decode(Self self, VM vm,
                      ByteStringEncoding encoding, EncodingVariant variant);

  inline
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  LString<unsigned char> _bytes;
};

inline
UnstableNode encodeToBytestring(VM vm, const BaseLString<nchar>& input,
                                ByteStringEncoding encoding,
                                EncodingVariant variant);

#ifndef MOZART_GENERATOR
#include "ByteString-implem-decl-after.hh"
#endif

}

#endif // __BYTESTRING_DECL_H
