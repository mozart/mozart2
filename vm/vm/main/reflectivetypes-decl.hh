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

#ifndef __REFLECTIVETYPES_DECL_H
#define __REFLECTIVETYPES_DECL_H

#include "mozartcore-decl.hh"

#include "datatypeshelpers-decl.hh"
#include "variables-decl.hh"

namespace mozart {

//////////////////////
// ReflectiveEntity //
//////////////////////

#ifndef MOZART_GENERATOR
#include "ReflectiveEntity-implem-decl.hh"
#endif

class ReflectiveEntity: public DataType<ReflectiveEntity> {
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("reflective"));
  }

  inline
  ReflectiveEntity(VM vm, UnstableNode& stream);

  inline
  ReflectiveEntity(VM vm, GR gr, ReflectiveEntity& from);

public:
  // Reflective call

  template <typename Label, typename... Args>
  inline
  bool reflectiveCall(VM vm, const nchar* identity,
                      Label&& label, Args&&... args);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth, int width) {
    out << "<ReflectiveEntity>";
  }

private:
  UnstableNode _stream;
};

#ifndef MOZART_GENERATOR
#include "ReflectiveEntity-implem-decl-after.hh"
#endif

////////////////////////
// ReflectiveVariable //
////////////////////////

#ifndef MOZART_GENERATOR
#include "ReflectiveVariable-implem-decl.hh"
#endif

class ReflectiveVariable: public DataType<ReflectiveVariable>,
  public VariableBase<ReflectiveVariable>,
  Transient, WithVariableBehavior<85> {
public:
  inline
  ReflectiveVariable(VM vm, UnstableNode& stream);

  inline
  ReflectiveVariable(VM vm, Space* home, UnstableNode& stream);

  inline
  ReflectiveVariable(VM vm, GR gr, ReflectiveVariable& from);

public:
  // DataflowVariable interface

  inline
  void markNeeded(VM vm);

  inline
  void bind(VM vm, RichNode src);

  inline
  void reflectiveBind(RichNode self, VM vm, RichNode src);

public:
  // Miscellaneous

  void printReprToStream(VM vm, std::ostream& out, int depth, int width) {
    out << "_<Reflective>";
  }

private:
  UnstableNode _stream;
};

#ifndef MOZART_GENERATOR
#include "ReflectiveVariable-implem-decl-after.hh"
#endif

}

#endif // __REFLECTIVETYPES_DECL_H
