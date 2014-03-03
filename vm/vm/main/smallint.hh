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
    return SmallInt::build(vm, 0);
  }
}

UnstableNode SmallInt::add(VM vm, RichNode right) {
  return add(vm, getArgument<nativeint>(vm, right));
}

UnstableNode SmallInt::add(VM vm, nativeint b) {
  nativeint a = value();
  nativeint c = a + b;

  // Detecting overflow - platform dependent (2's complement)
  if ((((a ^ c) & (b ^ c)) >> std::numeric_limits<nativeint>::digits) == 0) {
    // No overflow
    return SmallInt::build(vm, c);
  } else {
    // Overflow - TODO: create a BigInt
    return SmallInt::build(vm, 0);
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
    return SmallInt::build(vm, 0);
  }
}

UnstableNode SmallInt::multiply(VM vm, RichNode right) {
  return multiplyValue(vm, getArgument<nativeint>(vm, right));
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
    // Overflow - TODO: create a BigInt
    return SmallInt::build(vm, 0);
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
    return SmallInt::build(vm, 0);
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
    return SmallInt::build(vm, 0);
  }
}

UnstableNode SmallInt::pow(VM vm, RichNode right) {
  return powValue(vm, getArgument<nativeint>(vm, right));
}

UnstableNode SmallInt::powValue(VM vm, nativeint b) {
  nativeint a = value();

  // Negative powers disallowed
  if (b < 0) {
    raiseKernelError(vm, "Integer power: Negative indices disallowed");
  }

  nativeint product = 1;
  for (int i = 0; i < b; i++) {
    if (!testMultiplyOverflow(product, a)) {
      // No overflow
      product *= a;
    } else {
      // Overflow - TODO: create a BigInt
      product = 0;
      break;
    }
  }
  return SmallInt::build(vm, product);
}

UnstableNode SmallInt::abs(VM vm) {
  nativeint a = value();
  // Detecting overflow - platform dependent (2's complement)
  if (a != std::numeric_limits<nativeint>::min()) {
    // No overflow
    return SmallInt::build(vm, a >= 0 ? a : -a);
  } else {
    // Overflow - TODO: create a BigInt
    return SmallInt::build(vm, 0);
  }
}

// Float module functions - will return a type error via Numeric interface

UnstableNode SmallInt::divide(RichNode self, VM vm, RichNode right) {
  return Interface<Numeric>().divide(self, vm, right);
}

UnstableNode SmallInt::fmod(RichNode self, VM vm, RichNode right) {
  return Interface<Numeric>().fmod(self, vm, right);
}

UnstableNode SmallInt::acos(RichNode self, VM vm) {
  return Interface<Numeric>().acos(self, vm);
}

UnstableNode SmallInt::acosh(RichNode self, VM vm) {
  return Interface<Numeric>().acosh(self, vm);
}

UnstableNode SmallInt::asin(RichNode self, VM vm) {
  return Interface<Numeric>().asin(self, vm);
}

UnstableNode SmallInt::asinh(RichNode self, VM vm) {
  return Interface<Numeric>().asinh(self, vm);
}

UnstableNode SmallInt::atan(RichNode self, VM vm) {
  return Interface<Numeric>().atan(self, vm);
}

UnstableNode SmallInt::atanh(RichNode self, VM vm) {
  return Interface<Numeric>().atanh(self, vm);
}

UnstableNode SmallInt::atan2(RichNode self, VM vm, RichNode right) {
  return Interface<Numeric>().atan2(self, vm, right);
}

UnstableNode SmallInt::ceil(RichNode self, VM vm) {
  return Interface<Numeric>().ceil(self, vm);
}

UnstableNode SmallInt::cos(RichNode self, VM vm) {
  return Interface<Numeric>().cos(self, vm);
}

UnstableNode SmallInt::cosh(RichNode self, VM vm) {
  return Interface<Numeric>().cosh(self, vm);
}

UnstableNode SmallInt::exp(RichNode self, VM vm) {
  return Interface<Numeric>().exp(self, vm);
}

UnstableNode SmallInt::floor(RichNode self, VM vm) {
  return Interface<Numeric>().floor(self, vm);
}

UnstableNode SmallInt::log(RichNode self, VM vm) {
  return Interface<Numeric>().log(self, vm);
}

UnstableNode SmallInt::round(RichNode self, VM vm) {
  return Interface<Numeric>().round(self, vm);
}

UnstableNode SmallInt::sin(RichNode self, VM vm) {
  return Interface<Numeric>().sin(self, vm);
}

UnstableNode SmallInt::sinh(RichNode self, VM vm) {
  return Interface<Numeric>().sinh(self, vm);
}

UnstableNode SmallInt::sqrt(RichNode self, VM vm) {
  return Interface<Numeric>().sqrt(self, vm);
}

UnstableNode SmallInt::tan(RichNode self, VM vm) {
  return Interface<Numeric>().tan(self, vm);
}

UnstableNode SmallInt::tanh(RichNode self, VM vm) {
  return Interface<Numeric>().tanh(self, vm);
}

}

#endif // MOZART_GENERATOR

#endif // MOZART_SMALLINT_H
