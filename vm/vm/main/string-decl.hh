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

#include "datatypeshelpers-decl.hh"

namespace mozart {

////////////
// String //
////////////

#ifndef MOZART_GENERATOR
#include "String-implem-decl.hh"
#endif

class String: public DataType<String>, WithValueBehavior {
public:
  typedef SelfType<String>::Self Self;
public:
  static constexpr UUID uuid = "{163123b5-feaa-4e1d-8917-f74d81e11236}";

  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("unicodeString"));
  }

  String(VM vm, const LString<nchar>& string) : _string(string) {}

  inline
  String(VM vm, GR gr, Self self);

public:
  const LString<nchar>& value() const { return _string; }

  inline
  bool equals(VM vm, Self right);

public:
  // Comparable interface

  inline
  int compare(Self self, VM vm, RichNode right);

public:
  // StringLike interface

  bool isString(Self self, VM vm) {
    return true;
  }

  bool isByteString(Self self, VM vm) {
    return false;
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

  // Search for a string or a character.
  inline
  void stringSearch(Self self, VM vm, RichNode from, RichNode needle,
                    UnstableNode& begin, UnstableNode& end);

  inline
  bool stringHasPrefix(Self self, VM vm, RichNode prefix);

  inline
  bool stringHasSuffix(Self self, VM vm, RichNode suffix);

public:
  // Dottable interface

  // (don't want to implement IntegerDottableHelper because isValidFeature
  // is not trivial)

  inline
  bool lookupFeature(Self self, VM vm, RichNode feature,
                     nullable<UnstableNode&> value);

  inline
  bool lookupFeature(Self self, VM vm, nativeint feature,
                     nullable<UnstableNode&> value);

public:
  // VirtualString inteface

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
  void printReprToStream(Self self, VM vm, std::ostream& out, int depth);

private:
  LString<nchar> _string;
};

#ifndef MOZART_GENERATOR
#include "String-implem-decl-after.hh"
#endif

}

#endif // __STRING_DECL_H
