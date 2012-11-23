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

#ifndef __UTILS_DECL_H
#define __UTILS_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

///////////////////////////////////////////////////////
// Extracting arguments from Oz values to C++ values //
///////////////////////////////////////////////////////

template <class T>
struct PrimitiveTypeToExpectedAtom {
  inline
  static atom_t result(VM vm);
};

template <>
struct PrimitiveTypeToExpectedAtom<internal::intIfDifferentFromNativeInt> {
  inline
  static atom_t result(VM vm);
};

template <>
struct PrimitiveTypeToExpectedAtom<size_t> {
  inline
  static atom_t result(VM vm);
};

template <class T>
inline
T getArgument(VM vm, RichNode argValue, const nchar* expectedType);

template <class T>
inline
T getArgument(VM vm, RichNode argValue);

template <>
inline
UnstableNode getArgument(VM vm, RichNode argValue);

template <>
inline
RichNode getArgument(VM vm, RichNode argValue);

template <class T>
inline
T* getPointerArgument(VM vm, RichNode argValue, const nchar* expectedType);

template <class T>
inline
T* getPointerArgument(VM vm, RichNode argValue);

inline
void requireFeature(VM vm, RichNode feature);

//////////////////////////////////
// Working with Oz lists in C++ //
//////////////////////////////////

/**
 * Helper to build an Oz list in C++.
 * Use push_front and/or push_back to build the list. Then call get() ONCE.
 * After calling get(), any interaction with the builder is undefined behavior.
 */
class OzListBuilder {
public:
  inline
  OzListBuilder(VM vm);

  template <class T>
  inline
  void push_front(VM vm, T&& value);

  template <class T>
  inline
  void push_back(VM vm, T&& value);

  inline
  UnstableNode get(VM vm);
private:
  UnstableNode _head;
  NodeHole _tail;
};

/**
 * Apply a function to each element of an Oz list
 *
 * Example: if list == `a|b|c|nil`, ozListForEach performs:
 *   f(a);
 *   f(b);
 *   f(c);
 */
template <class F>
inline
auto ozListForEach(VM vm, RichNode list, const F& f,
                   const nchar* expectedType)
    -> typename std::enable_if<function_traits<F>::arity == 1, void>::type;

/**
 * Apply a function to each element of an Oz list, with index
 *
 * Example: if list == `a|b|c|nil`, ozListForEach performs:
 *   f(a, 0);
 *   f(b, 1);
 *   f(c, 2);
 */
template <class F>
inline
auto ozListForEach(VM vm, RichNode list, const F& f,
                   const nchar* expectedType)
    -> typename std::enable_if<function_traits<F>::arity == 2, void>::type;

inline
size_t ozListLength(VM vm, RichNode list);

template <class C>
inline
std::basic_string<C> vsToString(VM vm, RichNode vs);

template <typename T>
inline
void sendToReadOnlyStream(VM vm, UnstableNode& stream, T&& value);

///////////////////////////////////////
// Dealing with non-idempotent steps //
///////////////////////////////////////

template <typename Step>
inline
auto protectNonIdempotentStep(VM vm, const nchar* identity, const Step& step)
    -> typename std::enable_if<!std::is_void<decltype(step())>::value,
                               decltype(step())>::type;

template <typename Step>
inline
auto protectNonIdempotentStep(VM vm, const nchar* identity, const Step& step)
    -> typename std::enable_if<std::is_void<decltype(step())>::value,
                               void>::type;

}

#endif // __UTILS_DECL_H
