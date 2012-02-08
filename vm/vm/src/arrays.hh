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

#include <stdlib.h>
#include <assert.h>

/**
 * A simple wrapper for an array and its size (only in debug mode)
 * @param <T> Type of the elements in the array
 */
template <class T>
class StaticArray {
private:
  T *_array;

#ifndef NDEBUG
  int _size;
#endif // NDEBUG

public:
  /** Create an array with s elements */
  StaticArray(int s) : _array(new T[s]) {
#ifndef NDEBUG
    _size = s;
#endif // NDEBUG
  }

  ~StaticArray() { delete[] _array; }

  /** Zero-based access to elements (read-write) */
  inline
  T& operator[](int i) {
    assert(0 <= i && i < _size);
    return _array[i];
  }

  /** Convert to a raw array */
  inline
  operator T*() {
    return _array;
  }
};

#endif // __ARRAYS_H
