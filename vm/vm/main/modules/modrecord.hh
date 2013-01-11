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

#ifndef __MODRECORD_H
#define __MODRECORD_H

#include "../mozartcore.hh"

#include "modcompilersupport.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////
// Record module //
///////////////////

class ModRecord: public Module {
public:
  ModRecord(): Module("Record") {}

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, RecordLike(value).isRecord(vm));
    }
  };

  class Label: public Builtin<Label> {
  public:
    Label(): Builtin("label") {}

    static void call(VM vm, In record, Out result) {
      result = RecordLike(record).label(vm);
    }
  };

  class Width: public Builtin<Width> {
  public:
    Width(): Builtin("width") {}

    static void call(VM vm, In record, Out result) {
      result = build(vm, RecordLike(record).width(vm));
    }
  };

  class Arity: public Builtin<Arity> {
  public:
    Arity(): Builtin("arity") {}

    static void call(VM vm, In record, Out result) {
      result = RecordLike(record).arityList(vm);
    }
  };

  class Clone: public Builtin<Clone> {
  public:
    Clone(): Builtin("clone") {}

    static void call(VM vm, In record, Out result) {
      result = RecordLike(record).clone(vm);
    }
  };

  class WaitOr: public Builtin<WaitOr> {
  public:
    WaitOr(): Builtin("waitOr") {}

    static void call(VM vm, In record, Out result) {
      result = RecordLike(record).waitOr(vm);
    }
  };

  class MakeDynamic: public Builtin<MakeDynamic> {
  public:
    MakeDynamic(): Builtin("makeDynamic") {}

    static void call(VM vm, In label, In contents, Out result) {
      using namespace patternmatching;

      size_t contentsWidth = 0;
      StaticArray<StableNode> contentsData;

      if (matchesVariadicSharp(vm, contents, contentsWidth,
                               contentsData) && (contentsWidth % 2 == 0)) {
        size_t width = contentsWidth / 2;
        auto elements = vm->newStaticArray<UnstableField>(width);

        for (size_t i = 0; i < width; i++) {
          elements[i].feature.init(vm, contentsData[i*2]);
          elements[i].value.init(vm, contentsData[i*2+1]);
        }

        result = buildRecordDynamic(vm, label, width, elements);

        vm->deleteStaticArray(elements, width);
      } else {
        raiseTypeError(vm, MOZART_STR("#-tuple with even arity"), contents);
      }
    }
  };

  // Pattern matching helpers

  class Test: public Builtin<Test> {
  public:
    Test(): Builtin("test") {}

    static void call(VM vm, In value, In patLabel, In patFeatures, Out result) {
      using namespace patternmatching;

      UnstableNode falseNode(vm, false);
      UnstableNode patArityUnstable;
      ModCompilerSupport::MakeArityDynamic::call(
        vm, patLabel, patFeatures, falseNode, patArityUnstable);
      RichNode patArity = patArityUnstable;

      if (patArity.is<Boolean>()) {
        assert(patArity.as<Boolean>().value() == false);
        size_t patWidth = RecordLike(patFeatures).width(vm);
        result = build(vm, RecordLike(value).testTuple(vm, patLabel, patWidth));
      } else {
        assert(patArity.is<mozart::Arity>());
        result = build(vm, RecordLike(value).testRecord(vm, patArity));
      }
    }
  };

  class TestLabel: public Builtin<TestLabel> {
  public:
    TestLabel(): Builtin("testLabel") {}

    static void call(VM vm, In value, In patLabel, Out result) {
      result = build(vm, RecordLike(value).testLabel(vm, patLabel));
    }
  };

  class TestFeature: public Builtin<TestFeature> {
  public:
    TestFeature(): Builtin("testFeature") {}

    static void call(VM vm, In value, In patFeature,
                     Out found, Out fieldValue) {
      if (Dottable(value).lookupFeature(vm, patFeature, fieldValue)) {
        found = build(vm, true);
      } else {
        found = build(vm, false);
        fieldValue = build(vm, unit);
      }
    }
  };

  // Some operations that can be implemented much more efficiently in C++

  class AdjoinAtIfHasFeature: public Builtin<AdjoinAtIfHasFeature> {
  public:
    AdjoinAtIfHasFeature(): Builtin("adjoinAtIfHasFeature") {}

    static void call(VM vm, In record, In feature, In fieldValue,
                     Out result, Out success) {
      using namespace patternmatching;

      if (!RecordLike(record).isRecord(vm))
        raiseTypeError(vm, MOZART_STR("record"), record);

      if (!Dottable(record).hasFeature(vm, feature)) {
        result = build(vm, unit);
        success = build(vm, false);
        return;
      }

      size_t width, featureIndex;
      StaticArray<StableNode> srcElements, destElements;

      if (record.is<Tuple>()) {
        auto srcTuple = record.as<Tuple>();
        width = srcTuple.getWidth();
        result = Tuple::build(vm, width, *srcTuple.getLabel());
        featureIndex = getArgument<nativeint>(vm, feature) - 1;

        srcElements = srcTuple.getElementsArray();
        destElements = RichNode(result).as<Tuple>().getElementsArray();
      } else if (record.is<Cons>()) {
        auto srcCons = record.as<Cons>();
        width = 2;
        result = Cons::build(vm);
        featureIndex = getArgument<nativeint>(vm, feature) - 1;

        srcElements = srcCons.getElementsArray();
        destElements = RichNode(result).as<Cons>().getElementsArray();
      } else {
        assert(record.is<Record>());

        auto srcRecord = record.as<Record>();
        width = srcRecord.getWidth();
        StableNode& arity = *srcRecord.getArity();
        result = Record::build(vm, width, arity);
        RichNode(arity).as<mozart::Arity>().lookupFeature(vm, feature, featureIndex);

        srcElements = srcRecord.getElementsArray();
        destElements = RichNode(result).as<Record>().getElementsArray();
      }

      for (size_t i = 0; i < width; ++i) {
        if (i == featureIndex)
          destElements[i].init(vm, fieldValue);
        else
          destElements[i].init(vm, srcElements[i]);
      }

      success = build(vm, true);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODRECORD_H
