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

    void operator()(VM vm, In lhs, In rhs, Out result) {
      requireFeature(vm, lhs);
      requireFeature(vm, rhs);

      result = build(vm, compareFeatures(vm, lhs, rhs) < 0);
    }
  };

  class NewCodeArea: public Builtin<NewCodeArea> {
  public:
    NewCodeArea(): Builtin("newCodeArea") {}

    void operator()(VM vm, In byteCodeList, In arity, In XCount, In KsList,
                    In printName, In debugData, Out result) {
      // Read byte code
      std::vector<ByteCode> byteCode;

      ozListForEach(vm, byteCodeList,
        [&] (nativeint elem) {
          if ((elem < std::numeric_limits<ByteCode>::min()) ||
              (elem > std::numeric_limits<ByteCode>::max())) {
            return raiseTypeError(vm, MOZART_STR("Byte code element"),
                                  build(vm, elem));
          } else {
            byteCode.push_back((ByteCode) elem);
          }
        },
        MOZART_STR("List of byte code elements")
      );

      // Read scalar args
      nativeint intArity = 0, intXCount = 0;
      atom_t atomPrintName;
      getArgument(vm, intArity, arity, MOZART_STR("positive integer"));
      getArgument(vm, intXCount, XCount, MOZART_STR("positive integer"));
      getArgument(vm, atomPrintName, printName, MOZART_STR("Atom"));

      // Read number of K registers
      size_t KCount = 0;
      ozListLength(vm, KsList, KCount);

      // Create the code area
      result = CodeArea::build(vm, KCount, &byteCode.front(),
                               byteCode.size() * sizeof(ByteCode),
                               intArity, intXCount, atomPrintName, debugData);

      // Fill the K registers
      ArrayInitializer KInitializer = result;
      size_t index = 0;

      ozListForEach(vm, KsList,
        [&] (UnstableNode& elem) {
          KInitializer.initElement(vm, index, elem);
          index++;
        },
        MOZART_STR("list")
      );
    }
  };

  class NewAbstraction: public Builtin<NewAbstraction> {
  public:
    NewAbstraction(): Builtin("newAbstraction") {}

    void operator()(VM vm, In body, In GsList, Out result) {
      // Check the type of the code area
      bool bodyIsCodeArea = false;
      CodeAreaProvider(body).isCodeAreaProvider(vm, bodyIsCodeArea);
      if (!bodyIsCodeArea) {
        return raiseTypeError(vm, MOZART_STR("Code area"), body);
      }

      // Read number of G registers
      size_t GCount = 0;
      ozListLength(vm, GsList, GCount);

      // Create the abstraction
      result = Abstraction::build(vm, GCount, body);

      // Fill the G registers
      ArrayInitializer GInitializer = result;
      size_t index = 0;

      ozListForEach(vm, GsList,
        [&] (UnstableNode& elem) {
          GInitializer.initElement(vm, index, elem);
          index++;
        },
        MOZART_STR("list")
      );
    }
  };

  class MakeArityDynamic: public Builtin<MakeArityDynamic> {
  public:
    MakeArityDynamic(): Builtin("makeArityDynamic") {}

    void operator()(VM vm, In label, In features, Out result) {
      using namespace patternmatching;

      size_t width = 0;
      StaticArray<StableNode> featuresData;

      if (matchesVariadicSharp(vm, features, width, featuresData)) {
        auto unstableFeatures = vm->newStaticArray<UnstableNode>(width);
        for (size_t i = 0; i < width; i++)
          unstableFeatures[i].init(vm, featuresData[i]);

        bool isTuple = false;
        UnstableNode arity;
        buildArityDynamic(vm, isTuple, arity, label, width,
                          (UnstableNode*) unstableFeatures);

        if (isTuple)
          result = build(vm, false);
        else
          result = std::move(arity);

        vm->deleteStaticArray(unstableFeatures, width);
      } else {
        return raiseTypeError(vm, MOZART_STR("#-tuple"), features);
      }
    }
  };

  class NewPatPatWildcard: public Builtin<NewPatPatWildcard> {
  public:
    NewPatPatWildcard(): Builtin("newPatMatWildcard") {}

    void operator()(VM vm, Out result) {
      result = PatMatCapture::build(vm, -1);
    }
  };

  class NewPatPatCapture: public Builtin<NewPatPatCapture> {
  public:
    NewPatPatCapture(): Builtin("newPatMatCapture") {}

    void operator()(VM vm, In index, Out result) {
      nativeint intIndex;
      getArgument(vm, intIndex, index, MOZART_STR("Integer"));

      result = PatMatCapture::build(vm, intIndex);
    }
  };

  class IsBuiltin: public Builtin<IsBuiltin> {
  public:
    IsBuiltin(): Builtin("isBuiltin") {}

    void operator()(VM vm, In value, Out result) {
      bool boolResult = false;
      BuiltinCallable(value).isBuiltin(vm, boolResult);

      result = Boolean::build(vm, boolResult);
    }
  };

  class GetBuiltinInfo: public Builtin<GetBuiltinInfo> {
  public:
    GetBuiltinInfo(): Builtin("getBuiltinInfo") {}

    void operator()(VM vm, In value, Out result) {
      BaseBuiltin* builtin = nullptr;
      BuiltinCallable(value).getBuiltin(vm, builtin);

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

    void operator()(VM vm, In value, Out result) {
      if (value.isTransient())
        return waitFor(vm, value);

      result = build(vm, value.is<UniqueName>());
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODCOMPILERSUPPORT_H
