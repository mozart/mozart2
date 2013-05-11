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

#ifndef __REIFIEDGNODE_DECL_H
#define __REIFIEDGNODE_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

//////////////////
// ReifiedGNode //
//////////////////

#ifndef MOZART_GENERATOR
#include "ReifiedGNode-implem-decl.hh"
#endif

class ReifiedGNode: public DataType<ReifiedGNode>,
  StoredAs<GlobalNode*>, WithValueBehavior {
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("gNode"));
  }

  explicit ReifiedGNode(GlobalNode* value): _value(value) {}

  static void create(GlobalNode*& self, VM vm, GlobalNode* value) {
    self = value;
  }

  inline
  static void create(GlobalNode*& self, VM vm, GR gr, ReifiedGNode from);

public:
  GlobalNode* value() const {
    return _value;
  }

  inline
  bool equals(VM vm, RichNode right);

private:
  GlobalNode* _value;
};

#ifndef MOZART_GENERATOR
#include "ReifiedGNode-implem-decl-after.hh"
#endif

}

#endif // __REIFIEDGNODE_DECL_H
