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

#ifndef __ARRAYS_H
#define __ARRAYS_H

#include <cstdlib>
#include <cassert>

#include "core-forward-decl.hh"

namespace mozart {

/**
 * A simple wrapper for an array and its size (only in debug mode)
 * @param <T> Type of the elements in the array
 */
template <class T>
class StaticArray {
private:
  // Apparently, std::nullptr_t is not defined in every standard library yet
  typedef decltype(nullptr) nullptr_t;
private:
  T* _array;

#ifdef MOZART_STATICARRAY_WITH_SIZE
  size_t _size;
#endif

public:
  /** Create an array with s elements */
  StaticArray(T* array, size_t s) : _array(array) {
#ifdef MOZART_STATICARRAY_WITH_SIZE
    _size = s;
#endif
  }

  /** Create an array with no element */
  StaticArray() : _array(nullptr) {
#ifdef MOZART_STATICARRAY_WITH_SIZE
    _size = 0;
#endif
  }

  /** Convert from nullptr */
  StaticArray(nullptr_t nullp) : _array(nullptr) {
#ifdef MOZART_STATICARRAY_WITH_SIZE
    _size = 0;
#endif
  }

  /** Zero-based access to elements (read-write) */
  inline
  T& operator[](size_t i) {
#ifdef MOZART_STATICARRAY_WITH_SIZE
    assert(i < _size);
#endif
    return _array[i];
  }

  /** Zero-based access to elements (read-write) */
  inline
  T& operator[](int i) {
#ifdef MOZART_STATICARRAY_WITH_SIZE
    assert((i >= 0) && ((size_t i) < _size));
#endif
    return _array[i];
  }

  /** Convert to a raw array */
  inline
  operator T*() {
    return _array;
  }

  /** Assign from nullptr */
  inline
  void operator=(nullptr_t nullp) {
    _array = nullptr;
#ifdef MOZART_STATICARRAY_WITH_SIZE
    _size = 0;
#endif
  }

  /** Take a slice of the array, dropping n elements at the beginning */
  inline
  StaticArray<T> drop(size_t n) {
#ifdef MOZART_STATICARRAY_WITH_SIZE
    assert(n <= _size);
    return { _array+n, _size-n };
#else
    return { _array+n, 0 };
#endif
  }
};

}

#endif // __ARRAYS_H
