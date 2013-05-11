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

#ifndef __LSTRING_H
#define __LSTRING_H

#include <vector>
#include <algorithm>
#include <cstring>

#include "mozartcore.hh"

namespace mozart {

namespace mut {

// BaseLString -----------------------------------------------------------------

template <class C>
BaseLString<C>::BaseLString(const C* str)
    : string(str), length(std::char_traits<C>::length(str)) {}

template <class C>
BaseLString<C>::BaseLString(BaseLString&& other)
    : string(other.string), length(other.length) {
  other.string = nullptr;
  other.length = 0;
}

template <class C>
bool operator==(const BaseLString<C>& a, const BaseLString<C>& b) {
  if (a.length != b.length)
    return false;
  if (a.string == b.string)
    return true;
  return memcmp(a.string, b.string, a.bytesCount()) == 0;
}

template <class C>
bool operator!=(const BaseLString<C>& a, const BaseLString<C>& b) {
  return !(a == b);
}

template <class C>
constexpr const BaseLString<C> BaseLString<C>::unsafeSlice(nativeint from) const {
  return isErrorOrEmpty()
      ? BaseLString<C>(error)
      : BaseLString<C>(string + from, length - from);
}

template <class C>
constexpr const BaseLString<C> BaseLString<C>::unsafeSlice(nativeint from,
                                                           nativeint to) const {
  return isErrorOrEmpty()
      ? BaseLString<C>(error)
      : BaseLString<C>(string + from, to - from);
}

namespace mutinternal {
  template <class OutC, class InC>
  struct WriteLStringToStreamHelper {
    static std::basic_ostream<OutC>& write(std::basic_ostream<OutC>& out,
                                           const BaseLString<InC>& input) {
      return out << toUTF<OutC>(input);
    }
  };

  template <class C>
  struct WriteLStringToStreamHelper<C, C> {
    static std::basic_ostream<C>& write(std::basic_ostream<C>& out,
                                        const BaseLString<C>& input) {
      if (input.isError())
        return out << "(error " << (nativeint) input.error << ")";
      else
        return out.write(input.string, input.length);
    }
  };
}

template <class OutC, class InC>
std::basic_ostream<OutC>& operator<<(std::basic_ostream<OutC>& out,
                                     const BaseLString<InC>& input) {
  return mutinternal::WriteLStringToStreamHelper<OutC, InC>::write(out, input);
}

// LString ---------------------------------------------------------------------

template <class C>
LString<C>::LString(VM vm, const BaseLString<C>& other) {
  if (other.isErrorOrEmpty()) {
    this->string = nullptr;
    this->error = other.error;
  } else {
    C* buffer = new C[other.length];
    memcpy(buffer, other.string, other.bytesCount());
    this->string = buffer;
    this->length = other.length;
  }
}

template <class C>
template <class F>
LString<C>::LString(VM vm, nativeint length, const F& initializer) {
  C* buffer = new C[length];
  initializer(buffer);
  this->string = buffer;
  this->length = length;
}

template <class C>
constexpr const LString<C> LString<C>::slice(nativeint from) const {
  return slice(from, this->length);
}

template <class C>
constexpr const LString<C> LString<C>::slice(nativeint from,
                                             nativeint to) const {
  return this->isErrorOrEmpty()
      ? LString<C>(this->error)
      : LString<C>(this->string + from, to - from);
}

}

// ContainedLString ------------------------------------------------------------

template <class T>
ContainedLString<T>::ContainedLString(ContainedLString&& other)
    : _container(std::move(other._container)) {
  other.string = nullptr;
  other.length = 0;
}

template <class T>
ContainedLString<T>::ContainedLString(T container)
    : _container(std::move(container)) {
  this->string = _container.data();
  this->length = _container.size();
}

template <class T>
template <class It>
ContainedLString<T>::ContainedLString(It begin, It end)
    : _container(begin, end) {
  this->string = _container.data();
  this->length = _container.size();
}

template <class T>
void ContainedLString<T>::insertPrefix(const mut::BaseLString<CharType>& s) {
  assert(!s.isError());
  _container.insert(_container.begin(), s.begin(), s.end());
  this->string = _container.data();
  this->length = _container.size();
}

// functions -------------------------------------------------------------------

template <class C, nativeint n>
LString<C> makeLString(const char (&str)[n], nativeint len) {
  return {str, len};
}

template <class C>
mut::BaseLString<C> makeLString(const C* str) {
  return mut::BaseLString<C>(str);
}

template <class C>
mut::BaseLString<C> makeLString(const C* str, nativeint len) {
  return {str, len};
}

// Create LString on heap.
template <class C, nativeint n>
LString<C> newLString(const C (&str)[n], nativeint len) {
  return LString<C>::fromLiteral(str, len);
}

template <class C>
LString<C> newLString(VM vm, const C* str) {
  return {vm, makeLString(str)};
}

template <class C>
LString<C> newLString(VM vm, const C* str, nativeint len) {
  return {vm, makeLString(str, len)};
}

template <class T>
LString<typename T::value_type> newLString(VM vm, const T& container) {
  return {vm, makeLString(container.data(), container.size())};
}

template <class C>
LString<C> newLString(VM vm, const BaseLString<C>& copyFrom) {
  return {vm, copyFrom};
}

template <class F>
auto newLStringInit(VM vm, nativeint len, const F& func)
    -> LString<typename std::remove_pointer<
                 typename function_traits<F>::template arg<0>::type>::type> {
  return {vm, len, func};
}

template <class C>
LString<C> concatLString(VM vm, const LString<C>& a, const LString<C>& b) {
  if (b.isErrorOrEmpty())
    return a;
  else if (a.isErrorOrEmpty())
    return b;
  else if (a.end() == b.begin())
    return a.slice(0, a.length + b.length);

  return newLStringInit(vm, a.length + b.length, [&](C* buffer) {
    memcpy(buffer, a.string, a.bytesCount());
    memcpy(buffer + a.length, b.string, b.bytesCount());
  });
}

}

#endif // __LSTRING_H
