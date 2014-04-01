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

#ifndef MOZART_REIFIEDVM_DECL_H
#define MOZART_REIFIEDVM_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

///////////////
// ReifiedVM //
///////////////

#ifndef MOZART_GENERATOR
#include "ReifiedVM-implem-decl.hh"
#endif

class ReifiedVM: public DataType<ReifiedVM>,
  StoredAs<VM>, WithValueBehavior {
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom("vm");
  }

  explicit ReifiedVM(VM target): _vm(target) {}

  static void create(VM& self, VM vm, VM target) {
    self = target;
  }

  static void create(VM& self, VM vm, GR gr, ReifiedVM from) {
    self = from._vm;
  }

public:
  VM value() {
    return _vm;
  }

public:
  inline
  bool equals(VM vm, RichNode right);

public:
  // PortLike interface

  bool isPort(VM vm) {
    return true;
  }

  inline
  void send(VM vm, RichNode value);

  inline
  UnstableNode sendReceive(VM vm, RichNode value);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth, int width) {
    out << "<ReifiedVM @ " << _vm << ">";
  }

private:
  VM _vm;
};

#ifndef MOZART_GENERATOR
#include "ReifiedVM-implem-decl-after.hh"
#endif

}

#endif // MOZART_REIFIEDVM_DECL_H
