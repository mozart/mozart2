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

#ifndef __COREINTERFACES_DECL_H
#define __COREINTERFACES_DECL_H

#include "mozartcore-decl.hh"

#include "coredatatypes-decl.hh"
#include "exchelpers-decl.hh"

namespace mozart {

class DataflowVariable;
template<>
struct Interface<DataflowVariable>:
  ImplementedBy<Unbound, Variable, ReadOnly, FailedValue>, NoAutoWait {

  void addToSuspendList(RichNode self, VM vm, RichNode variable) {
    // TODO Should we immediately wake up the variable, here?
  }

  bool isNeeded(RichNode self, VM vm) {
    // Determined variables are always needed
    return true;
  }

  void markNeeded(RichNode self, VM vm) {
    // Nothing to do
  }

  /**
   * Precondition:
   *   self.type()->getStructuralBehavior() == sbVariable
   */
  OpResult bind(RichNode self, VM vm, RichNode src) {
    assert(self.type()->getStructuralBehavior() == sbVariable);
    assert(false);
    return raiseTypeError(vm, MOZART_STR("Variable"), self);
  }
};

class ValueEquatable;
template<>
struct Interface<ValueEquatable>:
  ImplementedBy<SmallInt, Atom, Boolean, Float, BuiltinProcedure,
                ReifiedThread, Unit, String, ByteString> {

  /**
   * Precondition:
   *   self.type()->getStructuralBehavior() == sbValue
   *   self.type() == right.type()
   */
  bool equals(RichNode self, VM vm, RichNode right) {
    assert(self.type()->getStructuralBehavior() == sbValue);
    assert(self.type() == right.type());
    assert(false);
    return false;
  }
};

class StructuralEquatable;
template<>
struct Interface<StructuralEquatable>:
  ImplementedBy<Tuple, Cons, Record, Arity> {

  /**
   * Precondition:
   *   self.type()->getStructuralBehavior() == sbStructural
   *   self.type() == right.type()
   */
  bool equals(RichNode self, VM vm, RichNode right, WalkStack& stack) {
    assert(self.type()->getStructuralBehavior() == sbStructural);
    assert(self.type() == right.type());
    assert(false);
    return false;
  }
};

class Comparable;
template<>
struct Interface<Comparable>:
  ImplementedBy<SmallInt, Atom, Float, String, ByteString> {

  OpResult compare(RichNode self, VM vm, RichNode right, int& result) {
    return raiseTypeError(vm, MOZART_STR("comparable"), self);
  }
};

class Wakeable;
template<>
struct Interface<Wakeable>:
  ImplementedBy<ReifiedThread, Variable, ReadOnly>, NoAutoWait {

  OpResult wakeUp(RichNode self, VM vm) {
    return OpResult::proceed();
  }

  bool shouldWakeUpUnderSpace(RichNode self, VM vm, Space* space) {
    return false;
  }
};

class Literal;
template<>
struct Interface<Literal>:
  ImplementedBy<Atom, OptName, GlobalName, Boolean, Unit> {

  OpResult isLiteral(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }
};

class NameLike;
template<>
struct Interface<NameLike>: ImplementedBy<OptName, GlobalName> {
  OpResult isName(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }
};

class AtomLike;
template<>
struct Interface<AtomLike>: ImplementedBy<Atom> {
  OpResult isAtom(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }
};

class PotentialFeature;
template<>
struct Interface<PotentialFeature>: ImplementedBy<OptName> {
  OpResult makeFeature(RichNode self, VM vm) {
    if (self.isFeature())
      return OpResult::proceed();
    else
      return raiseTypeError(vm, MOZART_STR("feature"), self);
  }
};

class BuiltinCallable;
template<>
struct Interface<BuiltinCallable>: ImplementedBy<BuiltinProcedure> {
  OpResult callBuiltin(RichNode self, VM vm, int argc,
                       UnstableNode* args[]) {
    return raiseTypeError(vm, MOZART_STR("BuiltinProcedure"), self);
  }

