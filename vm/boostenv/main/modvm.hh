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

#ifndef MOZART_MODVMBOOST_H
#define MOZART_MODVMBOOST_H

#include <mozart.hh>

#include "boostenv-decl.hh"

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

namespace builtins {

using namespace ::mozart::builtins;

///////////////
// VM module //
///////////////

class ModVM: public Module {
public:
  ModVM(): Module("VM") {}

  class Current: public Builtin<Current> {
  public:
    Current(): Builtin("current") {}

    static void call(VM vm, Out result) {
      result = SmallInt::build(vm, (nativeint) vm); // TODO
    }
  };

  class New: public Builtin<New> {
  public:
    New(): Builtin("new") {}

    static void call(VM vm, In appURL, Out result) {
      std::string appURLstr(getArgument<atom_t>(vm, appURL).contents());
      BoostBasedVM::forVM(vm).addVM(64 * MegaBytes, appURLstr);
      result = SmallInt::build(vm, 0); // TODO
    }
  };
};

}

} }

#endif // MOZART_GENERATOR

#endif // MOZART_MODVMBOOST_H
