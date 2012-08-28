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
#include "builtins-decl.hh"

namespace mozart {

class DataflowVariable;
template<>
struct Interface<DataflowVariable>:
  ImplementedBy<OptVar, Variable, ReadOnly, FailedValue>, NoAutoWait {

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
  void bind(RichNode self, VM vm, RichNode src) {
    assert(self.type()->getStructuralBehavior() == sbVariable);
    assert(false);
    return raiseTypeError(vm, MOZART_STR("Variable"), self);
  }
};

class ValueEquatable;
template<>
struct Interface<ValueEquatable>:
  ImplementedBy<SmallInt, Atom, Boolean, Float, BuiltinProcedure,
                ReifiedThread, Unit, String, ByteString, UniqueName,
                PatMatCapture> {

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

  void compare(RichNode self, VM vm, RichNode right, int& result) {
    return raiseTypeError(vm, MOZART_STR("comparable"), self);
  }
};

class Wakeable;
template<>
struct Interface<Wakeable>:
  ImplementedBy<ReifiedThread, Variable, ReadOnly>, NoAutoWait {

  void wakeUp(RichNode self, VM vm) {
  }

  bool shouldWakeUpUnderSpace(RichNode self, VM vm, Space* space) {
    return false;
  }
};

class Literal;
template<>
struct Interface<Literal>:
  ImplementedBy<Atom, OptName, GlobalName, Boolean, Unit> {

  void isLiteral(RichNode self, VM vm, bool& result) {
    result = false;
  }
};

class NameLike;
template<>
struct Interface<NameLike>: ImplementedBy<OptName, GlobalName> {
  void isName(RichNode self, VM vm, bool& result) {
    result = false;
  }
};

class AtomLike;
template<>
struct Interface<AtomLike>: ImplementedBy<Atom> {
  void isAtom(RichNode self, VM vm, bool& result) {
    result = false;
  }
};

class PotentialFeature;
template<>
struct Interface<PotentialFeature>: ImplementedBy<OptName> {
  void makeFeature(RichNode self, VM vm) {
    if (!self.isFeature())
      return raiseTypeError(vm, MOZART_STR("feature"), self);
  }
};

class BuiltinCallable;
template<>
struct Interface<BuiltinCallable>: ImplementedBy<BuiltinProcedure> {
  void isBuiltin(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void callBuiltin(RichNode self, VM vm, size_t argc,
                   UnstableNode* args[]) {
    return raiseTypeError(vm, MOZART_STR("BuiltinProcedure"), self);
  }

  template <class... Args>
  void callBuiltin(RichNode self, VM vm, Args&&... args) {
    return raiseTypeError(vm, MOZART_STR("BuiltinProcedure"), self);
  }

  void getBuiltin(RichNode self, VM vm, builtins::BaseBuiltin*& result) {
    return raiseTypeError(vm, MOZART_STR("BuiltinProcedure"), self);
  }
};

class Callable;
template<>
struct Interface<Callable>:
  ImplementedBy<Abstraction, Object, BuiltinProcedure> {

  void isCallable(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void isProcedure(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void procedureArity(RichNode self, VM vm, size_t& result) {
    return raiseTypeError(vm, MOZART_STR("Abstraction"), self);
  }

  void getCallInfo(RichNode self, VM vm, size_t& arity,
                   ProgramCounter& start, size_t& Xcount,
                   StaticArray<StableNode>& Gs,
                   StaticArray<StableNode>& Ks) {
    return raiseTypeError(vm, MOZART_STR("Abstraction"), self);
  }

  void getDebugInfo(RichNode self, VM vm,
                    atom_t& printName, UnstableNode& debugData) {
    return raiseTypeError(vm, MOZART_STR("Abstraction"), self);
  }
};

class CodeAreaProvider;
template<>
struct Interface<CodeAreaProvider>: ImplementedBy<CodeArea> {
  void isCodeAreaProvider(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void getCodeAreaInfo(RichNode self, VM vm, size_t& arity,
                       ProgramCounter& start, size_t& Xcount,
                       StaticArray<StableNode>& Ks) {
    return raiseTypeError(vm, MOZART_STR("CodeArea"), self);
  }

  void getCodeAreaDebugInfo(RichNode self, VM vm,
                            atom_t& printName, UnstableNode& debugData) {
    return raiseTypeError(vm, MOZART_STR("CodeArea"), self);
  }
};

class Numeric;
template<>
struct Interface<Numeric>: ImplementedBy<SmallInt, Float> {
  void isNumber(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void isInt(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void isFloat(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void opposite(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  void add(RichNode self, VM vm, RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  void subtract(RichNode self, VM vm, RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  void multiply(RichNode self, VM vm, RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  void divide(RichNode self, VM vm, RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  void div(RichNode self, VM vm, RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  void mod(RichNode self, VM vm, RichNode right, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }
};

class IntegerValue;
template<>
struct Interface<IntegerValue>: ImplementedBy<SmallInt> {
  void intValue(RichNode self, VM vm, nativeint& result) {
    return raiseTypeError(vm, MOZART_STR("Integer"), self);
  }

  void equalsInteger(RichNode self, VM vm, nativeint right, bool& result) {
    result = false;
  }

  void addValue(RichNode self, VM vm, nativeint b, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Integer"), self);
  }
};

class FloatValue;
template<>
struct Interface<FloatValue>: ImplementedBy<Float> {
  void floatValue(RichNode self, VM vm, double& result) {
    return raiseTypeError(vm, MOZART_STR("Float"), self);
  }

  void equalsFloat(RichNode self, VM vm, double right, bool& result) {
    result = false;
  }

  void addValue(RichNode self, VM vm, double b, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Float"), self);
  }
};

class BooleanValue;
template<>
struct Interface<BooleanValue>: ImplementedBy<Boolean> {
  void boolValue(RichNode self, VM vm, bool& result) {
    return raiseTypeError(vm, MOZART_STR("Boolean"), self);
  }

  void valueOrNotBool(RichNode self, VM vm, BoolOrNotBool& result) {
    result = bNotBool;
  }
};

class BaseDottable;
template<>
struct Interface<BaseDottable>:
  ImplementedBy<Tuple, Record, Object, Chunk, Cons, Array, Dictionary,
    Atom, OptName, GlobalName, Boolean, Unit> {

  void lookupFeature(RichNode self, VM vm, RichNode feature,
                     bool& found, nullable<UnstableNode&> value) {
    return raiseTypeError(vm, MOZART_STR("Record or Chunk"), self);
  }

  void lookupFeature(RichNode self, VM vm, nativeint feature,
                     bool& found, nullable<UnstableNode&> value) {
    return raiseTypeError(vm, MOZART_STR("Record or Chunk"), self);
  }
};

class DotAssignable;
template<>
struct Interface<DotAssignable>:
  ImplementedBy<Array, Dictionary> {

  void dotAssign(RichNode self, VM vm, RichNode feature, RichNode newValue) {
    return raiseTypeError(vm, MOZART_STR("Array or Dictionary"), self);
  }

  void dotExchange(RichNode self, VM vm, RichNode feature,
                   RichNode newValue, UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("Array or Dictionary"), self);
  }
};

class RecordLike;
template<>
struct Interface<RecordLike>:
  ImplementedBy<Tuple, Record, Cons,
    Atom, OptName, GlobalName, Boolean, Unit> {

  void isRecord(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void isTuple(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void label(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  void width(RichNode self, VM vm, size_t& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  void arityList(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  void clone(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  void waitOr(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  void testRecord(RichNode self, VM vm, RichNode arity, bool& result) {
    result = false;
  }

  void testTuple(RichNode self, VM vm, RichNode label, size_t width,
                 bool& result) {
    result = false;
  }

  void testLabel(RichNode self, VM vm, RichNode label, bool& result) {
    result = false;
  }
};

class ArrayLike;
template <>
struct Interface<ArrayLike>: ImplementedBy<Array> {

  void isArray(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void arrayLow(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }

  void arrayHigh(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }

  void arrayGet(RichNode self, VM vm, RichNode index, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }

  void arrayPut(RichNode self, VM vm, RichNode index, RichNode value) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }

  void arrayExchange(RichNode self, VM vm, RichNode index,
                     RichNode newValue, UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("array"), self);
  }
};

class DictionaryLike;
template <>
struct Interface<DictionaryLike>: ImplementedBy<Dictionary> {

  void isDictionary(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void dictIsEmpty(RichNode self, VM vm, bool& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictMember(RichNode self, VM vm, RichNode feature, bool& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictGet(RichNode self, VM vm, RichNode feature, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictCondGet(RichNode self, VM vm, RichNode feature,
                   RichNode defaultValue, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictPut(RichNode self, VM vm, RichNode feature, RichNode newValue) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictExchange(RichNode self, VM vm, RichNode feature,
                    RichNode newValue, UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictCondExchange(RichNode self, VM vm, RichNode feature,
                        RichNode defaultValue,
                        RichNode newValue, UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictRemove(RichNode self, VM vm, RichNode feature) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictRemoveAll(RichNode self, VM vm) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictKeys(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictEntries(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictItems(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictClone(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }
};

class ObjectLike;
template <>
struct Interface<ObjectLike>: ImplementedBy<Object> {
  void isObject(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void getClass(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("object"), self);
  }

  void attrGet(RichNode self, VM vm, RichNode attribute, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("object"), self);
  }

  void attrPut(RichNode self, VM vm, RichNode attribute, RichNode value) {
    return raiseTypeError(vm, MOZART_STR("object"), self);
  }

  void attrExchange(RichNode self, VM vm, RichNode attribute,
                    RichNode newValue, UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("object"), self);
  }
};

class ArrayInitializer;
template<>
struct Interface<ArrayInitializer>:
  ImplementedBy<Tuple, Record, Abstraction, CodeArea, PatMatOpenRecord> {

  void initElement(RichNode self, VM vm, size_t index, RichNode value) {
    return raiseTypeError(vm, MOZART_STR("Array initializer"), self);
  }
};

class SpaceLike;
template<>
struct Interface<SpaceLike>: ImplementedBy<ReifiedSpace, DeletedSpace> {
  void isSpace(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void askSpace(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  void askVerboseSpace(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  void mergeSpace(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  void commitSpace(RichNode self, VM vm, RichNode value) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  void cloneSpace(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  void killSpace(RichNode self, VM vm) {
    return raiseTypeError(vm, MOZART_STR("Space"), self);
  }
};

class ThreadLike;
template<>
struct Interface<ThreadLike>: ImplementedBy<ReifiedThread> {
  void isThread(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void getThreadPriority(RichNode self, VM vm, ThreadPriority& result) {
    return raiseTypeError(vm, MOZART_STR("Thread"), self);
  }

  void setThreadPriority(RichNode self, VM vm, ThreadPriority priority) {
    return raiseTypeError(vm, MOZART_STR("Thread"), self);
  }

  void injectException(RichNode self, VM vm, RichNode exception) {
    return raiseTypeError(vm, MOZART_STR("Thread"), self);
  }
};

class CellLike;
template<>
struct Interface<CellLike>: ImplementedBy<Cell> {
  void isCell(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void exchange(RichNode self, VM vm, RichNode newValue,
                UnstableNode& oldValue) {
    return raiseTypeError(vm, MOZART_STR("Cell"), self);
  }

  void access(RichNode self, VM vm, UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("Cell"), self);
  }

  void assign(RichNode self, VM vm, RichNode newValue) {
    return raiseTypeError(vm, MOZART_STR("Cell"), self);
  }
};

class ChunkLike;
template<>
struct Interface<ChunkLike>: ImplementedBy<Chunk, Object> {
  void isChunk(RichNode self, VM vm, bool& result) {
    result = false;
  }
};

class StringLike;
template<>
struct Interface<StringLike>: ImplementedBy<String, ByteString> {
  void isString(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void isByteString(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void stringGet(RichNode self, VM vm, LString<nchar>*& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  void stringGet(RichNode self, VM vm, LString<unsigned char>*& result) {
    return raiseTypeError(vm, MOZART_STR("ByteString"), self);
  }

  void stringCharAt(RichNode self, VM vm, RichNode offset,
                    nativeint& character) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  void stringAppend(RichNode self, VM vm, RichNode right,
                    UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  void stringSlice(RichNode self, VM vm, RichNode from, RichNode to,
                   UnstableNode& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  void stringSearch(RichNode self, VM vm, RichNode from, RichNode needle,
                    UnstableNode& begin, UnstableNode& end) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  void stringHasPrefix(RichNode self, VM vm, RichNode prefix, bool& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }

  void stringHasSuffix(RichNode self, VM vm, RichNode suffix, bool& result) {
    return raiseTypeError(vm, MOZART_STR("String"), self);
  }
};

class VirtualString;
template<>
struct Interface<VirtualString>:
  ImplementedBy<SmallInt, Float, Atom, Boolean, String, Unit, Cons, Tuple,
                ByteString> {

  void isVirtualString(RichNode self, VM vm, bool& result) {
    result = false;
  }

  void toString(RichNode self, VM vm, std::basic_ostream<nchar>& sink) {
    return raiseTypeError(vm, MOZART_STR("VirtualString"), self);
  }

  void vsLength(RichNode self, VM vm, nativeint& result) {
    return raiseTypeError(vm, MOZART_STR("VirtualString"), self);
  }
};

}

#endif // __COREINTERFACES_DECL_H
