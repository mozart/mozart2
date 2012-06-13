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

#ifndef __MODOSBOOST_H
#define __MODOSBOOST_H

#include <mozart.hh>

#include "boostenv-decl.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

namespace builtins {

using namespace ::mozart::builtins;

///////////////
// OS module //
///////////////

class ModOS: public Module {
public:
  ModOS(): Module("OS") {}

  class Rand: public Builtin<Rand> {
  public:
    Rand(): Builtin("rand") {}

    OpResult operator()(VM vm, Out result) {
      auto& env = static_cast<BoostBasedVM&>(vm->getEnvironment());

      result = SmallInt::build(vm, env.random_generator());

      return OpResult::proceed();
    }
  };

  class Srand: public Builtin<Srand> {
  public:
    Srand(): Builtin("srand") {}

    OpResult operator()(VM vm, In seed) {
      nativeint intSeed;
      MOZART_GET_ARG(intSeed, seed, u"integer");

      auto& env = static_cast<BoostBasedVM&>(vm->getEnvironment());
      env.random_generator.seed(
        (BoostBasedVM::random_generator_t::result_type) intSeed);

      return OpResult::proceed();
    }
  };

  class RandLimits: public Builtin<RandLimits> {
  public:
    RandLimits(): Builtin("randLimits") {}

    OpResult operator()(VM vm, Out min, Out max) {
      min = SmallInt::build(vm, BoostBasedVM::random_generator_t::min());
      max = SmallInt::build(vm, BoostBasedVM::random_generator_t::max());

      return OpResult::proceed();
    }
  };
};

}

} }

#endif // MOZART_GENERATOR

#endif // __MODOSBOOST_H
