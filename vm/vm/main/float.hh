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

#ifndef __FLOAT_H
#define __FLOAT_H

#include <tuple>
#include <memory>
#include <cmath>
#include "mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

///////////
// Float //
///////////

#include "Float-implem.hh"

void Float::create(double& self, VM vm, GR gr, Float from) {
  self = from.value();
}

bool Float::equals(VM vm, RichNode right) {
  return value() == right.as<Float>().value();
}

int Float::compare(VM vm, RichNode right) {
  auto rightFloatValue = getArgument<double>(vm, right);
  return (value() < rightFloatValue) ? -1 : (value() > rightFloatValue) ? 1 : 0;
}

UnstableNode Float::opposite(VM vm) {
  return Float::build(vm, -value());
}

UnstableNode Float::add(VM vm, RichNode right) {
  return addValue(vm, getArgument<double>(vm, right));
}

UnstableNode Float::add(RichNode self, VM vm, nativeint right) {
  return Interface<Numeric>().add(self, vm, right);
}

UnstableNode Float::addValue(VM vm, double b) {
  return Float::build(vm, value() + b);
}

UnstableNode Float::subtract(VM vm, RichNode right) {
  return subtractValue(vm, getArgument<double>(vm, right));
}

UnstableNode Float::subtractValue(VM vm, double b) {
  return Float::build(vm, value() - b);
}

UnstableNode Float::multiply(VM vm, RichNode right) {
  return multiplyValue(vm, getArgument<double>(vm, right));
}

UnstableNode Float::multiplyValue(VM vm, double b) {
  return Float::build(vm, value() * b);
}

UnstableNode Float::divide(VM vm, RichNode right) {
  return divideValue(vm, getArgument<double>(vm, right));
}

UnstableNode Float::divideValue(VM vm, double b) {
  return Float::build(vm, value() / b);
}

UnstableNode Float::fmod(VM vm, RichNode right) {
  return fmodValue(vm, getArgument<double>(vm, right));
}

UnstableNode Float::fmodValue(VM vm, double b) {
  return Float::build(vm, std::fmod(value(), b));
}

UnstableNode Float::div(RichNode self, VM vm, RichNode right) {
  return Interface<Numeric>().div(self, vm, right);
}

UnstableNode Float::mod(RichNode self, VM vm, RichNode right) {
  return Interface<Numeric>().mod(self, vm, right);
}

UnstableNode Float::pow(VM vm, RichNode right) {
  return powValue(vm, getArgument<double>(vm, right));
}

UnstableNode Float::powValue(VM vm, double b) {
  return Float::build(vm, std::pow(value(), b));
}

UnstableNode Float::abs(VM vm) {
  double a = value();
  return Float::build(vm, a >= 0 ? a : -a);
}

UnstableNode Float::acos(VM vm) {
  return Float::build(vm, std::acos(value()));
}

UnstableNode Float::acosh(VM vm) {
  return Float::build(vm, std::acosh(value()));
}

UnstableNode Float::asin(VM vm) {
  return Float::build(vm, std::asin(value()));
}

UnstableNode Float::asinh(VM vm) {
  return Float::build(vm, std::asinh(value()));
}

UnstableNode Float::atan(VM vm) {
  return Float::build(vm, std::atan(value()));
}

UnstableNode Float::atanh(VM vm) {
  return Float::build(vm, std::atanh(value()));
}

UnstableNode Float::atan2(VM vm, RichNode right) {
  return atan2Value(vm, getArgument<double>(vm, right));
}

UnstableNode Float::atan2Value(VM vm, double b) {
  return Float::build(vm, std::atan2(value(), b));
}

UnstableNode Float::ceil(VM vm) {
  return Float::build(vm, std::ceil(value()));
}

UnstableNode Float::cos(VM vm) {
  return Float::build(vm, std::cos(value()));
}

UnstableNode Float::cosh(VM vm) {
  return Float::build(vm, std::cosh(value()));
}

UnstableNode Float::exp(VM vm) {
  return Float::build(vm, std::exp(value()));
}

UnstableNode Float::floor(VM vm) {
  return Float::build(vm, std::floor(value()));
}

UnstableNode Float::log(VM vm) {
  return Float::build(vm, std::log(value()));
}

UnstableNode Float::round(VM vm) {
  return Float::build(vm, std::round(value()));
}

UnstableNode Float::sin(VM vm) {
  return Float::build(vm, std::sin(value()));
}

UnstableNode Float::sinh(VM vm) {
  return Float::build(vm, std::sinh(value()));
}

UnstableNode Float::sqrt(VM vm) {
  return Float::build(vm, std::sqrt(value()));
}

UnstableNode Float::tan(VM vm) {
  return Float::build(vm, std::tan(value()));
}

UnstableNode Float::tanh(VM vm) {
  return Float::build(vm, std::tanh(value()));
}

}

#endif // MOZART_GENERATOR

#endif // __FLOAT_H
