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

#ifndef __CALLABLES_DECL_H
#define __CALLABLES_DECL_H

#include "mozartcore.hh"

#include "opcodes.hh"

//////////////////////
// BuiltinProcedure //
//////////////////////

/**
 * Type of a builtin function
 */
typedef BuiltinResult (*OzBuiltin)(VM vm, UnstableNode* args[]);

class BuiltinProcedure;

#ifndef MOZART_GENERATOR
#include "BuiltinProcedure-implem-decl.hh"
#endif

template <>
class Implementation<BuiltinProcedure> {
public:
  typedef SelfType<BuiltinProcedure>::Self Self;
public:
  Implementation(VM, int arity, OzBuiltin builtin) :
    _arity(arity), _builtin(builtin) {}

  Implementation(VM vm, GC gc, Self from) {
    _arity = from->_arity;
    _builtin = from->_builtin;
  }

  /**
   * Arity of this builtin
   */
  int getArity() const { return _arity; }

  /**
   * Call the builtin
   * @param vm     Contextual VM
   * @param argc   Actual number of parameters
   * @param args   Actual parameters
   */
  BuiltinResult callBuiltin(Self self, VM vm, int argc, UnstableNode* args[]) {
    if (argc == _arity)
      return _builtin(vm, args);
    else
      return raiseIllegalArity(argc);
  }

  /**
   * Get the arity of the builtin in a node
   */
  inline
  BuiltinResult arity(Self self, VM vm, UnstableNode* result);
private:
  inline
  BuiltinResult raiseIllegalArity(int argc);

  int _arity;
  OzBuiltin _builtin;
};

/////////////////
// Abstraction //
/////////////////

class Abstraction;

#ifndef MOZART_GENERATOR
#include "Abstraction-implem-decl.hh"
#endif

/**
 * Abstraction value, i.e., user-defined procedure
 */
template <>
class Implementation<Abstraction>: StoredWithArrayOf<StableNode> {
public:
  typedef SelfType<Abstraction>::Self Self;
public:
  Implementation(VM vm, size_t Gc, StaticArray<StableNode> _Gs,
                 int arity, UnstableNode* body)
    : _arity(arity), _Gc(Gc) {
    _body.init(vm, *body);
    _codeAreaCacheValid = false;
  }

  inline
  Implementation(VM vm, size_t Gc, StaticArray<StableNode> _Gs,
                 GC gc, Self from);

  size_t getArraySize() {
    return _Gc;
  }

  int getArity() { return _arity; }

  /**
   * Get the arity of the abstraction in a node
   */
  inline
  BuiltinResult arity(Self self, VM vm, UnstableNode* result);

  inline
  BuiltinResult initElement(Self self, VM vm, size_t index,
                            UnstableNode* value);

  /**
   * Get the information needed to call this abstraction
   * @param vm       Contextual VM
   * @param arity    Output: arity of this abstraction
   * @param body     Output: code area which is the body
   * @param start    Output: start of the code area
   * @param Xcount   Output: number of X registers used by the code area
   * @param Gs       Output: G registers
   * @param Ks       Output: K registers
   */
  inline
  BuiltinResult getCallInfo(Self self, VM vm, int* arity, StableNode** body,
                            ProgramCounter* start, int* Xcount,
                            StaticArray<StableNode>* Gs,
                            StaticArray<StableNode>* Ks);
private:
  int _arity;
  StableNode _body;
  size_t _Gc;

  // cache for information of the code area
  bool _codeAreaCacheValid;
  ProgramCounter _start;
  int _Xcount;
  StaticArray<StableNode> _Ks;
};

#endif // __CALLABLES_DECL_H
