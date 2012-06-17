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

#ifndef __ATOMTABLE_H
#define __ATOMTABLE_H

#include "core-forward-decl.hh"

#include <cstring>
#include <string>
#include <type_traits>

namespace mozart {

class Atom;
class AtomTable;

static constexpr size_t bitsPerChar = std::is_same<nchar, char32_t>::value ? 5 :
                                      std::is_same<nchar, char16_t>::value ? 4 : 3;
static constexpr size_t charBitsMask = (1 << bitsPerChar) - 1;

class AtomImpl {
public:
  size_t length() const {
    return size >> bitsPerChar;
  }

  const nchar* contents() const {
    return data;
  }

  int compare(const AtomImpl* rhs) const {
    if (this == rhs) {
      return 0;
    } else {
      return std::char_traits<nchar>::compare(
        this->contents(), rhs->contents(), this->length()+1);
    }
  }
private:
  friend class AtomTable;

  AtomImpl(VM vm, size_t size, const nchar* data,
           size_t critBit, int d, AtomImpl* other)
    : size(size), critBit(critBit) {

    size_t dataLengthPlus1 = (size >> bitsPerChar) + 1;
    nchar* data0 = new (vm) nchar[dataLengthPlus1];
    std::memcpy(data0, data, dataLengthPlus1 * sizeof(nchar));
    this->data = data0;

    side[d]=this;
    side[1-d]=other;
  }

  size_t size;              // number of bits in this atom.
  const nchar* data;     // the string content
  size_t critBit;
  AtomImpl* side[2];
};

class AtomTable {
public:
  AtomTable() : root(nullptr), _count(0) {}

  AtomImpl* get(VM vm, const nchar* data) {
    return get(vm, std::char_traits<nchar>::length(data), data);
  }

  __attribute__((noinline))
  AtomImpl* get(VM vm, size_t size, const nchar* data) {
    assert(size == (size << (bitsPerChar+1)) >> (bitsPerChar+1));   // ??
    size <<= bitsPerChar;
    if(root == nullptr){
      ++_count;
      size_t critBit = size + (1 << bitsPerChar);
      return root = new (vm) AtomImpl(vm, size, data, critBit, 1, nullptr);
    }
    AtomImpl** curP = &root;
    size_t nextToCheck = 0;
    while(true) {
      AtomImpl*& cur = *curP;
      size_t checkEnd = cur->critBit;
      bool cand = false;
      if(cur->critBit < nextToCheck) {
	cand=true;
	checkEnd=cur->size+16;
      }
      size_t f = firstMismatch(size, data,
			       cur->size, cur->data,
			       nextToCheck, checkEnd);
      if(f < checkEnd){
	++_count;
	return cur = new (vm) AtomImpl(vm, size, data, f, bitAt(size, data, f), cur);
      }
      if(cand) return cur;
      nextToCheck=cur->critBit+1;
      curP = &(cur->side[bitAt(size, data, cur->critBit)]);
    }
  }
  size_t count() {return _count;}
private:
  int bitAt(size_t size, const nchar* data, size_t pos) {
    if(pos >= size) return 1;
    return (data[pos >> bitsPerChar] & (1 << (pos & charBitsMask))) ? 1 : 0;
  }
  nchar charAt(size_t sizeC, const nchar* data, size_t i) {
    if(i >= sizeC) return ~(nchar)0;
    return data[i];
  }
  size_t firstMismatch(size_t s1, const nchar* d1,
		       size_t s2, const nchar* d2,
		       size_t start, size_t stop) {
    if(start == stop) return stop;
    stop--;
    size_t s1c = s1 >> bitsPerChar;
    size_t s2c = s2 >> bitsPerChar;
    nchar mask = (1 << (start & charBitsMask)) - 1;
    mask = ~mask;
    for(size_t i = start >> bitsPerChar; (i <= stop >> bitsPerChar); ++i) {
      nchar x = charAt(s1c, d1, i);
      nchar y = charAt(s2c, d2, i);
      nchar d = (x ^ y) & mask;
      if(d) return (i << bitsPerChar) + __builtin_ctz(d);
      mask = ~(nchar)0;
    }
    return stop+1;
  }
  AtomImpl* root;
  size_t _count;
};

}

#endif // __ATOMTABLE_H
