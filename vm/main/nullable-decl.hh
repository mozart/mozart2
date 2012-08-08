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

#ifndef __OPTIONAL_DECL_H
#define __OPTIONAL_DECL_H

#include "core-forward-decl.hh"

#include <cassert>

namespace mozart {

//////////////
// nullable //
//////////////

template <class T>
class nullable {

#ifdef IN_IDE_PARSER
public:
  // Help IDEs to autocomplete things
  inline nullable();
  inline nullable(std::nullptr_t);
  inline nullable(T value);
  inline nullable(const nullable<T>& from);

  inline nullable<T*>& operator=(std::nullptr_t);
  inline nullable<T*>& operator=(T value);
  inline nullable<T*>& operator=(const nullable<T>& from);

  inline bool isNull();
  inline bool isDefined();

  inline T get();
#endif

};

template <class T>
class nullable<T*> {
public:
  nullable() {}
  nullable(std::nullptr_t): _value(nullptr) {}

  nullable(T* value): _value(value) {
    assert(isDefined());
  }

  nullable(const nullable<T*>& from): _value(from._value) {}

  nullable<T*>& operator=(std::nullptr_t) {
    _value = nullptr;
    return *this;
  }

  nullable<T*>& operator=(T* value) {
    assert(value != nullptr);
    _value = value;
    return *this;
  }

  nullable<T*>& operator=(const nullable<T*>& from) {
    _value = from._value;
    return *this;
  }

  bool isNull() {
    return _value == nullptr;
  }

  bool isDefined() {
    return _value != nullptr;
  }

  T* get() {
    assert(isDefined());
    return _value;
  }

  inline
  nullable<T&> operator*();
private:
  T* _value;
};

template <class T>
class nullable<T&> {
public:
  nullable() {}
  nullable(std::nullptr_t): _underlying(nullptr) {}
  nullable(T& value): _underlying(&value) {}
  nullable(const nullable<T&>& from): _underlying(from._underlying) {}

  nullable<T&>& operator=(std::nullptr_t) {
    _underlying = nullptr;
    return *this;
  }

  nullable<T&>& operator=(T& value) {
    _underlying = &value;
    return *this;
  }

  nullable<T&>& operator=(const nullable<T&>& from) {
    _underlying = from._underlying;
    return *this;
  }

  bool isNull() {
    return _underlying.isNull();
  }

  bool isDefined() {
    return _underlying.isDefined();
  }

  T& get() {
    return *_underlying.get();
  }

  nullable<T*> operator&() {
    return _underlying;
  }
private:
  template <class>
  friend class nullable;

  nullable(const nullable<T*>& from): _underlying(from) {}
private:
  nullable<T*> _underlying;
};

// Inlines

template <class T>
nullable<T&> nullable<T*>::operator*() {
  return { *this };
}

}

#endif // __OPTIONAL_DECL_H
