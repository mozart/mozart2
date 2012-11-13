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

#ifndef __OBJECTS_DECL_H
#define __OBJECTS_DECL_H

#include "mozartcore-decl.hh"

#include "opcodes.hh"
#include "datatypeshelpers-decl.hh"

namespace mozart {

////////////
// Object //
////////////

#ifndef MOZART_GENERATOR
#include "Object-implem-decl.hh"
#endif

/**
 * Object
 */
class Object: public DataType<Object>, public WithHome,
  StoredWithArrayOf<UnstableNode> {
private:
  // defined in coredatatypes.cc
  static const ByteCode dispatchByteCode[9];
public:
  static atom_t getTypeAtom(VM vm) {
    return vm->getAtom(MOZART_STR("object"));
  }

  inline
  Object(VM vm, size_t attrCount, RichNode clazz,
         RichNode attrModel, RichNode featModel);

  inline
  Object(VM vm, size_t attrCount, GR gr, Self from);

public:
  // Requirement for StoredWithArrayOf
  size_t getArraySizeImpl() {
    return _attrCount;
  }

private:
  inline
  bool isFreeFlag(VM vm, RichNode value);

public:
  // Dottable interface

  inline
  bool lookupFeature(VM vm, RichNode feature,
                     nullable<UnstableNode&> value);

  inline
  bool lookupFeature(VM vm, nativeint feature,
                     nullable<UnstableNode&> value);

public:
  // ChunkLike interface

  bool isChunk(VM vm) {
    return true;
  }

public:
  // ObjectLike interface

  bool isObject(VM vm) {
    return true;
  }

  inline
  UnstableNode getClass(VM vm);

  inline
  UnstableNode attrGet(RichNode self, VM vm, RichNode attribute);

  inline
  void attrPut(RichNode self, VM vm, RichNode attribute, RichNode value);

  inline
  UnstableNode attrExchange(RichNode self, VM vm, RichNode attribute,
                            RichNode newValue);

private:
  inline
  size_t getAttrOffset(RichNode self, VM vm, RichNode attribute);

public:
  // Callable interface

  bool isCallable(VM vm) {
    return true;
  }

  bool isProcedure(VM vm) {
    return false;
  }

  inline
  size_t procedureArity(RichNode self, VM vm);

  inline
  void getCallInfo(RichNode self, VM vm, size_t& arity,
                   ProgramCounter& start, size_t& Xcount,
                   StaticArray<StableNode>& Gs,
                   StaticArray<StableNode>& Ks);

  inline
  void getDebugInfo(VM vm, atom_t& printName, UnstableNode& debugData);

public:
  void printReprToStream(VM vm, std::ostream& out, int depth) {
    out << "<Object>";
  }

private:
  StableNode _attrArity;
  size_t _attrCount;

  bool _GsInitialized;

  StableNode _clazz;
  StableNode _features;

  StableNode _Gs[2];
};

#ifndef MOZART_GENERATOR
#include "Object-implem-decl-after.hh"
#endif

}

#endif // __OBJECTS_DECL_H
