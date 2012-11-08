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
  ImplementedBy<OptVar, Variable, ReadOnly, ReadOnlyVariable, FailedValue,
                ReflectiveVariable>,
  NoAutoWait, NoAutoReflectiveCalls {

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

class BindableReadOnly;
template<>
struct Interface<BindableReadOnly>:
  ImplementedBy<ReadOnlyVariable>, NoAutoWait, NoAutoReflectiveCalls {

  void bindReadOnly(RichNode self, VM vm, RichNode src) {
    raiseTypeError(vm, MOZART_STR("ReadOnlyVariable"), self);
  }
};

class ValueEquatable;
template<>
struct Interface<ValueEquatable>:
  ImplementedBy<SmallInt, Atom, Boolean, Float, BuiltinProcedure,
                ReifiedThread, Unit, String, ByteString, UniqueName,
                PatMatCapture>,
  NoAutoReflectiveCalls {

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
  ImplementedBy<Tuple, Cons, Record, Arity>,
  NoAutoReflectiveCalls {

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

  int compare(RichNode self, VM vm, RichNode right) {
    raiseTypeError(vm, MOZART_STR("comparable"), self);
  }
};

class Wakeable;
template<>
struct Interface<Wakeable>:
  ImplementedBy<ReifiedThread, Variable, ReadOnly>, NoAutoWait,
  NoAutoReflectiveCalls {

  void wakeUp(RichNode self, VM vm) {
  }

  bool shouldWakeUpUnderSpace(RichNode self, VM vm, Space* space) {
    return false;
  }
};

class Literal;
template<>
struct Interface<Literal>:
  ImplementedBy<Atom, OptName, GlobalName, Boolean, Unit>,
  NoAutoReflectiveCalls {

  bool isLiteral(RichNode self, VM vm) {
    return false;
  }
};

class NameLike;
template<>
struct Interface<NameLike>:
  ImplementedBy<OptName, GlobalName>,
  NoAutoReflectiveCalls {

  bool isName(RichNode self, VM vm) {
    return false;
  }
};

class AtomLike;
template<>
struct Interface<AtomLike>:
  ImplementedBy<Atom>, NoAutoReflectiveCalls {

  bool isAtom(RichNode self, VM vm) {
    return false;
  }
};

class PotentialFeature;
template<>
struct Interface<PotentialFeature>:
  ImplementedBy<OptName>, NoAutoReflectiveCalls {

  void makeFeature(RichNode self, VM vm) {
    if (!self.isFeature())
      raiseTypeError(vm, MOZART_STR("feature"), self);
  }
};

class BuiltinCallable;
template<>
struct Interface<BuiltinCallable>:
  ImplementedBy<BuiltinProcedure>, NoAutoReflectiveCalls {

  bool isBuiltin(RichNode self, VM vm) {
    return false;
  }

  void callBuiltin(RichNode self, VM vm, size_t argc,
                   UnstableNode* args[]) {
    raiseTypeError(vm, MOZART_STR("BuiltinProcedure"), self);
  }

  template <class... Args>
  void callBuiltin(RichNode self, VM vm, Args&&... args) {
    raiseTypeError(vm, MOZART_STR("BuiltinProcedure"), self);
  }

  builtins::BaseBuiltin* getBuiltin(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("BuiltinProcedure"), self);
  }
};

class Callable;
template<>
struct Interface<Callable>:
  ImplementedBy<Abstraction, Object, BuiltinProcedure>,
  NoAutoReflectiveCalls {

  bool isCallable(RichNode self, VM vm) {
    return false;
  }

  bool isProcedure(RichNode self, VM vm) {
    return false;
  }

  size_t procedureArity(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Abstraction"), self);
  }

  void getCallInfo(RichNode self, VM vm, size_t& arity,
                   ProgramCounter& start, size_t& Xcount,
                   StaticArray<StableNode>& Gs,
                   StaticArray<StableNode>& Ks) {
    raiseTypeError(vm, MOZART_STR("Abstraction"), self);
  }

  void getDebugInfo(RichNode self, VM vm,
                    atom_t& printName, UnstableNode& debugData) {
    raiseTypeError(vm, MOZART_STR("Abstraction"), self);
  }
};

class CodeAreaProvider;
template<>
struct Interface<CodeAreaProvider>:
  ImplementedBy<CodeArea>, NoAutoReflectiveCalls {

  bool isCodeAreaProvider(RichNode self, VM vm) {
    return false;
  }

  void getCodeAreaInfo(RichNode self, VM vm, size_t& arity,
                       ProgramCounter& start, size_t& Xcount,
                       StaticArray<StableNode>& Ks) {
    raiseTypeError(vm, MOZART_STR("CodeArea"), self);
  }

  void getCodeAreaDebugInfo(RichNode self, VM vm,
                            atom_t& printName, UnstableNode& debugData) {
    raiseTypeError(vm, MOZART_STR("CodeArea"), self);
  }
};

class Numeric;
template<>
struct Interface<Numeric>:
  ImplementedBy<SmallInt, Float>, NoAutoReflectiveCalls {

  bool isNumber(RichNode self, VM vm) {
    return false;
  }

  bool isInt(RichNode self, VM vm) {
    return false;
  }

  bool isFloat(RichNode self, VM vm) {
    return false;
  }

  UnstableNode opposite(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  UnstableNode add(RichNode self, VM vm, RichNode right) {
    raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  UnstableNode subtract(RichNode self, VM vm, RichNode right) {
    raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  UnstableNode multiply(RichNode self, VM vm, RichNode right) {
    raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  UnstableNode divide(RichNode self, VM vm, RichNode right) {
    raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  UnstableNode div(RichNode self, VM vm, RichNode right) {
    raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }

  UnstableNode mod(RichNode self, VM vm, RichNode right) {
    raiseTypeError(vm, MOZART_STR("Numeric"), self);
  }
};

class IntegerValue;
template<>
struct Interface<IntegerValue>:
  ImplementedBy<SmallInt>, NoAutoReflectiveCalls {

  nativeint intValue(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Integer"), self);
  }

  bool equalsInteger(RichNode self, VM vm, nativeint right) {
    return false;
  }

  UnstableNode addValue(RichNode self, VM vm, nativeint b) {
    raiseTypeError(vm, MOZART_STR("Integer"), self);
  }
};

class FloatValue;
template<>
struct Interface<FloatValue>:
  ImplementedBy<Float>, NoAutoReflectiveCalls {

  double floatValue(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Float"), self);
  }

  bool equalsFloat(RichNode self, VM vm, double right) {
    return false;
  }

  UnstableNode addValue(RichNode self, VM vm, double b) {
    raiseTypeError(vm, MOZART_STR("Float"), self);
  }
};

class BooleanValue;
template<>
struct Interface<BooleanValue>:
  ImplementedBy<Boolean>, NoAutoReflectiveCalls {

  bool boolValue(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Boolean"), self);
  }

  BoolOrNotBool valueOrNotBool(RichNode self, VM vm) {
    return bNotBool;
  }
};

class BaseDottable;
template<>
struct Interface<BaseDottable>:
  ImplementedBy<Tuple, Record, Object, Chunk, Cons, Array, Dictionary,
    Atom, OptName, GlobalName, Boolean, Unit>,
  NoAutoReflectiveCalls {

  bool lookupFeature(RichNode self, VM vm, RichNode feature,
                     nullable<UnstableNode&> value) {
    raiseTypeError(vm, MOZART_STR("Record or Chunk"), self);
  }

  bool lookupFeature(RichNode self, VM vm, nativeint feature,
                     nullable<UnstableNode&> value) {
    raiseTypeError(vm, MOZART_STR("Record or Chunk"), self);
  }
};

class DotAssignable;
template<>
struct Interface<DotAssignable>:
  ImplementedBy<Array, Dictionary> {

  void dotAssign(RichNode self, VM vm, RichNode feature, RichNode newValue) {
    raiseTypeError(vm, MOZART_STR("Array or Dictionary"), self);
  }

  UnstableNode dotExchange(RichNode self, VM vm, RichNode feature,
                           RichNode newValue) {
    raiseTypeError(vm, MOZART_STR("Array or Dictionary"), self);
  }
};

class RecordLike;
template<>
struct Interface<RecordLike>:
  ImplementedBy<Tuple, Record, Cons,
    Atom, OptName, GlobalName, Boolean, Unit>,
  NoAutoReflectiveCalls {

  bool isRecord(RichNode self, VM vm) {
    return false;
  }

  bool isTuple(RichNode self, VM vm) {
    return false;
  }

  UnstableNode label(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  size_t width(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  UnstableNode arityList(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  UnstableNode clone(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  UnstableNode waitOr(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Record"), self);
  }

  bool testRecord(RichNode self, VM vm, RichNode arity) {
    return false;
  }

  bool testTuple(RichNode self, VM vm, RichNode label, size_t width) {
    return false;
  }

  bool testLabel(RichNode self, VM vm, RichNode label) {
    return false;
  }
};

class PortLike;
template<>
struct Interface<PortLike>: ImplementedBy<Port> {
  bool isPort(RichNode self, VM vm) {
    return false;
  }

  void send(RichNode self, VM vm, RichNode value) {
    raiseTypeError(vm, MOZART_STR("Port"), self);
  }

  UnstableNode sendReceive(RichNode self, VM vm, RichNode value) {
    raiseTypeError(vm, MOZART_STR("Port"), self);
  }
};

class ArrayLike;
template <>
struct Interface<ArrayLike>: ImplementedBy<Array> {

  bool isArray(RichNode self, VM vm) {
    return false;
  }

  UnstableNode arrayLow(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("array"), self);
  }

  UnstableNode arrayHigh(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("array"), self);
  }

  UnstableNode arrayGet(RichNode self, VM vm, RichNode index) {
    raiseTypeError(vm, MOZART_STR("array"), self);
  }

  void arrayPut(RichNode self, VM vm, RichNode index, RichNode value) {
    raiseTypeError(vm, MOZART_STR("array"), self);
  }

  UnstableNode arrayExchange(RichNode self, VM vm, RichNode index,
                             RichNode newValue) {
    raiseTypeError(vm, MOZART_STR("array"), self);
  }
};

class DictionaryLike;
template <>
struct Interface<DictionaryLike>: ImplementedBy<Dictionary> {

  bool isDictionary(RichNode self, VM vm) {
    return false;
  }

  bool dictIsEmpty(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  bool dictMember(RichNode self, VM vm, RichNode feature) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  UnstableNode dictGet(RichNode self, VM vm, RichNode feature) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  UnstableNode dictCondGet(RichNode self, VM vm, RichNode feature,
                           RichNode defaultValue) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictPut(RichNode self, VM vm, RichNode feature, RichNode newValue) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  UnstableNode dictExchange(RichNode self, VM vm, RichNode feature,
                            RichNode newValue) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  UnstableNode dictCondExchange(RichNode self, VM vm, RichNode feature,
                                RichNode defaultValue, RichNode newValue) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictRemove(RichNode self, VM vm, RichNode feature) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  void dictRemoveAll(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  UnstableNode dictKeys(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  UnstableNode dictEntries(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  UnstableNode dictItems(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }

  UnstableNode dictClone(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("dictionary"), self);
  }
};

class ObjectLike;
template <>
struct Interface<ObjectLike>: ImplementedBy<Object> {
  bool isObject(RichNode self, VM vm) {
    return false;
  }

  UnstableNode getClass(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("object"), self);
  }

  UnstableNode attrGet(RichNode self, VM vm, RichNode attribute) {
    raiseTypeError(vm, MOZART_STR("object"), self);
  }

  void attrPut(RichNode self, VM vm, RichNode attribute, RichNode value) {
    raiseTypeError(vm, MOZART_STR("object"), self);
  }

  UnstableNode attrExchange(RichNode self, VM vm, RichNode attribute,
                            RichNode newValue) {
    raiseTypeError(vm, MOZART_STR("object"), self);
  }
};

class ArrayInitializer;
template<>
struct Interface<ArrayInitializer>:
  ImplementedBy<Tuple, Record, Abstraction, CodeArea, PatMatOpenRecord>,
  NoAutoReflectiveCalls {

  void initElement(RichNode self, VM vm, size_t index, RichNode value) {
    raiseTypeError(vm, MOZART_STR("Array initializer"), self);
  }
};

class SpaceLike;
template<>
struct Interface<SpaceLike>:
  ImplementedBy<ReifiedSpace, DeletedSpace>,
  NoAutoReflectiveCalls {

  bool isSpace(RichNode self, VM vm) {
    return false;
  }

  UnstableNode askSpace(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  UnstableNode askVerboseSpace(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  UnstableNode mergeSpace(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  void commitSpace(RichNode self, VM vm, RichNode value) {
    raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  UnstableNode cloneSpace(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Space"), self);
  }

  void killSpace(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Space"), self);
  }
};

class ThreadLike;
template<>
struct Interface<ThreadLike>:
  ImplementedBy<ReifiedThread>,
  NoAutoReflectiveCalls {

  bool isThread(RichNode self, VM vm) {
    return false;
  }

  ThreadPriority getThreadPriority(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Thread"), self);
  }

  void setThreadPriority(RichNode self, VM vm, ThreadPriority priority) {
    raiseTypeError(vm, MOZART_STR("Thread"), self);
  }

  void injectException(RichNode self, VM vm, RichNode exception) {
    raiseTypeError(vm, MOZART_STR("Thread"), self);
  }
};

class CellLike;
template<>
struct Interface<CellLike>: ImplementedBy<Cell> {
  bool isCell(RichNode self, VM vm) {
    return false;
  }

  UnstableNode exchange(RichNode self, VM vm, RichNode newValue) {
    raiseTypeError(vm, MOZART_STR("Cell"), self);
  }

  UnstableNode access(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("Cell"), self);
  }

  void assign(RichNode self, VM vm, RichNode newValue) {
    raiseTypeError(vm, MOZART_STR("Cell"), self);
  }
};

class ChunkLike;
template<>
struct Interface<ChunkLike>: ImplementedBy<Chunk, Object> {
  bool isChunk(RichNode self, VM vm) {
    return false;
  }
};

class StringLike;
template<>
struct Interface<StringLike>:
  ImplementedBy<String, ByteString>,
  NoAutoReflectiveCalls {

  bool isString(RichNode self, VM vm) {
    return false;
  }

  bool isByteString(RichNode self, VM vm) {
    return false;
  }

  LString<nchar>* stringGet(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("String"), self);
  }

  LString<unsigned char>* byteStringGet(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("ByteString"), self);
  }

  nativeint stringCharAt(RichNode self, VM vm, RichNode offset) {
    raiseTypeError(vm, MOZART_STR("String"), self);
  }

  UnstableNode stringAppend(RichNode self, VM vm, RichNode right) {
    raiseTypeError(vm, MOZART_STR("String"), self);
  }

  UnstableNode stringSlice(RichNode self, VM vm, RichNode from, RichNode to) {
    raiseTypeError(vm, MOZART_STR("String"), self);
  }

  void stringSearch(RichNode self, VM vm, RichNode from, RichNode needle,
                    UnstableNode& begin, UnstableNode& end) {
    raiseTypeError(vm, MOZART_STR("String"), self);
  }

  bool stringHasPrefix(RichNode self, VM vm, RichNode prefix) {
    raiseTypeError(vm, MOZART_STR("String"), self);
  }

  bool stringHasSuffix(RichNode self, VM vm, RichNode suffix) {
    raiseTypeError(vm, MOZART_STR("String"), self);
  }
};

class VirtualString;
template<>
struct Interface<VirtualString>:
  ImplementedBy<SmallInt, Float, Atom, Boolean, String, Unit, Cons, Tuple,
                ByteString>,
  NoAutoReflectiveCalls {

  bool isVirtualString(RichNode self, VM vm) {
    return false;
  }

  void toString(RichNode self, VM vm, std::basic_ostream<nchar>& sink) {
    raiseTypeError(vm, MOZART_STR("VirtualString"), self);
  }

  nativeint vsLength(RichNode self, VM vm) {
    raiseTypeError(vm, MOZART_STR("VirtualString"), self);
  }
};

}

#endif // __COREINTERFACES_DECL_H
