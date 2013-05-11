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
#include <sstream>

#include "utf-decl.hh"

namespace mozart {

class Atom;
class UniqueName;
class AtomTable;

static constexpr size_t bitsPerChar = std::is_same<nchar, char32_t>::value ? 5 :
                                      std::is_same<nchar, char16_t>::value ? 4 : 3;
static constexpr size_t charBitsMask = (1 << bitsPerChar) - 1;

//////////////
// AtomImpl //
//////////////

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
      return compareByCodePoint(makeLString(this->contents(), this->length()),
                                makeLString(rhs->contents(), rhs->length()));
    }
  }
private:
  friend class AtomTable;

  AtomImpl(VM vm, size_t size, const nchar* data,
           size_t critBit, int d, AtomImpl* other)
    : size(size), critBit(critBit) {

    size_t dataLength = size >> bitsPerChar;
    nchar* data0 = new (vm) nchar[dataLength + 1];
    std::memcpy(data0, data, dataLength * sizeof(nchar));
    data0[dataLength] = (nchar) 0;
    this->data = data0;

    side[d]=this;
    side[1-d]=other;
  }

  size_t size;           // number of bits in this atom.
  const nchar* data;     // the string content
  size_t critBit;
  AtomImpl* side[2];
};

//////////////////
// basic_atom_t //
//////////////////

template <size_t atom_type>
size_t basic_atom_t<atom_type>::length() const {
  return _impl->length();
}

template <size_t atom_type>
const nchar* basic_atom_t<atom_type>::contents() const {
  return _impl->contents();
}

template <size_t atom_type>
bool basic_atom_t<atom_type>::equals(const basic_atom_t<atom_type>& rhs) const {
  return _impl == rhs._impl;
}

template <size_t atom_type>
int basic_atom_t<atom_type>::compare(const basic_atom_t<atom_type>& rhs) const {
  return _impl->compare(rhs._impl);
}

///////////////////////
// BasicAtomStreamer //
///////////////////////

template <>
struct BasicAtomStreamer<nchar, 1> { // 1 = atom_t
  static void print(std::basic_ostream<nchar>& out, const atom_t& atom) {
    auto contents = makeLString(atom.contents(), atom.length());

    if (needsQuote(contents)) {
      out << MOZART_STR("'");
      forEachCodePoint(contents,
        [&out] (char32_t c) -> bool {
          switch (c) {
            case 7: out << MOZART_STR("\\a"); break;
            case 8: out << MOZART_STR("\\b"); break;
            case 9: out << MOZART_STR("\\t"); break;
            case 10: out << MOZART_STR("\\n"); break;
            case 11: out << MOZART_STR("\\v"); break;
            case 12: out << MOZART_STR("\\f"); break;
            case 13: out << MOZART_STR("\\r"); break;
            case '\'': out << MOZART_STR("\\'"); break;
            case '\\': out << MOZART_STR("\\\\"); break;
            default: {
              if (c < 32) {
                out << '\\' << '0' << (c / 8) << (c % 8);
              } else {
                nchar data[4];
                auto len = toUTF(c, data);
                out.write(data, len);
              }
            }
          }
          return true;
        }
      );
      out << MOZART_STR("'");
    } else {
      out.write(atom.contents(), atom.length());
    }
  }

private:
  static bool needsQuote(const BaseLString<nchar>& contents) {
    return doesItNotLookLikeAnAtom(contents) || isKeyword(contents);
  }

  static bool doesItNotLookLikeAnAtom(const BaseLString<nchar>& contents) {
    if (contents.length <= 0)
      return true;

    bool first = true;
    bool result = false;
    forEachCodePoint(contents,
      [&first, &result] (char32_t c) -> bool {
        if (first) {
          if (!(c >= 'a' && c <= 'z')) {
            result = true;
            return false;
          }
          first = false;
        } else {
          if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') || (c == '_'))) {
            result = true;
            return false;
          }
        }
        return true;
      }
    );
    return result;
  }

  static bool isKeyword(const BaseLString<nchar>& contents) {
    // TODO Be smarter here, e.g. test length first, or first char, or both
    static const nchar* keywords[] = {
      MOZART_STR("andthen"), MOZART_STR("at"), MOZART_STR("attr"),
      MOZART_STR("case"), MOZART_STR("catch"), MOZART_STR("choice"),
      MOZART_STR("class"), MOZART_STR("cond"), MOZART_STR("declare"),
      MOZART_STR("define"), MOZART_STR("dis"), MOZART_STR("do"),
      MOZART_STR("div"), MOZART_STR("else"), MOZART_STR("elsecase"),
      MOZART_STR("elseif"), MOZART_STR("elseof"), MOZART_STR("end"),
      MOZART_STR("export"), MOZART_STR("fail"), MOZART_STR("false"),
      MOZART_STR("feat"), MOZART_STR("finally"), MOZART_STR("from"),
      MOZART_STR("for"), MOZART_STR("fun"), MOZART_STR("functor"),
      MOZART_STR("if"), MOZART_STR("import"), MOZART_STR("in"),
      MOZART_STR("local"), MOZART_STR("lock"), MOZART_STR("meth"),
      MOZART_STR("mod"), MOZART_STR("not"), MOZART_STR("of"), MOZART_STR("or"),
      MOZART_STR("orelse"), MOZART_STR("prepare"), MOZART_STR("proc"),
      MOZART_STR("prop"), MOZART_STR("raise"), MOZART_STR("require"),
      MOZART_STR("self"), MOZART_STR("skip"), MOZART_STR("then"),
      MOZART_STR("thread"), MOZART_STR("true"), MOZART_STR("try"),
      MOZART_STR("unit"),
    };

    using ct = std::char_traits<nchar>;

    assert(contents.length > 0);
    size_t len = (size_t) contents.length;
    const nchar* s = contents.string;

    for (const nchar* kw : keywords) {
      if ((len == ct::length(kw)) && (ct::compare(s, kw, len) == 0)) {
        return true;
      }
    }

    return false;
  }
};

template <>
struct BasicAtomStreamer<nchar, 2> { // 1 = unique_name_t
  static void print(std::basic_ostream<nchar>& out,
                    const unique_name_t& atom) {
    out << MOZART_STR("<N: ");
    BasicAtomStreamer<nchar, 1>::print(out, atom_t(atom));
    out << MOZART_STR(">");
  }
};

template <typename C, size_t atom_type>
void BasicAtomStreamer<C, atom_type>::print(
  std::basic_ostream<C>& out, const basic_atom_t<atom_type>& atom) {

  std::basic_stringstream<nchar> tempStream;
  BasicAtomStreamer<nchar, atom_type>::print(tempStream, atom);
  out << makeLString(tempStream.str().data(), tempStream.str().size());
}

///////////////
// AtomTable //
///////////////

class AtomTable {
public:
  AtomTable() : root(nullptr), _count(0) {}

  size_t count() {return _count;}

  atom_t get(VM vm, const nchar* data) {
    return get(vm, std::char_traits<nchar>::length(data), data);
  }

  atom_t get(VM vm, size_t size, const nchar* data) {
    return atom_t(getInternal(vm, size, data));
  }

  unique_name_t getUniqueName(VM vm, const nchar* data) {
    return getUniqueName(vm, std::char_traits<nchar>::length(data), data);
  }

  unique_name_t getUniqueName(VM vm, size_t size, const nchar* data) {
    return unique_name_t(getInternal(vm, size, data));
  }
private:
  __attribute__((noinline))
  AtomImpl* getInternal(VM vm, size_t size, const nchar* data) {
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
