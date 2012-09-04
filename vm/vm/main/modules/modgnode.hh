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

#ifndef __MODGNODE_H
#define __MODGNODE_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////
// GNode module //
//////////////////

class ModGNode: public Module {
public:
  ModGNode(): Module("GNode") {}

  class Globalize: public Builtin<Globalize> {
  public:
    Globalize(): Builtin("globalize") {}

    static void call(VM vm, In lhs, Out result) {
      result = build(vm, lhs.type()->globalize(vm, lhs));
    }
  };

  class Load: public Builtin<Load> {
  public:
    Load(): Builtin("load") {}

    static void call(VM vm, In uuid, Out gnode, Out existed) {
      auto uuidValue = getArgument<UUID>(vm, uuid);

      GlobalNode* n;
      bool ex = GlobalNode::get(vm, uuidValue, n);
      if (!ex) {
        n->self.init(vm, OptVar::build(vm));
        n->protocol.init(vm, OptVar::build(vm));
      }

      gnode = build(vm, n);
      existed = build(vm, ex);
    }
  };

  class GetValue: public Builtin<GetValue> {
  public:
    GetValue(): Builtin("getValue") {}

    static void call(VM vm, In gnode, Out result) {
      auto node = getArgument<GlobalNode*>(vm, gnode);
      result.copy(vm, node->self);
    }
  };

  class GetProto: public Builtin<GetProto> {
  public:
    GetProto(): Builtin("getProto") {}

    static void call(VM vm, In gnode, Out result) {
      auto node = getArgument<GlobalNode*>(vm, gnode);
      result.copy(vm, node->protocol);
    }
  };

  class GetUUID: public Builtin<GetUUID> {
  public:
    GetUUID(): Builtin("getUUID") {}

    static void call(VM vm, In gnode, Out result) {
      auto node = getArgument<GlobalNode*>(vm, gnode);
      result = build(vm, node->uuid);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODGNODE_H
