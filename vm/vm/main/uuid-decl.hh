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

#ifndef __UUID_DECL_H
#define __UUID_DECL_H

#include "core-forward-decl.hh"

#include <cstdint>
#include <string>
#include <sstream>
#include <iomanip>

namespace mozart {

namespace internal {
  class word_print {
  public:
    word_print(std::uint_fast16_t value): value(value) {}

    std::ostream& operator()(std::ostream& out) const {
      return out << std::setw(4) << value;
    }
  private:
    std::uint_fast16_t value;
  };

  inline
  static std::ostream& operator<<(std::ostream& out,
                                  const word_print& printer) {
    return printer(out);
  }
}

//////////
// UUID //
//////////

struct UUID {
private:
  constexpr static std::uint64_t hexDigit(char digit) {
    return (digit <= '9') ? (digit - '0') :
      ((digit <= 'F') ? (digit - 'A' + 10) : (digit - 'a' + 10));
  }

  constexpr static std::uint64_t hexWordAt(const char str[39], size_t i) {
    return (hexDigit(str[i]) << 12) + (hexDigit(str[i+1]) << 8) +
      (hexDigit(str[i+2]) << 4) + hexDigit(str[i+3]);
  }

  constexpr static std::uint64_t makeUInt64FromWordsAt(
    const char str[39], size_t i, size_t j, size_t k, size_t l) {
    return (hexWordAt(str, i) << 48) + (hexWordAt(str, j) << 32) +
      (hexWordAt(str, k) << 16) + hexWordAt(str, l);
  }

  static std::uint64_t makeUInt64FromBytes(const unsigned char* bytes) {
    return
      ((std::uint64_t) bytes[0] << 56) + ((std::uint64_t) bytes[1] << 48) +
      ((std::uint64_t) bytes[2] << 40) + ((std::uint64_t) bytes[3] << 32) +
      ((std::uint64_t) bytes[4] << 24) + ((std::uint64_t) bytes[5] << 16) +
      ((std::uint64_t) bytes[6] << 8) + ((std::uint64_t) bytes[7]);
  }

  static void storeUInt64ToBytes(std::uint64_t value, unsigned char* bytes) {
    bytes[0] = value >> 56;
    bytes[1] = value >> 48;
    bytes[2] = value >> 40;
    bytes[3] = value >> 32;
    bytes[4] = value >> 24;
    bytes[5] = value >> 16;
    bytes[6] = value >> 8;
    bytes[7] = value;
  }
public:
  // Definition lives in coredatatypes.cc
  constexpr static size_t byte_count = 16;
public:
  constexpr UUID(): data0(0), data1(0) {}

  constexpr UUID(const char str[39]):
    data0(makeUInt64FromWordsAt(str, 1, 5, 10, 15)),
    data1(makeUInt64FromWordsAt(str, 20, 25, 29, 33)) {}

  constexpr UUID(std::uint64_t data0, std::uint64_t data1):
    data0(data0), data1(data1) {}

  UUID(const unsigned char* bytes):
    data0(makeUInt64FromBytes(bytes)),
    data1(makeUInt64FromBytes(bytes + 8)) {}
public:
  constexpr bool is_nil() const {
    return (data0 == 0) && (data1 == 0);
  }
public:
  void toBytes(unsigned char* bytes) const {
    storeUInt64ToBytes(data0, bytes);
    storeUInt64ToBytes(data1, bytes + 8);
  }
public:
  void print(std::ostream& out) const {
    using namespace internal;

    auto savedFlags = out.setf(out.hex, out.basefield);
    auto savedFill = out.fill('0');

    out << "{"
        << wordAt0(0) << wordAt0(1) << "-"
        << wordAt0(2) << "-"
        << wordAt0(3) << "-"
        << wordAt1(0) << "-"
        << wordAt1(1) << wordAt1(2) << wordAt1(3)
        << "}";

    out.flags(savedFlags);
    out.fill(savedFill);
  }

  std::string toString() const {
    std::stringstream result;
    print(result);
    return result.str();
  }
private:
  internal::word_print wordAt0(size_t i) const {
    return internal::word_print(
      ((std::uint_fast16_t) (data0 >> ((3-i)*16))) & 0xffff);
  }

  internal::word_print wordAt1(size_t i) const {
    return internal::word_print(
      ((std::uint_fast16_t) (data1 >> ((3-i)*16))) & 0xffff);
  }
public:
  std::uint64_t data0;
  std::uint64_t data1;
};

///////////////////////
// Operators on UUID //
///////////////////////

inline
bool operator==(const UUID& lhs, const UUID& rhs) {
  return (lhs.data0 == rhs.data0) && (lhs.data1 == rhs.data1);
}

inline
bool operator!=(const UUID& lhs, const UUID& rhs) {
  return !(lhs == rhs);
}

inline
bool operator<(const UUID& lhs, const UUID& rhs) {
  return (lhs.data0 < rhs.data0) ||
    ((lhs.data0 == rhs.data0) && (lhs.data1 < rhs.data1));
}

inline
bool operator>(const UUID& lhs, const UUID& rhs) {
  return rhs < lhs;
}

inline
bool operator<=(const UUID& lhs, const UUID& rhs) {
  return !(lhs > rhs);
}

inline
bool operator>=(const UUID& lhs, const UUID& rhs) {
  return !(lhs < rhs);
}

inline
std::ostream& operator<<(std::ostream& out, const UUID& uuid) {
  uuid.print(out);
  return out;
}

}

#endif // __UUID_DECL_H