  template <class... Args>
  OpResult callBuiltin(RichNode self, VM vm, Args&&... args) {
    return raiseTypeError(vm, MOZART_STR("BuiltinProcedure"), self);
  }
};

class Callable;
template<>
struct Interface<Callable>:
  ImplementedBy<Abstraction, Object, BuiltinProcedure> {

  OpResult isCallable(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult isProcedure(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult procedureArity(RichNode self, VM vm, int& result) {
    return raiseTypeError(vm, MOZART_STR("Abstraction"), self);
  }

  OpResult getCallInfo(RichNode self, VM vm, int& arity,
                       ProgramCounter& start, int& Xcount,
                       StaticArray<StableNode>& Gs,
                       StaticArray<StableNode>& Ks) {
    arity = 0;
    start = nullptr;
    Xcount = 0;
    Gs = nullptr;
    Ks = nullptr;
    return raiseTypeError(vm, MOZART_STR("Abstraction"), self);
  }
};

class CodeAreaProvider;
template<>
struct Interface<CodeAreaProvider>: ImplementedBy<CodeArea> {
  OpResult getCodeAreaInfo(RichNode self, VM vm, ProgramCounter& start,
                           int& Xcount, StaticArray<StableNode>& Ks) {
    start = nullptr;
    Xcount = 0;
    Ks = nullptr;
    return raiseTypeError(vm, MOZART_STR("CodeArea"), self);
  }
};

class Numeric;
template<>
struct Interface<Numeric>: ImplementedBy<SmallInt, Float> {
  OpResult isNumber(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult isInt(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult isFloat(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult opposite(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  OpResult add(RichNode self, VM vm,
               RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  OpResult subtract(RichNode self, VM vm,
                    RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  OpResult multiply(RichNode self, VM vm,
                    RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  OpResult divide(RichNode self, VM vm,
                  RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  OpResult div(RichNode self, VM vm,
               RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  OpResult mod(RichNode self, VM vm,
               RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }
};

class IntegerValue;
template<>
struct Interface<IntegerValue>: ImplementedBy<SmallInt> {
  OpResult intValue(RichNode self, VM vm, nativeint& result) {
    return raiseTypeError(vm, MOZART_STR("Integer"), self);
  }

  OpResult equalsInteger(RichNode self, VM vm,
                         nativeint right, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult addValue(RichNode self, VM vm,
                    nativeint b, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Integer"), self);
  }
};

class FloatValue;
template<>
struct Interface<FloatValue>: ImplementedBy<Float> {
  OpResult floatValue(RichNode self, VM vm, double& result) {
    return raiseTypeError(vm, MOZART_STR("Float"), self);
  }

  OpResult equalsFloat(RichNode self, VM vm,
                       double right, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult addValue(RichNode self, VM vm,
                    double b, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Float"), self);
  }
};

class BooleanValue;
template<>
struct Interface<BooleanValue>: ImplementedBy<Boolean> {
  OpResult boolValue(RichNode self, VM vm, bool& result) {
    return raiseTypeError(vm, MOZART_STR("Boolean"), self);
  }

  OpResult valueOrNotBool(RichNode self, VM vm, BoolOrNotBool& result) {
    result = bNotBool;
    return OpResult::proceed();
  }
};

class Dottable;
template<>
struct Interface<Dottable>:
  ImplementedBy<Tuple, Record, Object, Chunk, Cons, Array, Dictionary,
    Atom, OptName, GlobalName, Boolean, Unit> {

  OpResult dot(RichNode self, VM vm, RichNode feature,
               UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Record or Chunk"), self);
  }

  OpResult hasFeature(RichNode self, VM vm, RichNode feature, bool& result) {
    return raiseTypeError(vm, MOZART_STR("Record or Chunk"), self);
  }
};

class RecordLike;
template<>
struct Interface<RecordLike>:
  ImplementedBy<Tuple, Record, Cons,
    Atom, OptName, GlobalName, Boolean, Unit> {

  OpResult isRecord(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult isTuple(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult label(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  OpResult width(RichNode self, VM vm, size_t& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  OpResult arityList(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  OpResult clone(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  OpResult waitOr(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }
};

class ArrayLike;
template <>
struct Interface<ArrayLike>: ImplementedBy<Array> {

  OpResult isArray(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult arrayLow(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }

  OpResult arrayHigh(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }

  OpResult arrayGet(RichNode self, VM vm, RichNode index,
                    UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }

  OpResult arrayPut(RichNode self, VM vm, RichNode index, RichNode value) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }

  OpResult arrayExchange(RichNode self, VM vm, RichNode index,
                         RichNode newValue, UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }
};

class DictionaryLike;
template <>
struct Interface<DictionaryLike>: ImplementedBy<Dictionary> {

  OpResult isDictionary(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult dictIsEmpty(RichNode self, VM vm, bool& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictMember(RichNode self, VM vm, RichNode feature, bool& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictGet(RichNode self, VM vm, RichNode feature,
                   UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictCondGet(RichNode self, VM vm, RichNode feature,
                       RichNode defaultValue, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictPut(RichNode self, VM vm, RichNode feature, RichNode newValue) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictExchange(RichNode self, VM vm, RichNode feature,
                        RichNode newValue, UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictCondExchange(RichNode self, VM vm, RichNode feature,
                            RichNode defaultValue,
                            RichNode newValue, UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictRemove(RichNode self, VM vm, RichNode feature) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictRemoveAll(RichNode self, VM vm) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictKeys(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictEntries(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictItems(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  OpResult dictClone(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }
};

class ObjectLike;
template <>
struct Interface<ObjectLike>: ImplementedBy<Object> {
  OpResult isObject(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult getClass(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("object"), self);
  }

  OpResult attrGet(RichNode self, VM vm, RichNode attribute,
                    UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("object"), self);
  }

  OpResult attrPut(RichNode self, VM vm, RichNode attribute, RichNode value) {
    return raiseTypeError(vm, MOZART_STR("object"), self);
  }

  OpResult attrExchange(RichNode self, VM vm, RichNode attribute,
                        RichNode newValue, UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("object"), self);
  }
};

class ArrayInitializer;
template<>
struct Interface<ArrayInitializer>:
  ImplementedBy<Tuple, Record, Abstraction, CodeArea> {

  OpResult initElement(RichNode self, VM vm, size_t index, RichNode value) {
    return raiseTypeError(vm, MOZART_STR("Array initializer"), self);
  }
};

class SpaceLike;
template<>
struct Interface<SpaceLike>: ImplementedBy<ReifiedSpace, DeletedSpace> {
  OpResult isSpace(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult askSpace(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  OpResult askVerboseSpace(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  OpResult mergeSpace(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  OpResult commitSpace(RichNode self, VM vm, RichNode value) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  OpResult cloneSpace(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  OpResult killSpace(RichNode self, VM vm) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }
};

class ThreadLike;
template<>
struct Interface<ThreadLike>: ImplementedBy<ReifiedThread> {
  OpResult isThread(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult getThreadPriority(RichNode self, VM vm, ThreadPriority& result) {
    return raiseTypeError(vm, MOZART_STR("Thread"), self);
  }

  OpResult setThreadPriority(RichNode self, VM vm, ThreadPriority priority) {
    return raiseTypeError(vm, MOZART_STR("Thread"), self);
  }
};

class CellLike;
template<>
struct Interface<CellLike>: ImplementedBy<Cell> {
  OpResult isCell(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult exchange(RichNode self, VM vm, RichNode newValue,
                    UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("Cell"), self);
  }

  OpResult access(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Cell"), self);
  }

  OpResult assign(RichNode self, VM vm, RichNode newValue) {
    return raiseTypeError(vm, MOZART_STR("Cell"), self);
  }
};

class ChunkLike;
template<>
struct Interface<ChunkLike>: ImplementedBy<Chunk, Object> {
  OpResult isChunk(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }
};

class StringLike;
template<>
struct Interface<StringLike>: ImplementedBy<String, ByteString> {
  OpResult isString(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult isByteString(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult stringGet(RichNode self, VM vm, LString<nchar>*& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  OpResult stringGet(RichNode self, VM vm, LString<unsigned char>*& result) {
    return raiseTypeError(vm, MOZART_STR("ByteString"), self);
  }

  OpResult stringCharAt(RichNode self, VM vm,
                        RichNode offset, nativeint& character) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  OpResult stringAppend(RichNode self, VM vm,
                        RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  OpResult stringSlice(RichNode self, VM vm,
                       RichNode from, RichNode to, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  OpResult stringSearch(RichNode self, VM vm, RichNode from, RichNode needle,
                        UnstableNode& begin, UnstableNode& end) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  OpResult stringHasPrefix(RichNode self, VM vm, RichNode prefix, bool& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  OpResult stringHasSuffix(RichNode self, VM vm, RichNode suffix, bool& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }
};

class VirtualString;
template<>
struct Interface<VirtualString>:
  ImplementedBy<SmallInt, Float, Atom, Boolean, String, Unit, Cons, Tuple,
                ByteString> {

  OpResult isVirtualString(RichNode self, VM vm, bool& result) {
    result = false;
    return OpResult::proceed();
  }

  OpResult toString(RichNode self, VM vm, std::basic_ostream<nchar>& sink) {
    return raiseTypeError(vm, MOZART_STR("VirtualString"), self);
  }

  OpResult vsLength(RichNode self, VM vm, nativeint& result) {
    return raiseTypeError(vm, MOZART_STR("VirtualString"), self);
  }
};

}

#endif // __COREINTERFACES_DECL_H
