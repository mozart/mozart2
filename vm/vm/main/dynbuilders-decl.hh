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

#ifndef __DYNBUILDERS_DECL_H
#define __DYNBUILDERS_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

template <class T>
inline
T identity(T it) {
  return it;
}

////////////
// Tuples //
////////////

inline
void requireLiteral(VM vm, RichNode label);

inline
UnstableNode makeTuple(VM vm, RichNode label, size_t width);

template <typename Label>
inline
UnstableNode makeTuple(VM vm, Label&& label, size_t width);

template <class T>
inline
UnstableNode buildTupleDynamic(VM vm, RichNode label, size_t width,
                               T elements[]);

template <class T, class ElemToValue>
inline
UnstableNode buildTupleDynamic(VM vm, RichNode label, size_t width,
                               T elements[], ElemToValue elemToValue);

///////////
// Lists //
///////////

template <class T>
inline
UnstableNode buildListDynamic(VM vm, size_t length, T elements[]);

template <class T, class ElemToValue>
inline
UnstableNode buildListDynamic(VM vm, size_t length, T elements[],
                              ElemToValue elemToValue);

/////////////
// Records //
/////////////

struct UnstableField {
  UnstableNode feature;
  UnstableNode value;
};

template <class T>
inline
void sortFeatures(VM vm, size_t width, T features[]);

template <class T>
inline
UnstableNode buildArityDynamic(VM vm, RichNode label, size_t width,
                               T elements[]);

inline
UnstableNode buildRecordDynamic(VM vm, RichNode label, size_t width,
                                UnstableField elements[]);

}

#endif // __DYNBUILDERS_DECL_H
