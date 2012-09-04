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

#ifndef __UTILS_H
#define __UTILS_H

#include "mozart.hh"

#include <type_traits>
#include <cstdio>

#ifndef MOZART_GENERATOR

namespace mozart {

///////////////////////////////////////////////////////
// Extracting arguments from Oz values to C++ values //
///////////////////////////////////////////////////////

// getArgument -----------------------------------------------------------------

template <class T>
atom_t PrimitiveTypeToExpectedAtom<T>::result(VM vm) {
  typedef typename patternmatching::PrimitiveTypeToOzType<T>::result OzType;
  return OzType::type()->getTypeAtom(vm);
}

atom_t PrimitiveTypeToExpectedAtom<internal::intIfDifferentFromNativeInt>::result(VM vm) {
  return vm->getAtom(MOZART_STR("integer"));
}

atom_t PrimitiveTypeToExpectedAtom<size_t>::result(VM vm) {
  return vm->getAtom(MOZART_STR("positive integer"));
}

atom_t PrimitiveTypeToExpectedAtom<UUID>::result(VM vm) {
  return vm->getAtom(MOZART_STR("UUID aka VBS of length 16"));
}

template <class T>
T getArgument(VM vm, RichNode argValue, const nchar* expectedType) {
  using namespace patternmatching;

  T result;

  if (!matches(vm, argValue, capture(result)))
    raiseTypeError(vm, expectedType, argValue);

  return result;
}

template <class T>
T getArgument(VM vm, RichNode argValue) {
  using namespace patternmatching;

  T result;

  if (!matches(vm, argValue, capture(result))) {
    atom_t expected = PrimitiveTypeToExpectedAtom<T>::result(vm);
    raiseTypeError(vm, expected, argValue);
  }

  return result;
}

template <>
UnstableNode getArgument(VM vm, RichNode argValue) {
  return { vm, argValue };
}

template <>
RichNode getArgument(VM vm, RichNode argValue) {
  argValue.ensureStable(vm);
  return argValue;
}

/* Important note to anyone thinking that getPointerArgument should return a
 * shared_ptr.
 *
 * It is *intentional* that we break the "safety" of shared_ptr by returning
 * the raw pointer here.
 *
 * The use case for getPointerArgument is, in a VM-called function, to extract
 * the pointer from a ForeignPointer.
 *
 * A first important observation is that code further in the method can throw a
 * Mozart exception (waiting, raise, etc.) for any kind of reason. Now,
 * Mozart exceptions are implemented with the setjmp/longjmp, which break
 * through all C++ try-catches in the stack, including the destructor of the
 * potential shared_ptr.
 * This would cause a memory leak!
 *
 * The other important observation is that the method will end before any
 * garbage collection can be performed. And only garbage collection can delete
 * the shared_ptr inside the ForeignPointer. Hence, its is already guaranteed
 * that the reference count will not reach 0 before the calling method ends and
 * stops using the returning pointer.
 *
 * Conclusion: we don't need to return a shared_ptr, and doing so would
 * actually cause *memory leaks* in some (non-rare) cases.
 */

template <class T>
T* getPointerArgument(VM vm, RichNode argValue, const nchar* expectedType) {
  return getArgument<std::shared_ptr<T>>(vm, argValue, expectedType).get();
}

template <class T>
T* getPointerArgument(VM vm, RichNode argValue) {
  return getArgument<std::shared_ptr<T>>(vm, argValue).get();
}

// requireFeature --------------------------------------------------------------

void requireFeature(VM vm, RichNode feature) {
  if (!feature.isFeature())
    PotentialFeature(feature).makeFeature(vm);
}

//////////////////////////////////
// Working with Oz lists in C++ //
//////////////////////////////////

// OzListBuilder ---------------------------------------------------------------

OzListBuilder::OzListBuilder(VM vm) {
  _head.init(vm);
  _tail = &_head;
}

template <class T>
void OzListBuilder::push_front(VM vm, T&& value) {
  _head = buildCons(vm, std::forward<T>(value), std::move(_head));
  if (_tail == &_head) {
    _tail = RichNode(_head).as<Cons>().getTail();
  }
}

template <class T>
void OzListBuilder::push_back(VM vm, T&& value) {
  auto cons = buildCons(vm, std::forward<T>(value), unit);
  auto newTail = RichNode(cons).as<Cons>().getTail();
  _tail.fill(vm, std::move(cons));
  _tail = newTail;
}

UnstableNode OzListBuilder::get(VM vm) {
  _tail.fill(vm, buildNil(vm));
  return std::move(_head);
}

template <typename T>
UnstableNode OzListBuilder::get(VM vm, T&& tail) {
  _tail.fill(vm, build(vm, std::forward<T>(tail)));
  return std::move(_head);
}

// ozListForEach ---------------------------------------------------------------

namespace internal {

template <class F>
inline
auto ozListForEachNoRaise(VM vm, RichNode list, const F& f)
    -> typename std::enable_if<function_traits<F>::arity == 1, bool>::type {

  using namespace patternmatching;

  typename std::remove_reference<
    typename function_traits<F>::template arg<0>::type>::type head;

  while (true) {
    RichNode tail;
    if (matchesCons(vm, list, capture(head), capture(tail))) {
      f(head);
      list = tail;
    } else if (matches(vm, list, vm->coreatoms.nil)) {
      return true;
    } else {
      return false;
    }
  }
}

template <class F>
inline
auto ozListForEachNoRaise(VM vm, RichNode list, const F& f)
    -> typename std::enable_if<function_traits<F>::arity == 2, bool>::type {

  using namespace patternmatching;

  typename std::remove_reference<
    typename function_traits<F>::template arg<0>::type>::type head;

  for (size_t i = 0; ; ++i) {
    RichNode tail;
    if (matchesCons(vm, list, capture(head), capture(tail))) {
      f(head, i);
      list = tail;
    } else if (matches(vm, list, vm->coreatoms.nil)) {
      return true;
    } else {
      return false;
    }
  }
}

}

template <class F>
auto ozListForEach(VM vm, RichNode list, const F& f,
                   const nchar* expectedType)
    -> typename std::enable_if<function_traits<F>::arity == 1, void>::type {

  if (!internal::ozListForEachNoRaise(vm, list, f))
    raiseTypeError(vm, expectedType, list);
}

template <class F>
auto ozListForEach(VM vm, RichNode list, const F& f,
                   const nchar* expectedType)
    -> typename std::enable_if<function_traits<F>::arity == 2, void>::type {

  if (!internal::ozListForEachNoRaise(vm, list, f))
    raiseTypeError(vm, expectedType, list);
}

size_t ozListLength(VM vm, RichNode list) {
  size_t result = 0;

  UnstableNode nextList;

  while (true) {
    using namespace patternmatching;

    RichNode tail;

    if (matchesCons(vm, list, wildcard(), capture(tail))) {
      result++;
      list = tail;
    } else if (matches(vm, list, vm->coreatoms.nil)) {
      return result;
    } else {
      raiseTypeError(vm, MOZART_STR("list"), list);
    }
  }
}

//////////////////////////////////////
// Virtual strings and byte strings //
//////////////////////////////////////

namespace internal {

inline
constexpr size_t getIntToStrBufferSize() {
  // +1 for the extra digit, +1 for the - and +1 for the '\0'
  return std::numeric_limits<nativeint>::digits10 + 3;
}

using IntToStrBuffer = nchar[getIntToStrBufferSize()];

inline
size_t intToStrBuffer(IntToStrBuffer buffer, nativeint value) {
  char buffer0[getIntToStrBufferSize()];
  auto length = std::snprintf(buffer0, getIntToStrBufferSize(), "%td", value);
  assert(length >= 0 && (size_t) length < getIntToStrBufferSize());

  std::copy(buffer0, buffer0 + getIntToStrBufferSize(), buffer);
  return (size_t) length;
}

inline
constexpr size_t getFloatToStrBufferSize() {
  return 32;
}

using FloatToStrBuffer = nchar[getFloatToStrBufferSize()];

inline
size_t floatToStrBuffer(FloatToStrBuffer buffer, double value) {
  char buffer0[getFloatToStrBufferSize()];
  auto length0 = std::snprintf(buffer0, sizeof(buffer0), "%.5g", value);
  assert(length0 >= 0 && (size_t) length0 < getFloatToStrBufferSize());

  size_t length = 0;
  bool hasDot = false, hasDigit = false;

  for (size_t i = 0; i < (size_t) length0; ++i) {
    switch (buffer0[i]) {
      case '+':
        continue;

      case '-':
        break;

      case 'e':
        if (!hasDot)
          buffer[length++] = '.';
        if (!hasDigit)
          buffer[length++] = '0';
        hasDigit = hasDot = true;
        break;

      case '.':
        hasDot = true;
        break;

      case '0': case '1': case '2': case '3': case '4':
      case '5': case '6': case '7': case '8': case '9':
        if (hasDot)
          hasDigit = true;
        break;

      default:
        break;
    }

    buffer[length++] = buffer0[i];
  }

  if (!hasDot)
    buffer[length++] = '.';
  if (!hasDigit)
    buffer[length++] = '0';

  buffer[length] = '\0';
  return length;
}

} // namespace internal

inline
nativeint ozVSLengthForBufferNoRaise(VM vm, RichNode vs) {
  using namespace internal;
  using namespace patternmatching;

  size_t partCount;
  StaticArray<StableNode> parts;

  atom_t atomValue;
  nativeint intValue;
  double floatValue;

  if (matchesVariadicSharp(vm, vs, partCount, parts)) {
    nativeint result = 0;
    for (size_t i = 0; i < partCount; ++i) {
      auto partResult = ozVSLengthForBufferNoRaise(vm, parts[i]);
      if (partResult < 0)
        return -1;
      result += partResult;
    }
    return result;
  } else if (matches(vm, vs, capture(atomValue))) {
    if (atomValue != vm->coreatoms.nil)
      return atomValue.length();
    else
      return 0;
  } else if (matchesCons(vm, vs, wildcard(), wildcard())) {
    nativeint result = 0;
    bool ok = ozListForEachNoRaise(vm, vs,
      [vm, &result] (char32_t c) {
        result += (sizeof(char32_t) / sizeof(nchar));
      }
    );
    if (ok)
      return result;
    else
      return -1;
  } else if (vs.is<String>()) {
    return vs.as<String>().value().length;
  } else if (matches(vm, vs, capture(intValue))) {
    return getIntToStrBufferSize();
  } else if (matches(vm, vs, capture(floatValue))) {
    return getFloatToStrBufferSize();
  } else {
    return -1;
  }
}

inline
bool ozVSGetNoRaise(VM vm, RichNode vs, std::vector<nchar>& output) {
  using namespace internal;
  using namespace patternmatching;

  static_assert(
    is_trivially_destructible<decltype(std::back_inserter(output))>::value,
    "Assumption that back_inserter of a vector is trivially destructible "
    "proved wrong.");

  size_t partCount;
  StaticArray<StableNode> parts;

  atom_t atomValue;
  nativeint intValue;
  double floatValue;

  if (matchesVariadicSharp(vm, vs, partCount, parts)) {
    for (size_t i = 0; i < partCount; ++i) {
      if (!ozVSGetNoRaise(vm, parts[i], output))
        return false;
    }
    return true;
  } else if (matches(vm, vs, capture(atomValue))) {
    if (atomValue != vm->coreatoms.nil) {
      std::copy_n(atomValue.contents(), atomValue.length(),
                  std::back_inserter(output));
    }
    return true;
  } else if (matchesCons(vm, vs, wildcard(), wildcard())) {
    return ozListForEachNoRaise(vm, vs,
      [vm, &output] (char32_t c) {
        nchar buffer[4];
        nativeint length = toUTF(c, buffer);
        std::copy_n(buffer, length, std::back_inserter(output));
      }
    );
  } else if (vs.is<String>()) {
    auto& value = vs.as<String>().value();
    std::copy(value.begin(), value.end(), std::back_inserter(output));
    return true;
  } else if (matches(vm, vs, capture(intValue))) {
    IntToStrBuffer buffer;
    auto length = intToStrBuffer(buffer, intValue);
    std::copy_n(buffer, length, std::back_inserter(output));
    return true;
  } else if (matches(vm, vs, capture(floatValue))) {
    FloatToStrBuffer buffer;
    auto length = floatToStrBuffer(buffer, floatValue);
    std::copy_n(buffer, length, std::back_inserter(output));
    return true;
  } else {
    return false;
  }
}

inline
nativeint ozVBSLengthForBufferNoRaise(VM vm, RichNode vbs) {
  using namespace internal;
  using namespace patternmatching;

  size_t partCount;
  StaticArray<StableNode> parts;

  if (matchesVariadicSharp(vm, vbs, partCount, parts)) {
    nativeint result = 0;
    for (size_t i = 0; i < partCount; ++i) {
      nativeint partResult = ozVBSLengthForBufferNoRaise(vm, parts[i]);
      if (partResult < 0)
        return -1;
      result += partResult;
    }
    return result;
  } else if (matchesCons(vm, vbs, wildcard(), wildcard())) {
    nativeint result = 0;
    bool ok = ozListForEachNoRaise(vm, vbs,
      [&result] (unsigned char b) {
        ++result;
      }
    );
    if (ok)
      return result;
    else
      return -1;
  } else if (matches(vm, vbs, vm->coreatoms.nil)) {
    return 0;
  } else if (vbs.is<ByteString>()) {
    return vbs.as<ByteString>().value().length;
  } else {
    return -1;
  }
}

template <typename C>
inline
bool ozVBSGetNoRaise(VM vm, RichNode vbs, std::vector<C>& output) {
  using namespace internal;
  using namespace patternmatching;

  static_assert(
    is_trivially_destructible<decltype(std::back_inserter(output))>::value,
    "Assumption that back_inserter of a vector is trivially destructible "
    "proved wrong.");

  size_t partCount;
  StaticArray<StableNode> parts;

  if (matchesVariadicSharp(vm, vbs, partCount, parts)) {
    for (size_t i = 0; i < partCount; ++i) {
      if (!ozVBSGetNoRaise(vm, parts[i], output))
        return false;
    }
    return true;
  } else if (matchesCons(vm, vbs, wildcard(), wildcard())) {
    return ozListForEachNoRaise(vm, vbs,
      [vm, &output] (unsigned char b) {
        output.push_back(b);
      }
    );
  } else if (matches(vm, vbs, vm->coreatoms.nil)) {
    return true;
  } else if (vbs.is<ByteString>()) {
    auto& value = vbs.as<ByteString>().value();
    std::copy(value.begin(), value.end(), std::back_inserter(output));
    return true;
  } else {
    return false;
  }
}

/**
 * Test whether an Oz value is a VirtualString
 */
bool ozIsVirtualString(VM vm, RichNode vs) {
  return ozVSLengthForBufferNoRaise(vm, vs) >= 0;
}

/**
 * Compute the size of a buffer at least big enough for ozVSGet()
 */
size_t ozVSLengthForBuffer(VM vm, RichNode vs) {
  auto result = ozVSLengthForBufferNoRaise(vm, vs);
  if (result >= 0)
    return (size_t) result;
  else
    raiseTypeError(vm, MOZART_STR("VirtualString"), vs);
}

/**
 * Get the actual value of a VirtualString
 * If ozVSLengthForBuffer() has been called before for the same vs, this
 * function is guaranteed not to throw any Mozart exception.
 */
void ozVSGet(VM vm, RichNode vs, std::vector<nchar>& output) {
  if (!ozVSGetNoRaise(vm, vs, output))
    raiseTypeError(vm, MOZART_STR("VirtualString"), vs);
}

/**
 * Get the actual value of a VirtualString
 * Because ozVSLengthForBuffer() must have been called prior to calling this
 * function, it is guaranteed not to throw any Mozart exception.
 * @param bufSize Size of the buffer returned by ozVSLengthForBuffer()
 */
void ozVSGet(VM vm, RichNode vs, size_t bufSize, std::vector<nchar>& output) {
  output.reserve(bufSize);
  ozVSGet(vm, vs, output);
}

/**
 * Get the actual value of a VirtualString
 * Because ozVSLengthForBuffer() must have been called prior to calling this
 * function, it is guaranteed not to throw any Mozart exception.
 * @param bufSize Size of the buffer returned by ozVSLengthForBuffer()
 */
template <typename C>
void ozVSGet(VM vm, RichNode vs, size_t bufSize, std::vector<C>& output) {
  static_assert(!std::is_same<C, nchar>::value,
                "The overload above should have been selected instead.");

  std::vector<nchar> output0;
  output0.reserve(bufSize);
  ozVSGet(vm, vs, output0);

  auto temp = toUTF<C>(makeLString(output0.data(), output0.size()));
  std::copy_n(temp.begin(), temp.length, std::back_inserter(output));
}

/**
 * Get the actual value of a VirtualString in a C++ string
 * Because ozVSLengthForBuffer() must have been called prior to calling this
 * function, it is guaranteed not to throw any Mozart exception.
 * @param bufSize Size of the buffer returned by ozVSLengthForBuffer()
 */
template <typename C>
void ozVSGet(VM vm, RichNode vs, size_t bufSize, std::basic_string<C>& output) {
  std::vector<C> buffer;
  ozVSGet(vm, vs, bufSize, buffer);
  output = std::basic_string<C>(buffer.begin(), buffer.end());
}

/**
 * Get the actual value of a VirtualString in an LString
 * Because ozVSLengthForBuffer() must have been called prior to calling this
 * function, it is guaranteed not to throw any Mozart exception.
 * @param bufSize Size of the buffer returned by ozVSLengthForBuffer()
 */
template <typename C>
LString<C> ozVSGetAsLString(VM vm, RichNode vs, size_t bufSize) {
  std::vector<C> buffer;
  ozVSGet(vm, vs, bufSize, buffer);
  return newLString(vm, buffer.data(), buffer.size());
}

/**
 * Get the actual value of a VirtualString with a '\0' terminator
 * Because ozVSLengthForBuffer() must have been called prior to calling this
 * function, it is guaranteed not to throw any Mozart exception.
 * @param bufSize Size of the buffer returned by ozVSLengthForBuffer()
 */
template <typename C>
void ozVSGetNullTerminated(VM vm, RichNode vs, size_t bufSize,
                           std::vector<C>& output) {
  ozVSGet(vm, vs, bufSize+1, output);
  output.push_back((C) 0);
}

/**
 * Get the actual value of a VirtualString with a '\0' terminator in an LString
 * Because ozVSLengthForBuffer() must have been called prior to calling this
 * function, it is guaranteed not to throw any Mozart exception.
 * @param bufSize Size of the buffer returned by ozVSLengthForBuffer()
 */
template <typename C>
LString<C> ozVSGetNullTerminatedAsLString(VM vm, RichNode vs, size_t bufSize) {
  std::vector<C> buffer;
  ozVSGetNullTerminated(vm, vs, bufSize, buffer);
  return newLString(vm, buffer.data(), buffer.size());
}

/**
 * Get the actual length of a VirtualString, in number of code points
 */
size_t ozVSLength(VM vm, RichNode vs) {
  size_t bufSize = ozVSLengthForBuffer(vm, vs);

  nativeint result;
  {
    std::vector<nchar> buffer;
    ozVSGet(vm, vs, bufSize, buffer);
    result = codePointCount(makeLString(buffer.data(), buffer.size()));
  }

  if (result < 0)
    raiseUnicodeError(vm, (UnicodeErrorReason) result, vs);
  else
    return (size_t) result;
}

/**
 * Test whether an Oz value is a VirtualByteString
 */
bool ozIsVirtualByteString(VM vm, RichNode vs) {
  return ozVBSLengthForBufferNoRaise(vm, vs) >= 0;
}

/**
 * Compute the size of a buffer at least big enough for ozVBSGet()
 */
size_t ozVBSLengthForBuffer(VM vm, RichNode vbs) {
  auto result = ozVBSLengthForBufferNoRaise(vm, vbs);
  if (result >= 0)
    return (size_t) result;
  else
    raiseTypeError(vm, MOZART_STR("VirtualByteString"), vbs);
}

/**
 * Get the actual value of a VirtualByteString
 * If ozVBSLengthForBuffer() has been called before for the same vbs, this
 * function is guaranteed not to throw any Mozart exception.
 */
template <typename C, typename>
void ozVBSGet(VM vm, RichNode vbs, std::vector<C>& output) {
  if (!ozVBSGetNoRaise(vm, vbs, output))
    raiseTypeError(vm, MOZART_STR("VirtualByteString"), vbs);
}

/**
 * Get the actual value of a VirtualByteString
 * Because ozVVSLengthForBuffer() must have been called prior to calling this
 * function, it is guaranteed not to throw any Mozart exception.
 * @param bufSize Size of the buffer returned by ozVVSLengthForBuffer()
 */
template <typename C, typename>
void ozVBSGet(VM vm, RichNode vbs, size_t bufSize, std::vector<C>& output) {
  output.reserve(bufSize);
  ozVBSGet(vm, vbs, output);
}

/**
 * Get the actual length of a VirtualByteString, in number of bytes
 */
size_t ozVBSLength(VM vm, RichNode vs) {
  /* It so happens that ozVBSLengthForBuffer returns exactly the length.
   * So we reuse it.
   */
  return ozVBSLengthForBuffer(vm, vs);
}

////////////////////////////////
// Port-like usage of streams //
////////////////////////////////

template <typename T>
void sendToReadOnlyStream(VM vm, UnstableNode& stream, T&& value) {
  auto newStream = ReadOnlyVariable::build(vm);
  auto cons = buildCons(vm, std::forward<T>(value), newStream);
  UnstableNode oldStream = std::move(stream);
  stream = std::move(newStream);
  BindableReadOnly(oldStream).bindReadOnly(vm, cons);
}

///////////////////////////////////////
// Dealing with non-idempotent steps //
///////////////////////////////////////

/** Protect a non-idempotent step from being executing twice */
template <typename Step>
auto protectNonIdempotentStep(VM vm, const nchar* identity, const Step& step)
    -> typename std::enable_if<!std::is_void<decltype(step())>::value,
                               decltype(step())>::type {
  assert(vm->isIntermediateStateAvailable());

  IntermediateState& intermediateState = vm->getIntermediateState();
  decltype(step()) result;

  auto checkPoint = intermediateState.makeCheckPoint(vm);
  if (!intermediateState.fetch(vm, identity, patternmatching::capture(result))) {
    result = step();
    intermediateState.resetAndStore(vm, checkPoint, identity, result);
  }

  return result;
}

/** Protect a non-idempotent step from being executing twice */
template <typename Step>
auto protectNonIdempotentStep(VM vm, const nchar* identity, const Step& step)
    -> typename std::enable_if<std::is_void<decltype(step())>::value,
                               void>::type {
  assert(vm->isIntermediateStateAvailable());

  IntermediateState& intermediateState = vm->getIntermediateState();

  auto checkPoint = intermediateState.makeCheckPoint(vm);
  if (!intermediateState.fetch(vm, identity)) {
    step();
    intermediateState.resetAndStore(vm, checkPoint, identity);
  }
}

}

#endif

#endif // __UTILS_H
