#ifndef __LSTRING_HH
#define __LSTRING_HH

#include <cstring>
#include "mozartcore.hh"
#include "lstring-decl.hh"

namespace mozart {

namespace mut {

  // BaseLString ---------------------------------------------------------------

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
  static
  bool operator==(const BaseLString<C>& a, const BaseLString<C>& b) {
    if (a.length != b.length)
      return false;
    if (a.string == b.string)
      return true;
    return memcmp(a.string, b.string, a.bytesCount()) == 0;
  }

  template <class C>
  static
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

  template <class C>
  static std::basic_ostream<C>& operator<<(std::basic_ostream<C>& out,
                                           const BaseLString<C>& input) {
    if (input.isError())
      return out << "(error " << (nativeint)input.error << ")";
    else
      return out.write(input.string, input.length);
  }

  // LString -------------------------------------------------------------------
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
  constexpr const LString<C> LString<C>::slice(nativeint from, nativeint to) const {
    return this->isErrorOrEmpty()
        ? LString<C>(this->error)
        : LString<C>(this->string + from, to - from);
  }
}

// ContainedLString ------------------------------------------------------------

template <class T>
ContainedLString<T>::ContainedLString(ContainedLString&& other)
    : ContainedLString(std::move(other._container)) {
  other.string = nullptr;
  other.length = 0;
}

template <class T>
ContainedLString<T>::ContainedLString(T container)
    : _container(std::move(container))
{
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
static LString<C> makeLString(const char (&str)[n], nativeint len) {
  return {str, len};
}

template <class C>
static mut::BaseLString<C> makeLString(const C* str) {
  return mut::BaseLString<C>(str);
}

template <class C>
static mut::BaseLString<C> makeLString(const C* str, nativeint len) {
  return {str, len};
}

// Create LString on heap.
template <class C, nativeint n>
inline LString<C> newLString(const C (&str)[n], nativeint len) {
  return LString<C>::fromLiteral(str, len);
}

template <class C>
inline LString<C> newLString(VM vm, const C* str) {
  return {vm, makeLString(str)};
}

template <class C>
static LString<C> newLString(VM vm, const C* str, nativeint len) {
  return {vm, makeLString(str, len)};
}

template <class T>
static LString<typename T::value_type> newLString(VM vm, const T& container) {
  return {vm, makeLString(container.data(), container.size())};
}

template <class C>
static LString<C> newLString(VM vm, const BaseLString<C>& copyFrom) {
  return {vm, copyFrom};
}

template <class F>
static auto newLString(VM vm, nativeint len, const F& func)
    -> LString<typename std::remove_pointer<
                 typename function_traits<F>::template arg<0>::type>::type> {
  return {vm, len, func};
}

template <class C>
static LString<C> concatLString(VM vm, const LString<C>& a, const LString<C>& b) {
  if (b.isErrorOrEmpty())
    return a;
  else if (a.isErrorOrEmpty())
    return b;
  else if (a.end() == b.begin())
    return a.slice(0, a.length + b.length);

  return newLString(vm, a.length + b.length, [&](C* buffer) {
    memcpy(buffer, a.string, a.bytesCount());
    memcpy(buffer + a.length, b.string, b.bytesCount());
  });
}

}

#endif

