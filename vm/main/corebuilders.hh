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

#ifndef __COREBUILDERS_H
#define __COREBUILDERS_H

#include "mozartcore-decl.hh"

#include "coredatatypes-decl.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

/**
 * Build unstable nodes from primitive C++ values
 *
 * The trivialBuild() functions are a bunch of overloads for creating an
 * UnstableNode from a primitive C++ value.
 * E.g., applying trivialBuild() on a nativeint will return a node whose type
 * is SmallInt.
 *
 * It is useful to have these methods be overloads, so that they can be used
 * in templated code. See buildTuple() for a not-so-trivial example.
 */

inline
UnstableNode trivialBuild(VM vm, nativeint value) {
  return SmallInt::build(vm, value);
}

inline
UnstableNode trivialBuild(VM vm, size_t value) {
  return SmallInt::build(vm, value);
}

namespace internal {
  struct AlternativeToInt {
    operator nativeint() { return 0; }
  };

  typedef typename std::conditional<
    std::is_same<int, nativeint>::value,
    AlternativeToInt, int>::type intIfDifferentFromNativeInt;
}

inline
UnstableNode trivialBuild(VM vm, internal::intIfDifferentFromNativeInt value) {
  return SmallInt::build(vm, value);
}

inline
UnstableNode trivialBuild(VM vm, bool value) {
  return Boolean::build(vm, value);
}

inline
UnstableNode trivialBuild(VM vm, double value) {
  return Float::build(vm, value);
}

inline
UnstableNode trivialBuild(VM vm, const char16_t* value) {
  return Atom::build(vm, value);
}

inline
UnstableNode trivialBuild(VM vm, builtins::BaseBuiltin& builtin) {
  return BuiltinProcedure::build(vm, builtin);
}

inline
UnstableNode trivialBuild(VM vm, UnstableNode&& node) {
  return std::move(node);
}

inline
UnstableNode trivialBuild(VM vm, UnstableNode& node) {
  return UnstableNode(vm, node);
}

inline
UnstableNode trivialBuild(VM vm, RichNode node) {
  return UnstableNode(vm, node);
}

// Initialize the elements of an aggregate

template <size_t i, class T, class U>
inline
void staticInitElement(VM vm, TypedRichNode<T> aggregate, U&& value) {
  UnstableNode valueNode = trivialBuild(vm, std::forward<U>(value));
  aggregate.initElement(vm, i, valueNode);
}

template <size_t i, class T>
inline
void staticInitElementsInner(VM vm, TypedRichNode<T> aggregate) {
}

template <size_t i, class T, class U, class... Rest>
inline
void staticInitElementsInner(VM vm, TypedRichNode<T> aggregate,
                             U&& ithValue, Rest&&... rest) {
  staticInitElement<i, T, U>(vm, aggregate, std::forward<U>(ithValue));
  staticInitElementsInner<i+1, T>(vm, aggregate, std::forward<Rest>(rest)...);
}

/**
 * Initialize statically the elements of an aggregate (e.g., tuple)
 * @param vm          Contextual VM
 * @param aggregate   The aggregate to initialize, as a typed RichNode.
 * @param args...     The elements to initialize
 *                    (in any form supported by trivialBuild())
 */
template <class T, class... Args>
inline
void staticInitElements(VM vm, TypedRichNode<T> aggregate, Args&&... args) {
  staticInitElementsInner<0, T>(vm, aggregate, std::forward<Args>(args)...);
}

// Build a tuple

template <class LT>
inline
UnstableNode buildTuple(VM vm, LT&& label) {
  // Degenerated case, which is just an atom
  return trivialBuild(vm, std::forward<LT>(label));
}

/**
 * Build an Oz tuple inside a node, with its label and fields
 * The label and the arguments can be in any form supported by trivialBuild().
 * @param vm        Contextual VM
 * @param label     Label of the tuple
 * @param args...   Fields of the tuple
 */
template <class LT, class... Args>
inline
UnstableNode buildTuple(VM vm, LT&& label, Args&&... args) {
  UnstableNode labelNode = trivialBuild(vm, std::forward<LT>(label));
  UnstableNode result = Tuple::build(vm, sizeof...(args), labelNode);
  staticInitElements<Tuple>(vm, RichNode(result).as<Tuple>(),
                            std::forward<Args>(args)...);
  return result;
}

/**
 * Build a constant arity, with its label and features
 * The label and the features can be in any form supported by trivialBuild().
 * @param vm        Contextual VM
 * @param label     Label of the arity
 * @param args...   Features of the arity
 */
template <class LT, class... Args>
inline
UnstableNode buildArity(VM vm, LT&& label, Args&&... args) {
  UnstableNode tuple = buildTuple(vm, std::forward<LT>(label),
                                  std::forward<Args>(args)...);
  return Arity::build(vm, tuple);
}

}

#endif // MOZART_GENERATOR

#endif // __COREBUILDERS_H
