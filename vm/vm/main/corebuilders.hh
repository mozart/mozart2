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
 * The build() functions are a bunch of overloads for creating an
 * UnstableNode from a primitive C++ value.
 * E.g., applying build() on a nativeint will return a node whose type
 * is SmallInt.
 *
 * It is useful to have these methods be overloads, so that they can be used
 * in templated code. See buildTuple() for a not-so-trivial example.
 */

inline
UnstableNode build(VM vm, nativeint value) {
  return SmallInt::build(vm, value);
}

inline
UnstableNode build(VM vm, size_t value) {
  return SmallInt::build(vm, value);
}

inline
UnstableNode build(VM vm, internal::intIfDifferentFromNativeInt value) {
  return SmallInt::build(vm, value);
}

inline
UnstableNode build(VM vm, internal::int64IfDifferentFromNativeInt value) {
  // TODO Use BigInt if necessary
  return SmallInt::build(vm, (nativeint) value);
}

template <typename T>
inline
auto build(VM vm, T value)
    -> typename std::enable_if<std::is_same<T, bool>::value, UnstableNode>::type {
  return Boolean::build(vm, value);
}

inline
UnstableNode build(VM vm, unit_t value) {
  return Unit::build(vm);
}

inline
UnstableNode build(VM vm, double value) {
  return Float::build(vm, value);
}

inline
UnstableNode build(VM vm, const char* value) {
  return Atom::build(vm, value);
}

inline
UnstableNode build(VM vm, atom_t value) {
  return Atom::build(vm, value);
}

inline
UnstableNode build(VM vm, unique_name_t value) {
  return UniqueName::build(vm, value);
}

inline
UnstableNode build(VM vm, builtins::BaseBuiltin& builtin) {
  return BuiltinProcedure::build(vm, builtin);
}

inline
UnstableNode build(VM vm, const UUID& uuid) {
  unsigned char bytes[UUID::byte_count];
  uuid.toBytes(bytes);
  return ByteString::build(vm, newLString(vm, bytes, UUID::byte_count));
}

inline
UnstableNode build(VM vm, GlobalNode* gnode) {
  return ReifiedGNode::build(vm, gnode);
}

template <class T>
inline
UnstableNode build(VM vm, const std::shared_ptr<T>& value) {
  return ForeignPointer::build(vm, value);
}

inline
UnstableNode build(VM vm, UnstableNode&& node) {
  return std::move(node);
}

inline
UnstableNode build(VM vm, UnstableNode& node) {
  return UnstableNode(vm, node);
}

inline
UnstableNode build(VM vm, StableNode& node) {
  return UnstableNode(vm, node);
}

inline
UnstableNode build(VM vm, RichNode node) {
  return UnstableNode(vm, node);
}

// Initialize the elements of an aggregate

template <size_t i>
inline
void staticInitElementsInner(VM vm, StaticArray<StableNode> elements) {
}

template <size_t i, class IthType, class... Rest>
inline
void staticInitElementsInner(VM vm, StaticArray<StableNode> elements,
                             IthType&& ithValue, Rest&&... rest) {
  elements[i].init(vm, std::forward<IthType>(ithValue));
  staticInitElementsInner<i+1>(vm, elements, std::forward<Rest>(rest)...);
}

/**
 * Initialize statically the elements of an aggregate (e.g., tuple)
 * @param vm         Contextual VM
 * @param elements   The static array of StableNode's to initialize
 * @param args...    The values of the elements
 *                   (in any form supported by build())
 */
template <class... Args>
inline
void staticInitElements(VM vm, StaticArray<StableNode> elements, Args&&... args) {
  staticInitElementsInner<0>(vm, elements, std::forward<Args>(args)...);
}

// Build a tuple

template <class LT>
inline
UnstableNode buildTuple(VM vm, LT&& label) {
  // Degenerate case, which is just an atom
  return build(vm, std::forward<LT>(label));
}

/**
 * Build an Oz tuple inside a node, with its label and fields
 * The label and the arguments can be in any form supported by build().
 * This function must not be used to create a Cons, i.e. it must not be the
 * case that (label == '|' && sizeof...(args) == 2).
 * @param vm        Contextual VM
 * @param label     Label of the tuple
 * @param args...   Fields of the tuple
 */
template <class LT, class... Args>
inline
UnstableNode buildTuple(VM vm, LT&& label, Args&&... args) {
  // TODO Assert that we are not trying to create a Cons
  UnstableNode result = Tuple::build(vm, sizeof...(args),
                                     std::forward<LT>(label));
  staticInitElements(vm, RichNode(result).as<Tuple>().getElementsArray(),
                     std::forward<Args>(args)...);
  return result;
}

