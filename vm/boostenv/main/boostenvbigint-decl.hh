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

#ifndef __BOOSTENVBIGINT_DECL_H
#define __BOOSTENVBIGINT_DECL_H

#include "boostenv-decl.hh"

#define USE_GMP 0

#if USE_GMP
#include <boost/multiprecision/gmp.hpp>
#else
#include <boost/multiprecision/cpp_int.hpp>
#endif

namespace mozart { namespace boostenv {

#if USE_GMP
typedef boost::multiprecision::mpz_int mp_int;
#else
typedef boost::multiprecision::cpp_int mp_int;
#endif

class BoostBigInt : public BigIntImplem {
public:
  inline
  BoostBigInt(nativeint value);

  inline
  BoostBigInt(const mp_int& value);

  mp_int value() { return _value; }

  inline
  std::shared_ptr<BigIntImplem> operator-();

  inline
  std::shared_ptr<BigIntImplem> operator+(std::shared_ptr<BigIntImplem> b);

  inline
  std::shared_ptr<BigIntImplem> operator+(nativeint b);

  inline
  std::shared_ptr<BigIntImplem> operator-(std::shared_ptr<BigIntImplem> b);

  inline
  std::shared_ptr<BigIntImplem> operator*(std::shared_ptr<BigIntImplem> b);

  inline
  std::shared_ptr<BigIntImplem> operator/(std::shared_ptr<BigIntImplem> b);

  inline
  std::shared_ptr<BigIntImplem> operator%(std::shared_ptr<BigIntImplem> b);

  inline
  int compare(std::shared_ptr<BigIntImplem> b);

  inline
  void printReprToStream(VM vm, std::ostream& out, int depth, int width);

public:
  template<class T>
  static std::shared_ptr<BigIntImplem> make_shared_ptr(const T& value) {
    return std::static_pointer_cast<BigIntImplem>(std::make_shared<BoostBigInt>(value));
  }

private:
  mp_int _value;
};

} }

#endif // __BOOSTENVBIGINT_DECL_H
