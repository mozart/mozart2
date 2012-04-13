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

#ifndef __MATCHDSL_H
#define __MATCHDSL_H

#include "mozartcore-decl.hh"

#include "coredatatypes-decl.hh"
#include "coreinterfaces.hh"

/**
 * DSL for writing pattern matching on Oz values in C++ code
 *
 * This file defines a number of rather obscure classes and methods, but the
 * one you probably need most is the method `matchesTuple()`. It is meant to
 * allow you to express any Oz-like pattern matching in C++ in a
 * straightforward way.
 *
 * Here's an example. In Oz:
 *
 *   proc {DoSomething Value}
 *      case Value
 *      of X#42#Y then {Show X} {Show Y}
 *      [] Z andthen {IsInt Z} then {Show Value}
 *      end
 *   end
 *
 * In C++:
 *
 *   OpResult doSomething(VM vm, RichNode value) {
 *     using namespace mozart::patternmatching;
 *
 *     OpResult result = OpResult::proceed(); // important!
 *     UnstableNode X, Y;
 *
 *     if (matchesTuple(vm, result, value, u"#",
 *                      capture(X), 42, capture(Y))) {
 *       show(X);
 *       show(Y);
 *     } else if (matches(vm, result, value, wildcard<SmallInt>())) {
 *       show(value);
 *     } else if (result.isProceed()) {
 *       // value does not match any of the patterns, usually it's a type error
 *       return raiseTypeError(vm, u"int or 42-pair", value);
 *     } else {
 *       // the match blocks on a transient, or failed, etc.
 *       // the `result` contains the outcome of the operation
 *       return result;
 *     }
 *
 *     return OpResult::proceed();
 *   }
 *
 * The first match can be rewritten with matchesSharp():
 *
 *     if (matchesSharp(vm, result, value, capture(X), 42, capture(Y))) {
 *
 * It's not that much shorter, but that function could someday be optimized
 * more seriously than the generic matchesTuple().
 *
 * More importantly, the second match can be rewritten using a primitive
 * capture:
 *
 *     // [...]
 *     nativeint intValue;
 *     // [...]
 *     } else if (matches(vm, result, value, capture(intValue))) {
 *       cout << intValue << endl;
 *     } else [...]
 *
 * This is much better, as it will eventually capture any value that can be
 * assimilated to a nativeint. Besides, it is more efficient, because the
 * nativeint value is captured when the type test has already been done.
 *
 * Finally, it is so common that the two last clauses read as above, i.e., that
 * a no-match means a type error, and a non-proceed result must be passed
 * through, that there is a convenience matchTypeError() function for this.
 * Hence the two clauses can be rewritten as:
 *
 *     } else {
 *       return matchTypeError(vm, result, value, u"int or 42-pair");
 *     }
 *
 * The whole example thus looks like this:
 *
 *   OpResult doSomething(VM vm, RichNode value) {
 *     using namespace mozart::patternmatching;
 *
 *     OpResult result = OpResult::proceed(); // important!
 *     UnstableNode X, Y;
 *     nativeint intValue;
 *
 *     if (matchesSharp(vm, result, value, capture(X), 42, capture(Y))) {
 *       show(X);
 *       show(Y);
 *     } else if (matches(vm, result, value, capture(intValue))) {
 *       cout << intValue << endl;
 *     } else {
 *       return matchTypeError(vm, result, value, u"int or 42-pair");
 *     }
 *
 *     return OpResult::proceed();
 *   }
 *
 *
 * OK now we're done with the example. The API follows.
 *
 * The two basic possible entry points are:
 *
 *   bool matches(vm, result, value, pattern)
 *     which matches the given pattern
 *
 *   bool matchesTuple(vm, result, value, labelPattern, fieldsPatterns...)
 *     which matches a tuple whose label and fields match the given patterns
 *
 * The following two methods conveniently match on usual tuples:
 *
 *   bool matchesCons(vm, result, value, headPattern, tailPattern)
 *     ::= matchesTuple(vm, result, value, u"|", headPattern, tailPattern)
 *
 *   bool matchesSharp(vm, result, value, fieldsPatterns...)
 *     ::= matchesTuple(vm, result, value, u"#", fieldsPatterns...)
 *
 * All the patterns can be one of the following:
 *
 * * Simple C++ values, such as int, const char16_t*, bool.
 *   The value matches if it is equal to the given value.
 * * A RichNode `node`.
 *   The value matches if it is equal to `node` (tested with mozart::equals()).
 * * wildcard().
 *   The value always matches.
 * * wildcard<T>() where T is a datatype of the Object Model.
 *   The value matches iff its actual type() is T::type().
 * * capture(X) where X is a declared UnstableNode.
 *   Like wildcard(), plus the value is copy()'ed into X.
 * * capture<T>(X) where T is a datatype, and X a declared UnstableNode.
 *   Like wildcard<T>(), plus the value is copy()'ed into X.
 * * capture(x) where x is a declared nativeint.
 *   Matches any SmallInt-like, plus its actual value is stored into x.
 * * capture(x) where x is a declared bool.
 *   Matches any Boolean-like, plus its actual value is stored into x.
 *
 * Upon a successful match, `result` is untouched, and true is returned.
 * Upon a failed match, `result` is untouched, and false is returned.
 *
 * Upon an undecidable match (e.g., because of an unbound value), `result` is
 * set to the appropriate OpResult (e.g., a waitFor()), and false is
 * returned.
 *
 * Moreover, if, on entry, result.isProceed() is false, then the match
 * functions do nothing and return false. This allows to chain several matches
 * easily.
 */

