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

#ifndef __BOOSTENVBIGINT_H
#define __BOOSTENVBIGINT_H

#include "boostenvbigint-decl.hh"

#include "boostenv-decl.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

/////////////////
// BoostBigInt //
/////////////////

std::shared_ptr<BigIntImplem> BoostBigInt::operator-() {
  return make_shared_ptr(-value());
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator+(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value() + cast(b)->value());
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator+(nativeint b) {
  return make_shared_ptr(value() + b);
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator-(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value() - cast(b)->value());
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator*(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value() * cast(b)->value());
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator/(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value() / cast(b)->value());
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator%(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value() % cast(b)->value());
}

int BoostBigInt::compare(nativeint b) {
  return value().compare(b);
}

int BoostBigInt::compare(std::shared_ptr<BigIntImplem> b) {
  return value().compare(cast(b)->value());
}

nativeint BoostBigInt::nativeintValue() {
  return value().convert_to<nativeint>();
}

double BoostBigInt::doubleValue() {
  return value().convert_to<double>();
}

std::string BoostBigInt::str() {
  return value().str();
}

void BoostBigInt::printReprToStream(VM vm, std::ostream& out, int depth, int width) {
  if (value() >= 0) {
    out << value();
  } else {
    out << '~' << -value();
  }
}

} }

#endif

#endif // __BOOSTENVBIGINT_H
