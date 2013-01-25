// Copyright © 2013, Université catholique de Louvain
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

#ifndef __MODBROWSER_H
#define __MODBROWSER_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

////////////////////
// Browser module //
////////////////////

class ModBrowser: public Module {
public:
  ModBrowser(): Module("Browser") {}

  class IsRecordCVar: public Builtin<IsRecordCVar> {
  public:
    IsRecordCVar(): Builtin("isRecordCVar") {}

    static void call(VM vm, In value, Out result) {
      // TODO Update this when we have kinded variables
      result = build(vm, !value.isTransient() && RecordLike(value).isRecord(vm));
    }
  };

  class ChunkWidth: public Builtin<ChunkWidth> {
  public:
    ChunkWidth(): Builtin("chunkWidth") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, RecordLike(getChunkUnderlying(vm, value)).width(vm));
    }
  };

  class ChunkArity: public Builtin<ChunkArity> {
  public:
    ChunkArity(): Builtin("chunkArity") {}

    static void call(VM vm, In value, Out result) {
      result = RecordLike(getChunkUnderlying(vm, value)).arityList(vm);
    }
  };

private:
  static StableNode& getChunkUnderlying(VM vm, In value) {
      if (value.is<Chunk>())
        return *value.as<Chunk>().getUnderlying();
      else if (value.is<Object>())
        return *value.as<Object>().getFeaturesRecord();
      else if (value.isTransient())
        waitFor(vm, value);
      else
        raiseTypeError(vm, MOZART_STR("Chunk"), value);
  }

public:

  class ShortName: public Builtin<ShortName> {
  public:
    ShortName(): Builtin("shortName") {}

    static void call(VM vm, In longName, Out result) {
      // Keep it for compatibility, but this is nonsense
      ozVSLengthForBuffer(vm, longName); // for the type error
      result = build(vm, longName);
    }
  };

  class GetsBoundB: public Builtin<GetsBoundB> {
  public:
    GetsBoundB(): Builtin("getsBoundB") {}

    static void call(VM vm, In variable, Out watcher) {
      watcher = Variable::build(vm);

      if (variable.isTransient() && !variable.is<FailedValue>()) {
        DataflowVariable(variable).addToSuspendList(vm, watcher);
      };
    }
  };

  class VarSpace: public Builtin<VarSpace> {
  public:
    VarSpace(): Builtin("varSpace") {}

    static void call(VM vm, In variable, Out result) {
      Space* space;

      while (variable.is<ReadOnly>())
        variable = *variable.as<ReadOnly>().getUnderlying();

      if (variable.is<OptVar>())
        space = variable.as<OptVar>().home();
      else if (variable.is<Variable>())
        space = variable.as<Variable>().home();
      else if (variable.is<ReadOnlyVariable>())
        space = variable.as<ReadOnlyVariable>().home();
      else
        space = nullptr;

      result = build(vm, (nativeint) space);
    }
  };

  class ProcLoc: public Builtin<ProcLoc> {
  public:
    ProcLoc(): Builtin("procLoc") {}

    static void call(VM vm, In procedure, Out file, Out line, Out column) {
      atom_t printName;
      UnstableNode debugData;
      Callable(procedure).getDebugInfo(vm, printName, debugData);

      Dottable dotDebugData(debugData);
      file = dotDebugData.condSelect(
        vm, MOZART_STR("file"), MOZART_STR("procedure"));
      line = dotDebugData.condSelect(
        vm, MOZART_STR("line"), MOZART_STR("-"));
      column = dotDebugData.condSelect(
        vm, MOZART_STR("column"), MOZART_STR("-"));
    }
  };

  class Addr: public Builtin<Addr> {
  public:
    Addr(): Builtin("addr") {}

    static void call(VM vm, In entity, Out result) {
      result = build(vm, (nativeint) entity.getStableRef(vm));
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODBROWSER_H
