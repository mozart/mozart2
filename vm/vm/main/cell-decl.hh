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

#ifndef __CELL_DECL_H
#define __CELL_DECL_H

#include "mozartcore-decl.hh"

namespace mozart {

//////////
// Cell //
//////////

#ifndef MOZART_GENERATOR
#include "Cell-implem-decl.hh"
#endif

class Cell: public DataType<Cell>, public WithHome {
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("cell"));
  }

  Cell(VM vm, RichNode initial): WithHome(vm) {
    _value.init(vm, initial);
  }

  inline
  Cell(VM vm, GR gr, Cell& from);

public:
  // CellLike interface

  bool isCell(VM vm) {
    return true;
  }

  inline
  UnstableNode exchange(VM vm, RichNode newValue);

  inline
  UnstableNode access(VM vm);

  inline
  void assign(VM vm, RichNode newValue);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth, int width) {
    out << "<Cell: " << repr(vm, _value, depth, width) << ">";
  }

private:
  UnstableNode _value;
};

#ifndef MOZART_GENERATOR
#include "Cell-implem-decl-after.hh"
#endif

}

#endif // __CELL_DECL_H