#ifndef MOZART_GENERATOR

namespace mozart {

namespace patternmatching {

namespace internal {

/**
 * Utility function used to ensure that static_assert() is evaluated upon
 * template instantiation, not before.
 */
template <class T>
struct LateStaticAssert {
  static const bool value = false;
};

/** Marker to designate any type */
struct AnyType {};

/** Pattern that matches any value of type T */
template <class T>
struct WildcardPattern {
};

/** Pattern that matches any value of type T, and captures the value */
template <class T>
struct CapturePattern {
  CapturePattern(UnstableNode& node) : node(node) {}

  UnstableNode& node;
};

template <class T>
struct PrimitiveCapturePattern {
  PrimitiveCapturePattern(T& value) : value(value) {}

  T& value;
};

/**
 * Wait for a value if it is a transient
 */
inline
void waitForIfTransient(VM vm, OpResult& result, RichNode value) {
  if (value.isTransient())
    result = OpResult::waitFor(vm, value);
}

/**
 * Internal equivalent of matches().
 * Assumes that result.isProceed() is true on entry.
 * This function is meant to be specialized on types of pattern.
 */
template <class T>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value, T pattern) {
  static_assert(internal::LateStaticAssert<T>::value,
                "Invalid type of pattern");
  return false;
}

/**
 * Like matchesSimple(), but expects a StableNode* instead of a RichNode.
 */
template <class T>
inline
bool matchesStable(VM vm, OpResult& result, StableNode* value, T pattern) {
  UnstableNode temp(vm, *value);
  return matchesSimple(vm, result, RichNode(temp), pattern);
}

/** Base case of the below */
template <size_t i, class T>
inline
bool matchesElementsAgainstPatternList(VM vm, OpResult& result,
                                       TypedRichNode<T> aggregate) {
  return result.isProceed();
}

/**
 * Matches the elements of an aggregate against a list of patterns
 * Succeeds iff elements match pairwise with their pattern
 *   forall j : i <= j < (i + sizeof...(patterns))
 * @param i   Starting index in the aggregate's elements
 */
template <size_t i, class T, class U, class... Rest>
inline
bool matchesElementsAgainstPatternList(
  VM vm, OpResult& result, TypedRichNode<T> aggregate,
  U ithPattern, Rest... restPatterns) {

  if (!matchesStable(vm, result, aggregate.getElement(i), ithPattern))
    return false;

  return matchesElementsAgainstPatternList<i+1, T>(
    vm, result, aggregate, restPatterns...);
}

// Here we begin the various specializations of matchesSimple<T>()

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value, nativeint pattern) {
  bool res = false;
  result = IntegerValue(value).equalsInteger(vm, pattern, &res);
  return result.isProceed() && res;
}

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value, size_t pattern) {
  return matchesSimple(vm, result, value, (nativeint) pattern);
}

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value,
                   ::mozart::internal::intIfDifferentFromNativeInt pattern) {
  return matchesSimple(vm, result, value, (nativeint) pattern);
}

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value, bool pattern) {
  BoolOrNotBool boolValue = bNotBool;
  result = BooleanValue(value).valueOrNotBool(vm, &boolValue);
  return result.isProceed() && (boolValue == (pattern ? bTrue : bFalse));
}

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value,
                   const char16_t* pattern) {
  if (!value.is<Atom>()) {
    internal::waitForIfTransient(vm, result, value);
    return false;
  }

  size_t length = value.as<Atom>().value()->length();
  const char16_t* valueContents = value.as<Atom>().value()->contents();

  return std::char_traits<char16_t>::compare(
    valueContents, pattern, length) == 0;
}

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value, RichNode pattern) {
  bool res = false;
  result = equals(vm, value, pattern, &res);
  return result.isProceed() && res;
}

