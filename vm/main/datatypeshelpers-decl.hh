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
private:
  typedef T* This;
  typedef typename SelfType<T>::Self Self;

public:
  // Literal interface

  inline
  OpResult isLiteral(Self self, VM vm, bool& result);

public:
  // Dottable interface

  inline
  OpResult lookupFeature(Self self, VM vm, RichNode feature,
                         bool& found, nullable<UnstableNode&> value);

  inline
  OpResult lookupFeature(Self self, VM vm, nativeint feature,
                         bool& found, nullable<UnstableNode&> value);

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

  inline
  OpResult testRecord(Self self, VM vm, RichNode arity, bool& result);

  inline
  OpResult testTuple(Self self, VM vm, RichNode label, size_t width,
                     bool& result);

  inline
  OpResult testLabel(Self self, VM vm, RichNode label, bool& result);
};

///////////////////////////
// IntegerDottableHelper //
///////////////////////////

template <class T>
class IntegerDottableHelper {
private:
  typedef T* This;
  typedef typename SelfType<T>::Self Self;

public:
  // Dottable interface

  inline
  OpResult lookupFeature(Self self, VM vm, RichNode feature,
                         bool& found, nullable<UnstableNode&> value);

  inline
  OpResult lookupFeature(Self self, VM vm, nativeint feature,
                         bool& found, nullable<UnstableNode&> value);

private:
  bool internalIsValidFeature(Self self, VM vm, nativeint feature) {
    return static_cast<This>(this)->isValidFeature(self, vm, feature);
  }

  void internalGetValueAt(Self self, VM vm, nativeint feature,
                          UnstableNode& result) {
    static_cast<This>(this)->getValueAt(self, vm, feature, result);
  }

protected:
  /* To be implemented in subclasses
  inline
  bool isValidFeature(Self self, VM vm, nativeint feature);

  inline
  void getValueAt(Self self, VM vm, nativeint feature, UnstableNode& result);
  */
};

}

#endif // __DATATYPESHELPERS_DECL_H
