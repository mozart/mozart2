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

#ifndef __OZCALLS_DECL_H
#define __OZCALLS_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

namespace ozcalls {

//////////////////////////////
// Calling Oz code from C++ //
//////////////////////////////

namespace internal {
  template <typename T>
  struct OutputParam {
    OutputParam(T& value): value(value) {}
    T& value;
  };
}

template <typename T>
inline
internal::OutputParam<T> out(T& value) {
  return internal::OutputParam<T>(value);
}

inline
void asyncOzCall(VM vm, Space* space, RichNode callable);

template <typename... Args>
inline
void asyncOzCall(VM vm, Space* space, RichNode callable, Args&&... args);

template <typename... Args>
inline
void asyncOzCall(VM vm, RichNode callable, Args&&... args);

template <typename... Args>
inline
void ozCall(VM vm, const nchar* identity, RichNode callable, Args&&... args);

template <typename... Args>
inline
void ozCall(VM vm, RichNode callable, Args&&... args);

namespace internal {
  template <typename Label, typename... Args>
  inline
  bool doReflectiveCall(VM vm, const nchar* identity, UnstableNode& stream,
                        Label&& label, Args&&... args);
}

} // namespace ozcalls

} // namespace mozart

#endif // __OZCALLS_DECL_H
