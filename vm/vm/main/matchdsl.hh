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

#include <memory>

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
 *   void doSomething(VM vm, RichNode value) {
 *     using namespace mozart::patternmatching;
 *
 *     UnstableNode X, Y;
 *
 *     if (matchesTuple(vm, value, vm->coreatoms.sharp,
 *                      capture(X), 42, capture(Y))) {
 *       show(X);
 *       show(Y);
 *     } else if (matches(vm, value, wildcard<SmallInt>())) {
 *       show(value);
 *     } else {
 *       // value does not match any of the patterns, usually it's a type error
 *       return raiseTypeError(vm, MOZART_STR("int or 42-pair"), value);
 *     }
 *   }
 *
 * The first match can be rewritten with matchesSharp():
 *
 *     if (matchesSharp(vm, value, capture(X), 42, capture(Y))) {
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
 *     } else if (matches(vm, value, capture(intValue))) {
 *       cout << intValue << endl;
 *     } else [...]
 *
 * This is much better, as it will eventually capture any value that can be
 * assimilated to a nativeint. Besides, it is more efficient, because the
 * nativeint value is captured when the type test has already been done.
 *
 * The whole example thus looks like this:
 *
 *   void doSomething(VM vm, RichNode value) {
 *     using namespace mozart::patternmatching;
 *
 *     UnstableNode X, Y;
 *     nativeint intValue;
 *
 *     if (matchesSharp(vm, value, capture(X), 42, capture(Y))) {
 *       show(X);
 *       show(Y);
 *     } else if (matches(vm, value, capture(intValue))) {
 *       cout << intValue << endl;
 *     } else {
 *       return raiseTypeError(vm, MOZART_STR("int or 42-pair"), value);
 *     }
 *   }
 *
 *
 * OK now we're done with the example. The API follows.
 *
 * The two basic possible entry points are:
 *
 *   bool matches(vm, value, pattern)
 *     which matches the given pattern
 *
 *   bool matchesTuple(vm, value, labelPattern, fieldsPatterns...)
 *     which matches a tuple whose label and fields match the given patterns
 *
 * The following method conveniently match on #-tuples:
 *
 *   bool matchesSharp(vm, value, fieldsPatterns...)
 *     ::= matchesTuple(vm, value, vm->coreatoms.sharp, fieldsPatterns...)
 *
 * To match a |-pair (H|T), use the following method instead:
 *
 *   bool matchesCons(vm, value, headPattern, tailPattern)
 *
 * All the patterns can be one of the following:
 *
 * * Simple C++ values, such as nativeint, const char*, bool.
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
 * Upon a successful match, true is returned. Upon a failed match,
 * false is returned.
 *
 * Upon an undecidable match (e.g., because of an unbound value), the
 * appropriate exception is thrown.
 */

#ifndef MOZART_GENERATOR

namespace mozart {

namespace patternmatching {

/**
 * Metafunction from primitive type to the corresponding Oz type
 */
template <class T>
struct PrimitiveTypeToOzType {
  /// Defined only for the default thing - can be used in SFINAE
  typedef int no_result;
};

template <>
struct PrimitiveTypeToOzType<nativeint> {
  typedef SmallInt result;
};

template <>
struct PrimitiveTypeToOzType<atom_t> {
  typedef Atom result;
};

template <>
struct PrimitiveTypeToOzType<bool> {
  typedef Boolean result;
};

template <>
struct PrimitiveTypeToOzType<double> {
  typedef Float result;
};

template <>
struct PrimitiveTypeToOzType<unique_name_t> {
  typedef UniqueName result;
};

template <>
struct PrimitiveTypeToOzType<Runnable*> {
  typedef ReifiedThread result;
};

template <class T>
struct OzValueToPrimitiveValue {
  static bool call(VM vm, RichNode value, T& primitive) {
    typedef typename PrimitiveTypeToOzType<T>::result OzType;

    if (value.is<OzType>()) {
      primitive = value.as<OzType>().value();
      return true;
    } else {
      return false;
    }
  }
};

template <class T>
inline
bool ozValueToPrimitiveValue(VM vm, RichNode value, T& primitive) {
  return OzValueToPrimitiveValue<T>::call(vm, value, primitive);
}

template <>
struct OzValueToPrimitiveValue<char> {
  static bool call(VM vm, RichNode value, char& primitive) {
    if (value.is<SmallInt>()) {
      nativeint intValue = value.as<SmallInt>().value();

      if ((intValue >= 0) && (intValue < 256)) {
        primitive = (char) intValue;
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
};

template <class U>
struct OzValueToPrimitiveValue<std::shared_ptr<U> > {
private:
  typedef std::shared_ptr<U> T;

public:
  template <typename W = T,
            typename = typename PrimitiveTypeToOzType<W>::result>
  static bool call(VM vm, RichNode value, T& primitive, int dummy = 0) {
    // Duplicate of the original OzValueToPrimitiveValue<T>
    typedef typename PrimitiveTypeToOzType<T>::result OzType;

    if (value.is<OzType>()) {
      primitive = value.as<OzType>().value();
      return true;
    } else {
      return false;
    }
  }

  template <typename W = T,
            typename = typename PrimitiveTypeToOzType<W>::no_result>
  static bool call(VM vm, RichNode value, T& primitive, bool dummy = false) {
    if (value.is<ForeignPointer>() &&
        value.as<ForeignPointer>().isPointer<U>()) {
      primitive = value.as<ForeignPointer>().value<U>();
      return true;
    } else {
      return false;
    }
  }
};

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
void waitForIfTransient(VM vm, RichNode value) {
  if (value.isTransient())
    waitFor(vm, value);
}

/**
 * Internal equivalent of matches().
 * This function is meant to be specialized on types of pattern.
 */
template <class T>
inline
bool matchesSimple(VM vm, RichNode value, T pattern) {
  static_assert(internal::LateStaticAssert<T>::value,
                "Invalid type of pattern");
  return false;
}

/** Base case of the below */
template <size_t i, class T>
inline
bool matchesElementsAgainstPatternList(VM vm, TypedRichNode<T> aggregate) {
  return true;
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
  VM vm, TypedRichNode<T> aggregate,
  U ithPattern, Rest... restPatterns) {

  if (!matchesSimple(vm, *aggregate.getElement(i), ithPattern))
    return false;

  return matchesElementsAgainstPatternList<i+1, T>(
    vm, aggregate, restPatterns...);
}

// Here we begin the various specializations of matchesSimple<T>()

template <>
inline
bool matchesSimple(VM vm, RichNode value, nativeint pattern) {
  return IntegerValue(value).equalsInteger(vm, pattern);
}

template <>
inline
bool matchesSimple(VM vm, RichNode value, size_t pattern) {
  return matchesSimple(vm, value, (nativeint) pattern);
}

template <>
inline
bool matchesSimple(VM vm, RichNode value,
                   ::mozart::internal::intIfDifferentFromNativeInt pattern) {
  return matchesSimple(vm, value, (nativeint) pattern);
}

template <>
inline
bool matchesSimple(VM vm, RichNode value, bool pattern) {
  return BooleanValue(value).valueOrNotBool(vm) == (pattern ? bTrue : bFalse);
}

template <>
inline
bool matchesSimple(VM vm, RichNode value, unit_t pattern) {
  if (value.is<Unit>()) {
    return true;
  } else {
    internal::waitForIfTransient(vm, value);
    return false;
  }
}

template <>
inline
bool matchesSimple(VM vm, RichNode value, const nchar* pattern) {
  if (!value.is<Atom>()) {
    internal::waitForIfTransient(vm, value);
    return false;
  }

  size_t length = value.as<Atom>().value().length();
  const nchar* valueContents = value.as<Atom>().value().contents();

  return std::char_traits<nchar>::compare(
    valueContents, pattern, length) == 0;
}

template <>
inline
bool matchesSimple(VM vm, RichNode value, atom_t pattern) {
  if (!value.is<Atom>()) {
    internal::waitForIfTransient(vm, value);
    return false;
  }

  return value.as<Atom>().value() == pattern;
}

template <>
inline
bool matchesSimple(VM vm, RichNode value, unique_name_t pattern) {
  if (!value.is<UniqueName>()) {
    internal::waitForIfTransient(vm, value);
    return false;
  }

  return value.as<UniqueName>().value() == pattern;
}

template <>
inline
bool matchesSimple(VM vm, RichNode value, RichNode pattern) {
  return equals(vm, value, pattern);
}

template <class T>
inline
bool matchesSimple(VM vm, RichNode value, WildcardPattern<T> pattern) {
  if (value.is<T>()) {
    return true;
  } else {
    internal::waitForIfTransient(vm, value);
    return false;
  }
}

template <>
inline
bool matchesSimple(VM vm, RichNode value, WildcardPattern<AnyType> pattern) {
  return true;
}

template <class T>
inline
bool matchesSimple(VM vm, RichNode value, CapturePattern<T> pattern) {
  if (value.is<T>()) {
    pattern.node.copy(vm, value);
    return true;
  } else {
    internal::waitForIfTransient(vm, value);
    return false;
  }
}

template <>
inline
bool matchesSimple(VM vm, RichNode value, CapturePattern<AnyType> pattern) {
  pattern.node.copy(vm, value);
  return true;
}

template <class T>
inline
bool matchesSimple(VM vm, RichNode value, PrimitiveCapturePattern<T> pattern) {
  if (ozValueToPrimitiveValue<T>(vm, value, pattern.value)) {
    return true;
  } else {
    waitForIfTransient(vm, value);
    return false;
  }
}

template <>
inline
bool matchesSimple(VM vm, RichNode value,
                   PrimitiveCapturePattern<UnstableNode> pattern) {
  pattern.value.copy(vm, value);
  return true;
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
bool matches(VM vm, RichNode value, T pattern) {
  return internal::matchesSimple(vm, value, pattern);
}

/**
 * Pattern matching for tuples
 * See comments at the beginning of the file for usage.
 */
template <class LT, class... Args>
inline
bool matchesTuple(VM vm, RichNode value, LT labelPat, Args... fieldsPats) {
  if (value.type() != Tuple::type()) {
    internal::waitForIfTransient(vm, value);
    return false;
  }

  auto tuple = value.as<Tuple>();

  if (tuple.getWidth() != sizeof...(Args))
    return false;

  if (!internal::matchesSimple(vm, *tuple.getLabel(), labelPat))
    return false;

  return internal::matchesElementsAgainstPatternList<0>(
    vm, tuple, fieldsPats...);
}

/**
 * Pattern matching for a cons
 * See comments at the beginning of the file for usage.
 */
template <class HT, class TT>
inline
bool matchesCons(VM vm, RichNode value, HT head, TT tail) {
  if (value.type() != Cons::type()) {
    internal::waitForIfTransient(vm, value);
    return false;
  }

  auto cons = value.as<Cons>();

  return internal::matchesSimple(vm, *cons.getHead(), head) &&
    internal::matchesSimple(vm, *cons.getTail(), tail);
}

/**
 * Pattern matching for a # tuple
 * See comments at the beginning of the file for usage.
 */
template <class... Args>
inline
bool matchesSharp(VM vm, RichNode value, Args... fieldsPats) {
  return matchesTuple(vm, value, vm->coreatoms.sharp, fieldsPats...);
}

/**
 * Pattern matching for variadic tuples
 * See comments at the beginning of the file for usage.
 */
template <class LT, class... Args>
inline
bool matchesVariadicTuple(VM vm, RichNode value,
                          size_t& argc, StaticArray<StableNode>& args,
                          LT labelPat, Args... fieldsPats) {
  constexpr size_t fixedArgc = sizeof...(Args);

  if (value.type() != Tuple::type()) {
    if (fixedArgc == 0) {
      // If we expect 0 fixed arguments, then an atom is a valid input
      if (internal::matchesSimple(vm, value, labelPat)) {
        argc = 0;
        args = nullptr;
        return true;
      }
    }

    internal::waitForIfTransient(vm, value);
    return false;
  }

  // Actual matching
  auto tuple = value.as<Tuple>();

  if (tuple.getWidth() < fixedArgc)
    return false;

  if (!internal::matchesSimple(vm, *tuple.getLabel(), labelPat))
    return false;

  if (!internal::matchesElementsAgainstPatternList<0>(
      vm, tuple, fieldsPats...))
    return false;

  // Fill the captured variadic arguments
  argc = tuple.getWidth() - fixedArgc;
  args = tuple.getElementsArray().drop(fixedArgc);

  return true;
}

/**
 * Pattern matching for variadic # tuples
 * See comments at the beginning of the file for usage.
 */
template <class... Args>
inline
bool matchesVariadicSharp(VM vm, RichNode value,
                          size_t& argc, StaticArray<StableNode>& args,
                          Args... fieldsPats) {
  return matchesVariadicTuple(vm, value,
                              argc, args, vm->coreatoms.sharp, fieldsPats...);
}

} // namespace patternmatching

} // namespace mozart

#endif // MOZART_GENERATOR

#endif // __MATCHDSL_H
