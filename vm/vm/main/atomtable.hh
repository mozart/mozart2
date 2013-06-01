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

static constexpr size_t bitsPerChar = 3;
static constexpr size_t charBitsMask = (1 << bitsPerChar) - 1;

//////////////
// AtomImpl //
//////////////

class AtomImpl {
public:
  size_t length() const {
    return size >> bitsPerChar;
  }

  const char* contents() const {
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

  AtomImpl(VM vm, size_t size, const char* data,
           size_t critBit, int d, AtomImpl* other)
    : size(size), critBit(critBit) {

    size_t dataLength = size >> bitsPerChar;
    char* data0 = new (vm) char[dataLength + 1];
    std::memcpy(data0, data, dataLength * sizeof(char));
    data0[dataLength] = (char) 0;
    this->data = data0;

    side[d]=this;
    side[1-d]=other;
  }

  size_t size;          // number of bits in this atom.
  const char* data;     // the string content
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
const char* basic_atom_t<atom_type>::contents() const {
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
struct BasicAtomStreamer<char, 1> { // 1 = atom_t
  static void print(std::basic_ostream<char>& out, const atom_t& atom) {
    static const char hexdigits[16] = {
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
    };

    auto contents = makeLString(atom.contents(), atom.length());

    if (needsQuote(contents)) {
      out << '\'';
      for (nativeint i = 0; i < contents.length; ++i) {
        char c = contents[i];
        switch (c) {
          case 7: out << "\\a"; break;
          case 8: out << "\\b"; break;
          case 9: out << "\\t"; break;
          case 10: out << "\\n"; break;
          case 11: out << "\\v"; break;
          case 12: out << "\\f"; break;
          case 13: out << "\\r"; break;
          case '\'': out << "\\'"; break;
          case '\\': out << "\\\\"; break;
          case '\x7F': out << "\\x7F"; break; // <DEL>
          case '\xC2': {
            ++i;
            if (i == contents.length) {
              // Not valid UTF-8, but let us not crash
              out << c;
            } else {
              char c2 = contents[i];
              if ((c2 & '\xE0') == '\x80') { // === (c >= '\x80' && c < '\xA0')
                // c c2 is a control character with scalar value
                // 256 + c2 = (unsigned char) c2
                out << '\\' << 'x'
                    << hexdigits[((unsigned char) c2) >> 4]
                    << hexdigits[((unsigned char) c2) & 0x0F];
              } else {
                // regular character formed of c + c2 (+ ...)
                out << c << c2;
              }
            }
            break;
          }
          default: {
            if ((c & '\xE0') == 0) { // === (c >= 0 && c < 32)
              // control character with scalar value c
              out << '\\' << 'x' << hexdigits[c >> 4] << hexdigits[c & 0x0F];
            } else {
              // anything else can be passed through directly
              out << c;
            }
          }
        }
      }
      out << '\'';
    } else {
      out.write(atom.contents(), atom.length());
    }
  }

private:
  static bool needsQuote(const BaseLString<char>& contents) {
    return doesItNotLookLikeAnAtom(contents) || isKeyword(contents);
  }

  static bool doesItNotLookLikeAnAtom(const BaseLString<char>& contents) {
    // Must not be empty
    if (contents.length <= 0)
      return true;

    // First character must be an ASCII lowercase letter
    char firstChar = contents[0];
    if (!(firstChar >= 'a' && firstChar <= 'z'))
      return true;

    // Subsequent characters must be ASCII letters, digits or '_'
    for (nativeint i = 1; i < contents.length; ++i) {
      char c = contents[i];
      if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9') || (c == '_'))) {
        return true;
      }
    }

    return false;
  }

  static bool isKeyword(const BaseLString<char>& contents) {
    // TODO Be smarter here, e.g. test length first, or first char, or both
    static const char* keywords[] = {
      "andthen", "at", "attr",
      "case", "catch", "choice",
      "class", "cond", "declare",
      "define", "dis", "do",
      "div", "else", "elsecase",
      "elseif", "elseof", "end",
      "export", "fail", "false",
      "feat", "finally", "from",
      "for", "fun", "functor",
      "if", "import", "in",
      "local", "lock", "meth",
      "mod", "not", "of", "or",
      "orelse", "prepare", "proc",
      "prop", "raise", "require",
      "self", "skip", "then",
      "thread", "true", "try",
      "unit",
    };

    using ct = std::char_traits<char>;

    assert(contents.length > 0);
    size_t len = (size_t) contents.length;
    const char* s = contents.string;

    for (const char* kw : keywords) {
      if ((len == ct::length(kw)) && (ct::compare(s, kw, len) == 0)) {
        return true;
      }
    }

    return false;
  }
};

template <>
struct BasicAtomStreamer<char, 2> { // 1 = unique_name_t
  static void print(std::basic_ostream<char>& out,
                    const unique_name_t& atom) {
    out << "<N: ";
    BasicAtomStreamer<char, 1>::print(out, atom_t(atom));
    out << ">";
  }
};

template <typename C, size_t atom_type>
void BasicAtomStreamer<C, atom_type>::print(
  std::basic_ostream<C>& out, const basic_atom_t<atom_type>& atom) {

  std::basic_stringstream<char> tempStream;
  BasicAtomStreamer<char, atom_type>::print(tempStream, atom);
  out << makeLString(tempStream.str().data(), tempStream.str().size());
}

///////////////
// AtomTable //
///////////////

class AtomTable {
public:
  AtomTable() : root(nullptr), _count(0) {}

  size_t count() {return _count;}

  atom_t get(VM vm, const char* data) {
    return get(vm, std::char_traits<char>::length(data), data);
  }

  atom_t get(VM vm, size_t size, const char* data) {
    return atom_t(getInternal(vm, size, data));
  }

  unique_name_t getUniqueName(VM vm, const char* data) {
    return getUniqueName(vm, std::char_traits<char>::length(data), data);
  }

  unique_name_t getUniqueName(VM vm, size_t size, const char* data) {
    return unique_name_t(getInternal(vm, size, data));
  }
private:
  __attribute__((noinline))
  AtomImpl* getInternal(VM vm, size_t size, const char* data) {
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
  int bitAt(size_t size, const char* data, size_t pos) {
    if(pos >= size) return 1;
    return (data[pos >> bitsPerChar] & (1 << (pos & charBitsMask))) ? 1 : 0;
  }
  char charAt(size_t sizeC, const char* data, size_t i) {
    if(i >= sizeC) return ~(char)0;
    return data[i];
  }
  size_t firstMismatch(size_t s1, const char* d1,
                       size_t s2, const char* d2,
                       size_t start, size_t stop) {
    if(start == stop) return stop;
    stop--;
    size_t s1c = s1 >> bitsPerChar;
    size_t s2c = s2 >> bitsPerChar;
    char mask = (1 << (start & charBitsMask)) - 1;
    mask = ~mask;
    for(size_t i = start >> bitsPerChar; (i <= stop >> bitsPerChar); ++i) {
      char x = charAt(s1c, d1, i);
      char y = charAt(s2c, d2, i);
      char d = (x ^ y) & mask;
      if(d) return (i << bitsPerChar) + __builtin_ctz(d);
      mask = ~(char)0;
    }
    return stop+1;
  }
  AtomImpl* root;
  size_t _count;
};

}

#endif // __ATOMTABLE_H