/**
 * Build an Oz #-tuple inside a node, with its fields
 * The arguments can be in any form supported by build().
 * @param vm        Contextual VM
 * @param args...   Fields of the #-tuple
 */
template <class... Args>
inline
UnstableNode buildSharp(VM vm, Args&&... args) {
  return buildTuple(vm, vm->coreatoms.sharp, std::forward<Args>(args)...);
}

/**
 * Build an Oz cons pair, with a head and a tail
 * The head and tail can be in any form supported by build().
 * @param vm     Contextual VM
 * @param head   Head of the cons
 * @param tail   Tail of the cons
 */
template <class HT, class TT>
inline
UnstableNode buildCons(VM vm, HT&& head, TT&& tail) {
  return Cons::build(vm, std::forward<HT>(head), std::forward<TT>(tail));
}

/**
 * Build the atom 'nil'
 */
inline
UnstableNode buildNil(VM vm) {
  return build(vm, vm->coreatoms.nil);
}

// Build a list

inline
UnstableNode buildList(VM vm) {
  return buildNil(vm);
}

/**
 * Build an Oz list with a statically known number of elements
 * The elements can be in any form supported by build().
 */
template <class Head, class... Tail>
inline
UnstableNode buildList(VM vm, Head&& head, Tail&&... tail) {
  return buildCons(vm, std::forward<Head>(head),
                   buildList(vm, std::forward<Tail>(tail)...));
}

/**
 * Build a constant arity, with its label and features
 * The label and the features can be in any form supported by build().
 * The features must be ordered! Typically features are atoms, so they must
 * be in lexicographical order.
 * @param vm        Contextual VM
 * @param label     Label of the arity
 * @param args...   Features of the arity
 */
template <class LT, class... Args>
inline
UnstableNode buildArity(VM vm, LT&& label, Args&&... args) {
  // TODO Assert that features are ordered
  UnstableNode result = Arity::build(vm, sizeof...(args),
                                     std::forward<LT>(label));
  staticInitElements(vm, RichNode(result).as<Arity>().getElementsArray(),
                     std::forward<Args>(args)...);
  return result;
}

/**
 * Build an Oz record inside a node, with its arity and fields
 * The arity and the arguments can be in any form supported by build().
 * The arity must not be a tuple arity, i.e., this cannot be used to build a
 * tuple.
 * @param vm        Contextual VM
 * @param arity     Arity of the record
 * @param args...   Fields of the record
 */
template <class AT, class... Args>
inline
UnstableNode buildRecord(VM vm, AT&& arity, Args&&... args) {
  // TODO Assert that we are not trying to create a Tuple
  UnstableNode result = Record::build(vm, sizeof...(args),
                                      std::forward<AT>(arity));
  staticInitElements(vm, RichNode(result).as<Record>().getElementsArray(),
                     std::forward<Args>(args)...);
  return result;
}

inline
UnstableNode buildPatMatConjunction(VM vm) {
  // Degenerate case, which is just a wildcard
  return PatMatCapture::build(vm, -1);
}

template <class PT>
inline
UnstableNode buildPatMatConjunction(VM vm, PT&& part) {
  // Degenerate case, which is just the only part
  return build(vm, std::forward<PT>(part));
}

/**
 * Build a pattern conjunction
 * The parts can be in any form supported by build().
 * @param vm         Contextual VM
 * @param parts...   Parts of the conjunction
 */
template <class... Args>
inline
UnstableNode buildPatMatConjunction(VM vm, Args&&... parts) {
  UnstableNode result = PatMatConjunction::build(vm, sizeof...(parts));
  staticInitElements(
    vm, RichNode(result).as<PatMatConjunction>().getElementsArray(),
    std::forward<Args>(parts)...);
  return result;
}

/**
 * Build an patmat open record inside a node, with its arity and fields
 * The arity and the arguments can be in any form supported by build().
 * @param vm        Contextual VM
 * @param arity     Arity of the open record
 * @param args...   Fields of the open record
 */
template <class AT, class... Args>
inline
UnstableNode buildPatMatOpenRecord(VM vm, AT&& arity, Args&&... args) {
  UnstableNode result = PatMatOpenRecord::build(vm, sizeof...(args),
                                                std::forward<AT>(arity));
  staticInitElements(
    vm, RichNode(result).as<PatMatOpenRecord>().getElementsArray(),
    std::forward<Args>(args)...);
  return result;
}

}

#endif // MOZART_GENERATOR

#endif // __COREBUILDERS_H
