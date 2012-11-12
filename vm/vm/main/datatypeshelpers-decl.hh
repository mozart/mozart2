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

#ifndef __DATATYPESHELPERS_DECL_H
#define __DATATYPESHELPERS_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

///////////////////
// LiteralHelper //
///////////////////

template <class T>
class LiteralHelper {
public:
  // Literal interface

  inline
  bool isLiteral(VM vm) {
    return true;
  }

public:
  // Dottable interface

  inline
  bool lookupFeature(VM vm, RichNode feature,
                     nullable<UnstableNode&> value);

  inline
  bool lookupFeature(VM vm, nativeint feature,
                     nullable<UnstableNode&> value);

public:
  // RecordLike interface

  bool isRecord(VM vm) {
    return true;
  }

  bool isTuple(VM vm) {
    return true;
  }

  inline
  UnstableNode label(RichNode self, VM vm);

  inline
  size_t width(VM vm);

  inline
  UnstableNode arityList(VM vm);

  inline
  UnstableNode clone(RichNode self, VM vm);

  inline
  UnstableNode waitOr(VM vm);

  inline
  bool testRecord(VM vm, RichNode arity);

  inline
  bool testTuple(RichNode self, VM vm, RichNode label, size_t width);

  inline
  bool testLabel(RichNode self, VM vm, RichNode label);
};

///////////////////////////
// IntegerDottableHelper //
///////////////////////////

template <class T>
class IntegerDottableHelper {
private:
  T* getThis() {
    return static_cast<T*>(this);
  }

public:
  // Dottable interface

  inline
  bool lookupFeature(VM vm, RichNode feature,
                     nullable<UnstableNode&> value);

  inline
  bool lookupFeature(VM vm, nativeint feature,
                     nullable<UnstableNode&> value);

private:
  bool internalIsValidFeature(VM vm, nativeint feature) {
    return getThis()->isValidFeature(vm, feature);
  }

  UnstableNode internalGetValueAt(VM vm, nativeint feature) {
    return getThis()->getValueAt(vm, feature);
  }

protected:
  /* To be implemented in subclasses
  inline
  bool isValidFeature(VM vm, nativeint feature);

  inline
  UnstableNode getValueAt(VM vm, nativeint feature);
  */
};

}

#endif // __DATATYPESHELPERS_DECL_H
