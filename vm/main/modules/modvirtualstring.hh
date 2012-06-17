// Copyright © 2012, Université catholique de Louvain
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

#ifndef __MODVIRTUALSTRING_H
#define __MODVIRTUALSTRING_H

#include "../mozartcore.hh"

#include <sstream>

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////////////
// VirtualString module //
//////////////////////////

class ModVirtualString : public Module {
public:
  ModVirtualString() : Module("VirtualString") {}

  class Is : public Builtin<Is> {
  public:
    Is() : Builtin("is") {}

    OpResult operator()(VM vm, In value, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(VirtualString(value).isVirtualString(vm, boolResult));
      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class ToString : public Builtin<ToString> {
  public:
    ToString() : Builtin("toString") {}

    OpResult operator()(VM vm, In value, Out result) {
      std::basic_ostringstream<nchar> combinedStringStream;
      MOZART_CHECK_OPRESULT(VirtualString(value).toString(vm, combinedStringStream));
      result = buildString(vm, newLString(vm, combinedStringStream.str()));
      // ^ we need to call newLString() to move the result from the stack into
      //   the VM heap.
      return OpResult::proceed();
    }
  };

  class Length : public Builtin<Length> {
  public:
    Length() : Builtin("length") {}

    OpResult operator()(VM vm, In value, Out result) {
      nativeint length;
      MOZART_CHECK_OPRESULT(VirtualString(value).vsLength(vm, length));
      result = SmallInt::build(vm, length);
      return OpResult::proceed();
    }
  };

  class ChangeSign : public Builtin<ChangeSign> {
  public:
    ChangeSign() : Builtin("changeSign") {}

    OpResult operator()(VM vm, In value, In replacement, Out result) {
      return VirtualString(value).vsChangeSign(vm, replacement, result);
    }
  };
};

}

}

#endif

#endif

