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

#ifndef __MODCOMPILERSUPPORT_H
#define __MODCOMPILERSUPPORT_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

////////////////////////////
// CompilerSupport module //
////////////////////////////

class ModCompilerSupport: public Module {
public:
  ModCompilerSupport(): Module("CompilerSupport") {}

  class FeatureLess: public Builtin<FeatureLess> {
  public:
    FeatureLess(): Builtin("featureLess") {}

    static void call(VM vm, In lhs, In rhs, Out result) {
      requireFeature(vm, lhs);
      requireFeature(vm, rhs);

      result = build(vm, compareFeatures(vm, lhs, rhs) < 0);
    }
  };

  class NewCodeArea: public Builtin<NewCodeArea> {
  public:
    NewCodeArea(): Builtin("newCodeArea") {}

    static void call(VM vm, In byteCodeList, In arity, In XCount, In KsList,
                     In printName, In debugData, Out result) {
      // Read byte code
      std::vector<ByteCode> byteCode;

      ozListForEach(vm, byteCodeList,
        [&] (nativeint elem) {
          if ((elem < std::numeric_limits<ByteCode>::min()) ||
              (elem > std::numeric_limits<ByteCode>::max())) {
            raiseTypeError(vm, MOZART_STR("Byte code element"), elem);
          } else {
            byteCode.push_back((ByteCode) elem);
          }
        },
        MOZART_STR("List of byte code elements")
      );

      // Read scalar args
      auto intArity = getArgument<nativeint>(vm, arity);
      auto intXCount = getArgument<nativeint>(vm, XCount);
      auto atomPrintName = getArgument<atom_t>(vm, printName);

      // Read number of K registers
      size_t KCount = ozListLength(vm, KsList);

      // Create the code area
      result = CodeArea::build(vm, KCount, &byteCode.front(),
                               byteCode.size() * sizeof(ByteCode),
                               intArity, intXCount, atomPrintName, debugData);

      // Fill the K registers
      auto kregs = RichNode(result).as<CodeArea>().getElementsArray();
      ozListForEach(vm, KsList,
        [&] (RichNode elem, size_t index) {
          kregs[index].init(vm, elem);
        },
        MOZART_STR("list")
      );
    }
  };

  class NewAbstraction: public Builtin<NewAbstraction> {
  public:
    NewAbstraction(): Builtin("newAbstraction") {}

    static void call(VM vm, In body, In GsList, Out result) {
      // Check the type of the code area
      if (!CodeAreaProvider(body).isCodeAreaProvider(vm))
        raiseTypeError(vm, MOZART_STR("Code area"), body);

      // Read number of G registers
      size_t GCount = ozListLength(vm, GsList);

      // Create the abstraction
      result = Abstraction::build(vm, GCount, body);

      // Fill the G registers
      auto gregs = RichNode(result).as<Abstraction>().getElementsArray();
      ozListForEach(vm, GsList,
        [&] (RichNode elem, size_t index) {
          gregs[index].init(vm, elem);
        },
        MOZART_STR("list")
      );
    }
  };

  class SetUUID: public Builtin<SetUUID> {
  public:
    SetUUID(): Builtin("setUUID") {}

    static void call(VM vm, In value, In uuid) {
      auto uuidValue = getArgument<UUID>(vm, uuid);

      if (value.is<CodeArea>()) {
        value.as<CodeArea>().setUUID(vm, uuidValue);
      } else if (value.is<Abstraction>()) {
        value.as<Abstraction>().setUUID(vm, uuidValue);
      } else if (value.isTransient()) {
        waitFor(vm, value);
      } else {
        raiseTypeError(vm, MOZART_STR("Codea area or abstraction"), value);
      }
    }
  };

  class MakeArityDynamic: public Builtin<MakeArityDynamic> {
  public:
    MakeArityDynamic(): Builtin("makeArityDynamic") {}

    static void call(VM vm, In label, In features, Out result) {
      using namespace patternmatching;

      size_t width = 0;
      StaticArray<StableNode> featuresData;

      if (matchesVariadicSharp(vm, features, width, featuresData)) {
        auto unstableFeatures = vm->newStaticArray<UnstableNode>(width);
        for (size_t i = 0; i < width; i++)
          unstableFeatures[i].init(vm, featuresData[i]);

        auto arity = buildArityDynamic(vm, label, width,
                                       (UnstableNode*) unstableFeatures);

        if (RichNode(arity).is<Unit>())
          result = build(vm, false);
        else
          result = std::move(arity);

        vm->deleteStaticArray(unstableFeatures, width);
      } else {
        raiseTypeError(vm, MOZART_STR("#-tuple"), features);
      }
    }
  };

  class NewPatPatWildcard: public Builtin<NewPatPatWildcard> {
  public:
    NewPatPatWildcard(): Builtin("newPatMatWildcard") {}

    static void call(VM vm, Out result) {
      result = PatMatCapture::build(vm, -1);
    }
  };

  class NewPatPatCapture: public Builtin<NewPatPatCapture> {
  public:
    NewPatPatCapture(): Builtin("newPatMatCapture") {}

    static void call(VM vm, In index, Out result) {
      auto intIndex = getArgument<nativeint>(vm, index, MOZART_STR("Integer"));
      result = PatMatCapture::build(vm, intIndex);
    }
  };

  class IsBuiltin: public Builtin<IsBuiltin> {
  public:
    IsBuiltin(): Builtin("isBuiltin") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, BuiltinCallable(value).isBuiltin(vm));
    }
  };

  class GetBuiltinInfo: public Builtin<GetBuiltinInfo> {
  public:
    GetBuiltinInfo(): Builtin("getBuiltinInfo") {}

    static void call(VM vm, In value, Out result) {
      BaseBuiltin* builtin = BuiltinCallable(value).getBuiltin(vm);

      UnstableNode name = build(vm, builtin->getNameAtom(vm));
      UnstableNode arity = build(vm, builtin->getArity());

      UnstableNode params = build(vm, vm->coreatoms.nil);
      for (size_t i = builtin->getArity(); i > 0; i--) {
        auto& paramInfo = builtin->getParams(i-1);
        UnstableNode param = buildRecord(
          vm, buildArity(vm, MOZART_STR("param"), MOZART_STR("kind")),
          paramInfo.kind == ParamInfo::Kind::pkIn ?
            MOZART_STR("in") : MOZART_STR("out"));
        params = buildCons(vm, std::move(param), std::move(params));
      }

      UnstableNode inlineAs;
      if (builtin->getInlineAs() < 0)
        inlineAs = build(vm, MOZART_STR("none"));
      else
        inlineAs = buildTuple(vm, MOZART_STR("some"), builtin->getInlineAs());

      result = buildRecord(
        vm, buildArity(vm,
                       MOZART_STR("builtin"),
                       MOZART_STR("arity"),
                       MOZART_STR("inlineAs"),
                       MOZART_STR("name"),
                       MOZART_STR("params")),
        std::move(arity), std::move(inlineAs), std::move(name),
        std::move(params));
    }
  };

  class IsUniqueName: public Builtin<IsUniqueName> {
  public:
    IsUniqueName(): Builtin("isUniqueName") {}

    static void call(VM vm, In value, Out result) {
      if (value.isTransient())
        waitFor(vm, value);

      result = build(vm, value.is<UniqueName>());
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODCOMPILERSUPPORT_H
