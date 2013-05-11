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
#include "utils-decl.hh"

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
 *     RichNode X, Y;
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
 *     RichNode X, Y;
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
 * * capture(X) where X is a declared UnstableNode or RichNode.
 *   Like wildcard(), plus the value is copy()'ed into X.
 * * capture(X) where X is a declared value of a C++ type T.
 *   The value matches if it is the Oz pendant of a value of type T. The C++
 *   value is captured in X.
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
template <typename T>
struct PrimitiveTypeToOzType {
};

/**
 * Metafunction testing whether PrimitiveTypeToOzType is defined for T
 */
template <typename T>
struct HasPrimitiveTypeToOzType {
private:
  template <typename W = T,
            typename = typename PrimitiveTypeToOzType<W>::result>
  static constexpr bool test(int) {
    return true;
  }

  static constexpr bool test(...) {
    return false;
  }
public:
  static constexpr bool value = test(0);
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

template <>
struct PrimitiveTypeToOzType<GlobalNode*> {
  typedef ReifiedGNode result;
};

template <typename T, typename Enable = void>
struct OzValueToPrimitiveValue {
  static_assert(mozart::internal::LateStaticAssert<T>::value,
                "Invalid type for OzValueToPrimitiveValue");

#ifdef IN_IDE_PARSER
  inline static bool call(VM vm, RichNode value, T& primitive);
#endif
};

template <typename T>
inline
bool ozValueToPrimitiveValue(VM vm, RichNode value, T& primitive) {
  return OzValueToPrimitiveValue<T>::call(vm, value, primitive);
}

template <typename T>
struct OzValueToPrimitiveValue<T,
  typename std::enable_if<HasPrimitiveTypeToOzType<T>::value>::type> {

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

template <>
struct OzValueToPrimitiveValue<mozart::internal::intIfDifferentFromNativeInt> {
  static bool call(VM vm, RichNode value, int& primitive) {
    if (value.is<SmallInt>()) {
      nativeint intValue = value.as<SmallInt>().value();

      if ((intValue >= std::numeric_limits<int>::min()) &&
          (intValue <= std::numeric_limits<int>::max())) {
        primitive = (int) intValue;
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
};

template <>
struct OzValueToPrimitiveValue<size_t> {
  static bool call(VM vm, RichNode value, size_t& primitive) {
    if (value.is<SmallInt>()) {
      nativeint intValue = value.as<SmallInt>().value();

      if (intValue >= 0) {
        primitive = (size_t) intValue;
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
};

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

template <>
struct OzValueToPrimitiveValue<unsigned char> {
  static bool call(VM vm, RichNode value, unsigned char& primitive) {
    if (value.is<SmallInt>()) {
      nativeint intValue = value.as<SmallInt>().value();

      if ((intValue >= 0) && (intValue < 256)) {
        primitive = (unsigned char) intValue;
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
};

template <>
struct OzValueToPrimitiveValue<char32_t> {
  static bool call(VM vm, RichNode value, char32_t& primitive) {
    if (value.is<SmallInt>()) {
      nativeint intValue = value.as<SmallInt>().value();

      if (isValidCodePoint(intValue)) {
        primitive = (char32_t) intValue;
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
};

template <>
struct OzValueToPrimitiveValue<UUID> {
  static bool call(VM vm, RichNode value, UUID& primitive) {
    if (value.is<ByteString>()) {
      // Fast path for a raw ByteString
      auto& bytes = value.as<ByteString>().value();
      if (bytes.length == (nativeint) UUID::byte_count) {
        primitive = UUID(bytes.string);
        return true;
      } else {
        return false;
      }
    } if (ozVBSLengthForBufferNoRaise(vm, value) == (nativeint) UUID::byte_count) {
      std::vector<unsigned char> bytes;
      ozVBSGet(vm, value, UUID::byte_count, bytes);
      primitive = UUID(bytes.data());
      return true;
    } else {
      return false;
    }
  }
};

template <class U>
struct OzValueToPrimitiveValue<std::shared_ptr<U>,
  typename std::enable_if<!HasPrimitiveTypeToOzType<std::shared_ptr<U>>::value>::type> {

  static bool call(VM vm, RichNode value, std::shared_ptr<U>& primitive) {
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

/** Pattern that matches any value */
struct WildcardPattern {
};

/** Pattern that matches a value of the appropriate type given a C++ type */
template <class T>
struct CapturePattern {
  explicit CapturePattern(T& value) : value(value) {}

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

} // namespace internal

/** Core match function, meant to be specialized on the pattern type */
template <typename T, typename Enable = void>
struct Matcher {
  static_assert(mozart::internal::LateStaticAssert<T>::value,
                "Invalid type of pattern");

#ifdef IN_IDE_PARSER
  inline static bool matches(VM vm, RichNode value, T pattern);
#endif
};

namespace internal {

/** Base case of the below */
template <size_t i>
inline
bool matchesElementsAgainstPatternList(VM vm,
                                       StaticArray<StableNode> elements) {
  return true;
}

/**
 * Matches the elements of an aggregate against a list of patterns
 * Succeeds iff elements match pairwise with their pattern
 *   forall j : i <= j < (i + sizeof...(patterns))
 * @param i   Starting index in the aggregate's elements
 */
template <size_t i, class IthPat, class... Rest>
inline
bool matchesElementsAgainstPatternList(
  VM vm, StaticArray<StableNode> elements,
  IthPat ithPattern, Rest... restPatterns) {

  if (!Matcher<IthPat>::matches(vm, elements[i], ithPattern))
    return false;

  return matchesElementsAgainstPatternList<i+1>(vm, elements, restPatterns...);
}

} // namespace internal

// Here we begin the various specializations of Matcher<T>

template <typename T>
struct Matcher<T, typename std::enable_if<HasPrimitiveTypeToOzType<T>::value>::type> {
  static bool matches(VM vm, RichNode value, T pattern) {
    typedef typename PrimitiveTypeToOzType<T>::result OzType;

    if (value.is<OzType>()) {
      return value.as<OzType>().value() == pattern;
    } else {
      internal::waitForIfTransient(vm, value);
      return false;
    }
  }
};

template <>
struct Matcher<size_t> {
  static bool matches(VM vm, RichNode value, size_t pattern) {
    return Matcher<nativeint>::matches(vm, value, (nativeint) pattern);
  }
};

template <>
struct Matcher<mozart::internal::intIfDifferentFromNativeInt> {
  static bool matches(VM vm, RichNode value, int pattern) {
    return Matcher<nativeint>::matches(vm, value, (nativeint) pattern);
  }
};

template <>
struct Matcher<unit_t> {
  static bool matches(VM vm, RichNode value, unit_t pattern) {
    if (value.is<Unit>()) {
      return true;
    } else {
      internal::waitForIfTransient(vm, value);
      return false;
    }
  }
};

template <>
struct Matcher<const nchar*> {
  static bool matches(VM vm, RichNode value, const nchar* pattern) {
    if (value.is<Atom>()) {
      size_t length = value.as<Atom>().value().length();
      const nchar* valueContents = value.as<Atom>().value().contents();

      return std::char_traits<nchar>::compare(
        valueContents, pattern, length) == 0;
    } else {
      internal::waitForIfTransient(vm, value);
      return false;
    }
  }
};

template <>
struct Matcher<RichNode> {
  static bool matches(VM vm, RichNode value, RichNode pattern) {
    return equals(vm, value, pattern);
  }
};

template <>
struct Matcher<internal::WildcardPattern> {
  static bool matches(VM vm, RichNode value,
                      internal::WildcardPattern pattern) {
    return true;
  }
};

template <>
struct Matcher<internal::CapturePattern<UnstableNode>> {
  static bool matches(VM vm, RichNode value,
                      internal::CapturePattern<UnstableNode> pattern) {
    pattern.value.copy(vm, value);
    return true;
  }
};

template <>
struct Matcher<internal::CapturePattern<RichNode>> {
  static bool matches(VM vm, RichNode value,
                      internal::CapturePattern<RichNode> pattern) {
    value.ensureStable(vm);
    pattern.value = value;
    return true;
  }
};

template <typename T>
struct Matcher<internal::CapturePattern<T>> {
  static bool matches(VM vm, RichNode value,
                      internal::CapturePattern<T> pattern) {
    if (ozValueToPrimitiveValue<T>(vm, value, pattern.value)) {
      return true;
    } else {
      internal::waitForIfTransient(vm, value);
      return false;
    }
  }
};

//////////////////////////
// The public interface //
//////////////////////////

/**
 * Build a wildcard pattern
 * wildcard() matches any value
 */
inline
internal::WildcardPattern wildcard() {
  return internal::WildcardPattern();
}

/**
 * Build a capture pattern
 * capture(value) matches any value of an Oz type corresponding to the C++
 *   type of `value`, and captures its value in `value`
 * The type T can also be RichNode or UnstableNode, in which case any value
 * (including transients) will be matched and captured.
 */
template <class T>
inline
internal::CapturePattern<T> capture(T& value) {
  return internal::CapturePattern<T>(value);
}

/**
 * Simple form of pattern matching (not for aggregates)
 * See comments at the beginning of the file for usage.
 */
template <class T>
inline
bool matches(VM vm, RichNode value, T pattern) {
  return Matcher<T>::matches(vm, value, pattern);
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

  if (!matches(vm, *tuple.getLabel(), labelPat))
    return false;

  return internal::matchesElementsAgainstPatternList<0>(
    vm, tuple.getElementsArray(), fieldsPats...);
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

  return matches(vm, *cons.getHead(), head) &&
    matches(vm, *cons.getTail(), tail);
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
template <class LT>
inline
bool matchesVariadicTuple(VM vm, RichNode value,
                          size_t& argc, StaticArray<StableNode>& args,
                          LT labelPat) {
  if (value.type() != Tuple::type()) {
    // A value that matches the label pattern is a tuple with 0 elements
    argc = 0;
    args = nullptr;
    return matches(vm, value, labelPat);
  }

  // Actual matching
  auto tuple = value.as<Tuple>();

  if (!matches(vm, *tuple.getLabel(), labelPat))
    return false;

  // Fill the captured variadic arguments
  argc = tuple.getWidth();
  args = tuple.getElementsArray();

  return true;
}

/**
 * Pattern matching for variadic tuples with fixed fields at the beginning
 * See comments at the beginning of the file for usage.
 */
template <class LT, class... Args>
inline
bool matchesVariadicTuple(VM vm, RichNode value,
                          size_t& argc, StaticArray<StableNode>& args,
                          LT labelPat, Args... fieldsPats) {
  constexpr size_t fixedArgc = sizeof...(Args);
  static_assert(fixedArgc > 0,
                "The overload above should have been selected instead.");

  if (value.type() != Tuple::type()) {
    internal::waitForIfTransient(vm, value);
    return false;
  }

  // Actual matching
  auto tuple = value.as<Tuple>();

  if (tuple.getWidth() < fixedArgc)
    return false;

  if (!matches(vm, *tuple.getLabel(), labelPat))
    return false;

  if (!internal::matchesElementsAgainstPatternList<0>(
      vm, tuple.getElementsArray(), fieldsPats...))
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
