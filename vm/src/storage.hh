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

#ifndef __STORAGE_H
#define __STORAGE_H

#include "memword.hh"
#include "type.hh"

template <class T>
class Implementation {
};


// Marker class that specifies to use the default storage (pointer to value)
template<class T>
class DefaultStorage {
};

// Meta-function from Type to its storage
template<class T>
class Storage {
public:
  typedef DefaultStorage<T> Type;
};

template<class T, class U>
class Accessor {
public:
  template<class... Args>
  static void init(const Type*& type, MemWord& value, VM vm, Args... args) {
    type = T::type;
    value.init(vm, T::build(args...));
  }

  static Implementation<T> get(MemWord value) {
    return Implementation<T>(value.get<U>());
  }
};

template<class T>
class Accessor<T, DefaultStorage<T>> {
public:
  typedef Implementation<T> Impl;

  template<class... Args>
  static void init(const Type*& type, MemWord& value, VM vm, Args... args) {
    type = T::type;
    Impl* val = new (vm) Impl(args...);
    value.init<Impl*>(vm, val);
  }

  static Impl& get(MemWord value) {
    return *(value.get<Impl*>());
  }
};

#endif // __STORAGE_H