template <class T>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value,
                   WildcardPattern<T> pattern) {
  if (value.is<T>()) {
    return true;
  } else {
    internal::waitForIfTransient(vm, result, value);
    return false;
  }
}

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value,
                   WildcardPattern<AnyType> pattern) {
  return true;
}

template <class T>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value,
                   CapturePattern<T> pattern) {
  if (value.is<T>()) {
    pattern.node.copy(vm, value);
    return true;
  } else {
    internal::waitForIfTransient(vm, result, value);
    return false;
  }
}

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value,
                   CapturePattern<AnyType> pattern) {
  pattern.node.copy(vm, value);
  return true;
}

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value,
                   PrimitiveCapturePattern<nativeint> pattern) {
  if (value.is<SmallInt>()) {
    pattern.value = value.as<SmallInt>().value();
    return true;
  } else {
    internal::waitForIfTransient(vm, result, value);
    return false;
  }
}

template <>
inline
bool matchesSimple(VM vm, OpResult& result, RichNode value,
                   PrimitiveCapturePattern<bool> pattern) {
  if (value.is<Boolean>()) {
    pattern.value = value.as<Boolean>().value();
    return true;
  } else {
    internal::waitForIfTransient(vm, result, value);
    return false;
  }
}

} // namespace internal

//////////////////////////
// The public interface //
//////////////////////////

/**
 * Build a (typed) wildcard pattern
 * wildcard() matches any value
 * wildcard<T>() matches any value of type T
 */
template <class T = internal::AnyType>
inline
internal::WildcardPattern<T> wildcard() {
  return internal::WildcardPattern<T>();
}

/**
 * Build a (typed) capture pattern
 * capture(node) matches any value and captures it in `node`
 * capture<T>(node) matches any value of type T and captures it in `node`
 */
template <class T = internal::AnyType>
inline
internal::CapturePattern<T> capture(UnstableNode& node) {
  return internal::CapturePattern<T>(node);
}

/**
 * Build a typed primitive capture pattern
 * capture(value) matches any value of an Oz type corresponding to the C++
 *   type of `value`, and captures its value in `value`
 */
template <class T>
inline
internal::PrimitiveCapturePattern<T> capture(T& value) {
  return internal::PrimitiveCapturePattern<T>(value);
}

/**
 * Simple form of pattern matching (not for aggregates)
 * See comments at the beginning of the file for usage.
 */
template <class T>
inline
bool matches(VM vm, OpResult& result, RichNode value, T pattern) {
  return result.isProceed() &&
    internal::matchesSimple(vm, result, value, pattern);
}

/**
 * Pattern matching for tuples
 * See comments at the beginning of the file for usage.
 */
template <class LT, class... Args>
inline
bool matchesTuple(VM vm, OpResult& result, RichNode value,
                  LT labelPat, Args... fieldsPats) {
  if (!result.isProceed())
    return false;

  if (value.type() != Tuple::type()) {
    internal::waitForIfTransient(vm, result, value);
    return false;
  }

  auto tuple = value.as<Tuple>();

  if (tuple.getWidth() != sizeof...(Args))
    return false;

  if (!internal::matchesStable(vm, result, tuple.getLabel(), labelPat))
    return false;

  return internal::matchesElementsAgainstPatternList<0>(
    vm, result, tuple, fieldsPats...);
}

/**
 * Pattern matching for a cons
 * See comments at the beginning of the file for usage.
 */
template <class HT, class TT>
inline
bool matchesCons(VM vm, OpResult& result, RichNode value,
                 HT head, TT tail) {
  return matchesTuple(vm, result, value, u"|", head, tail);
}

/**
 * Pattern matching for a # tuple
 * See comments at the beginning of the file for usage.
 */
template <class... Args>
inline
bool matchesSharp(VM vm, OpResult& result, RichNode value,
                  Args... fieldsPats) {
  return matchesTuple(vm, result, value, u"#", fieldsPats...);
}

/**
 * Convenience "else clause" when no match means a type error
 * See comments at the beginning of the file for usage.
 */
inline
OpResult matchTypeError(VM vm, OpResult& result, RichNode value,
                        const char16_t* expected) {
  if (result.isProceed())
    return raiseTypeError(vm, expected, value);
  else
    return result;
}

} // namespace patternmatching

} // namespace mozart

#endif // MOZART_GENERATOR

#endif // __MATCHDSL_H
