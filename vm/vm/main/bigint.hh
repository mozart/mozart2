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

#ifndef __BIGINT_H
#define __BIGINT_H

#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

////////////
// BigInt //
////////////

#include "BigInt-implem.hh"

bool BigInt::equals(VM vm, RichNode right) {
  return value()->compare(right.as<BigInt>().value()) == 0;
}

UnstableNode BigInt::opposite(VM vm) {
  return shrink(vm, -(*value()));
}

UnstableNode BigInt::add(VM vm, RichNode right) {
  using namespace mozart::patternmatching;

  nativeint smallInt;
  if (matches(vm, right, capture(smallInt))) {
    return add(vm, smallInt);
  } else if (right.is<BigInt>()) {
    return shrink(vm, *value() + right.as<BigInt>().value());
  } else {
    raiseTypeError(vm, "Integer", right);
  }
}

UnstableNode BigInt::add(VM vm, nativeint b) {
  return shrink(vm, *value() + b);
}

UnstableNode BigInt::subtract(VM vm, RichNode right) {
  using namespace mozart::patternmatching;

  std::shared_ptr<BigIntImplem> b;
  nativeint smallInt;
  if (matches(vm, right, capture(smallInt))) {
    b = vm->newBigIntImplem(smallInt);
  } else if (right.is<BigInt>()) {
    b = right.as<BigInt>().value();
  } else {
    raiseTypeError(vm, "Integer", right);
  }
  return shrink(vm, *value() - b);
}

UnstableNode BigInt::multiply(VM vm, RichNode right) {
  using namespace mozart::patternmatching;

  std::shared_ptr<BigIntImplem> b;
  nativeint smallInt;
  if (matches(vm, right, capture(smallInt))) {
    b = vm->newBigIntImplem(smallInt);
  } else if (right.is<BigInt>()) {
    b = right.as<BigInt>().value();
  } else {
    raiseTypeError(vm, "Integer", right);
  }
  return shrink(vm, *value() * b);
}

UnstableNode BigInt::div(VM vm, RichNode right) {
  using namespace mozart::patternmatching;

  std::shared_ptr<BigIntImplem> b;
  nativeint divisor;
  if (matches(vm, right, capture(divisor))) {
    if (divisor == 0) {
      raiseKernelError(vm, "Integer division: Division by zero");
    }
    b = vm->newBigIntImplem(divisor);
  } else if (right.is<BigInt>()) {
    b = right.as<BigInt>().value();
  } else {
    raiseTypeError(vm, "Integer", right);
  }
  return shrink(vm, *value() / b);
}

UnstableNode BigInt::mod(VM vm, RichNode right) {
  using namespace mozart::patternmatching;

  std::shared_ptr<BigIntImplem> b;
  nativeint smallInt;
  if (matches(vm, right, capture(smallInt))) {
    b = vm->newBigIntImplem(smallInt);
  } else if (right.is<BigInt>()) {
    b = right.as<BigInt>().value();
  } else {
    raiseTypeError(vm, "Integer", right);
  }
  return shrink(vm, *value() % b);
}

UnstableNode BigInt::abs(VM vm) {
  if (value()->compare(0) < 0) {
    return opposite(vm);
  } else {
    return shrink(vm, value()); // TODO: optimize
  }
}

UnstableNode BigInt::shrink(VM vm, const std::shared_ptr<BigIntImplem>& n) {
  if (n->compare(std::numeric_limits<nativeint>::max()) <= 0 &&
      n->compare(std::numeric_limits<nativeint>::min()) >= 0) {
    return SmallInt::build(vm, n->nativeintValue());
  } else {
    return BigInt::build(vm, n);
  }
}

}

#endif // MOZART_GENERATOR

#endif // __BIGINT_H