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

BoostBigInt::BoostBigInt(nativeint value) {
  _value = value;
}

BoostBigInt::BoostBigInt(const mp_int& value) {
  _value = value;
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator-() {
  return make_shared_ptr(value()); // TODO
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator+(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value()); // TODO
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator+(nativeint b) {
  return make_shared_ptr(value()); // TODO
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator-(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value()); // TODO
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator*(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value() * std::static_pointer_cast<BoostBigInt>(b)->value());
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator/(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value()); // TODO
}

std::shared_ptr<BigIntImplem> BoostBigInt::operator%(std::shared_ptr<BigIntImplem> b) {
  return make_shared_ptr(value()); // TODO
}

int BoostBigInt::compare(std::shared_ptr<BigIntImplem> b) {
  return 0; // TODO
}

void BoostBigInt::printReprToStream(VM vm, std::ostream& out, int depth, int width) {
  out << value();
}

} }

#endif

#endif // __BOOSTENVBIGINT_H
