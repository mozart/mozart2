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

#ifndef MOZART_SMALLINT_H
#define MOZART_SMALLINT_H

#include "mozartcore.hh"

#include <string>
#include <limits>

#ifndef MOZART_GENERATOR

namespace mozart {

//////////////
// SmallInt //
//////////////

#include "SmallInt-implem.hh"

void SmallInt::create(nativeint& self, VM vm, GR gr, SmallInt from) {
  self = from.value();
}

bool SmallInt::equals(VM vm, RichNode right) {
  return value() == right.as<SmallInt>().value();
}

int SmallInt::compareFeatures(VM vm, RichNode right) {
  auto rhs = right.as<SmallInt>().value();

  if (value() == rhs)
    return 0;
  else if (value() < rhs)
    return -1;
  else
    return 1;
}

// Comparable ------------------------------------------------------------------

int SmallInt::compare(VM vm, RichNode right) {
  auto rightIntValue = getArgument<nativeint>(vm, right);
  return (value() == rightIntValue) ? 0 : (value() < rightIntValue) ? -1 : 1;
}

// Numeric ---------------------------------------------------------------------

UnstableNode SmallInt::opposite(VM vm) {
  // Detecting overflow - platform dependent (2's complement)
  if (value() != std::numeric_limits<nativeint>::min()) {
    // No overflow
    return SmallInt::build(vm, -value());
  } else {
    // Overflow - TODO: create a BigInt
    return vm->newBigInt(0);
  }
}

UnstableNode SmallInt::add(VM vm, RichNode right) {
  if (right.is<SmallInt>()) {
    return add(vm, right.as<SmallInt>().value());
  } else if (right.is<BigInt>()) {
    UnstableNode big = vm->newBigInt(value());
    return Numeric(big).add(vm, right);
  } else {
    raiseTypeError(vm, "Integer", right);
  }
}

UnstableNode SmallInt::add(VM vm, nativeint b) {
  nativeint a = value();
  nativeint c = a + b;

  // Detecting overflow - platform dependent (2's complement)
  if ((((a ^ c) & (b ^ c)) >> std::numeric_limits<nativeint>::digits) == 0) {
    // No overflow
    return SmallInt::build(vm, c);
  } else {
    UnstableNode left = vm->newBigInt(a);
    UnstableNode right = SmallInt::build(vm, b);
    return Numeric(left).add(vm, right);
  }
}

UnstableNode SmallInt::subtract(VM vm, RichNode right) {
  return subtractValue(vm, getArgument<nativeint>(vm, right));
}

UnstableNode SmallInt::subtractValue(VM vm, nativeint b) {
  nativeint a = value();
  nativeint c = a - b;

  // Detecting overflow - platform dependent (2's complement)
  if ((((a ^ c) & (-b ^ c)) >> std::numeric_limits<nativeint>::digits) == 0) {
    // No overflow
    return SmallInt::build(vm, c);
  } else {
    // Overflow - TODO: create a BigInt
    return vm->newBigInt(0);
  }
}

UnstableNode SmallInt::multiply(VM vm, RichNode right) {
  if (right.is<SmallInt>()) {
    return multiplyValue(vm, right.as<SmallInt>().value());
  } else if (right.is<BigInt>()) {
    UnstableNode big = vm->newBigInt(value());
    return Numeric(big).multiply(vm, right);
  } else {
    raiseTypeError(vm, "Integer", right);
  }
}

bool SmallInt::testMultiplyOverflow(nativeint a, nativeint b) {
  // This is platform dependent (2's complement)

  nativeint absa = a < 0 ? -a : a;
  nativeint absb = b < 0 ? -b : b;

  // Fast test first
  // If both absa and absb < sqrt(max()), then obviously there is no overflow
  const int bits = std::numeric_limits<nativeint>::digits / 2;
  if (((absa | absb) >> bits) == 0)
    return false;

  // Slow test (because of the division)
  return (b != 0) && (absa >= std::numeric_limits<nativeint>::max() / absb);
}

UnstableNode SmallInt::multiplyValue(VM vm, nativeint b) {
  nativeint a = value();

  // Detecting overflow
  if (!testMultiplyOverflow(a, b)) {
    // No overflow
    return SmallInt::build(vm, a * b);
  } else {
    UnstableNode left = vm->newBigInt(a);
    UnstableNode right = SmallInt::build(vm, b);
    return Numeric(left).multiply(vm, right);
  }
}

UnstableNode SmallInt::div(VM vm, RichNode right) {
  return divValue(vm, getArgument<nativeint>(vm, right));
}

UnstableNode SmallInt::divValue(VM vm, nativeint b) {
  nativeint a = value();
  if (b == 0) {
    raiseKernelError(vm, "Integer division: Division by zero");
  }

  // Detecting overflow
  if ((a != std::numeric_limits<nativeint>::min()) || (b != -1)) {
    // No overflow
    return SmallInt::build(vm, a / b);
  } else {
    // Overflow - TODO: create a BigInt
    return vm->newBigInt(0);
  }
}

UnstableNode SmallInt::mod(VM vm, RichNode right) {
  return modValue(vm, getArgument<nativeint>(vm, right));
}

UnstableNode SmallInt::modValue(VM vm, nativeint b) {
  nativeint a = value();

  // Detecting overflow
  if ((a != std::numeric_limits<nativeint>::min()) || (b != -1)) {
    // No overflow
    return SmallInt::build(vm, a % b);
  } else {
    // Overflow - TODO: create a BigInt
    return vm->newBigInt(0);
  }
}

UnstableNode SmallInt::abs(VM vm) {
  nativeint a = value();
  // Detecting overflow - platform dependent (2's complement)
  if (a != std::numeric_limits<nativeint>::min()) {
    // No overflow
    return SmallInt::build(vm, a >= 0 ? a : -a);
  } else {
    // Overflow - TODO: create a BigInt
    return vm->newBigInt(0);
  }
}

}

#endif // MOZART_GENERATOR

#endif // MOZART_SMALLINT_H
