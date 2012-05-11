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

#ifndef __MODCELL_H
#define __MODCELL_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

/////////////////
// Cell module //
/////////////////

class ModCell: public Module {
public:
  ModCell(): Module("Cell") {}

  class New: public Builtin<New> {
  public:
    New(): Builtin("new") {}

    OpResult operator()(VM vm, In initial, Out result) {
      result = Cell::build(vm, initial);
      return OpResult::proceed();
    }
  };

  class ExchangeFun: public Builtin<ExchangeFun> {
  public:
    ExchangeFun(): Builtin("exchangeFun") {}

    OpResult operator()(VM vm, In cell, In newValue, Out oldValue) {
      return CellLike(cell).exchange(vm, newValue, oldValue);
    }
  };

  class Access: public Builtin<Access> {
  public:
    Access(): Builtin("access") {}

    OpResult operator()(VM vm, In cell, Out result) {
      return CellLike(cell).access(vm, result);
    }
  };

  class Assign: public Builtin<Assign> {
  public:
    Assign(): Builtin("assign") {}

    OpResult operator()(VM vm, In cell, In newValue) {
      return CellLike(cell).assign(vm, newValue);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODCELL_H
