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

#ifndef __RECORDS_DECL_H
#define __RECORDS_DECL_H

#include "mozartcore.hh"

///////////
// Tuple //
///////////

class Tuple;

#ifndef MOZART_GENERATOR
#include "Tuple-implem-decl.hh"
#endif

/**
 * Tuple (specialization of Record)
 */
template <>
class Implementation<Tuple>: StoredWithArrayOf<StableNode> {
public:
  typedef SelfType<Tuple>::Self Self;
  typedef SelfType<Tuple>::SelfReadOnlyView SelfReadOnlyView;
public:
  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements,
                 UnstableNode* label);

  inline
  Implementation(VM vm, size_t width, StaticArray<StableNode> _elements,
                 GC gc, SelfReadOnlyView from);

  size_t getArraySize() {
    return _width;
  }

  int getWidth() { return _width; }

  /**
   * Get the width of the tuple in a node
   */
  inline
  BuiltinResult width(Self self, VM vm, UnstableNode* result);

  inline
  BuiltinResult initElement(Self self, VM vm, size_t index,
                            UnstableNode* value);

  inline
  BuiltinResult dot(Self self, VM vm, UnstableNode* feature,
                    UnstableNode* result);

  inline
  BuiltinResult dotNumber(Self self, VM vm, nativeint feature,
                          UnstableNode* result);

  inline
  void printReprToStream(SelfReadOnlyView self, VM vm,
                         std::ostream* out, int depth);
private:
  StableNode _label;
  size_t _width;
};

#ifndef MOZART_GENERATOR
#include "Tuple-implem-decl-after.hh"
#endif

#endif // __RECORDS_DECL_H
