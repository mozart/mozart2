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

#ifndef __MODOBJECT_H
#define __MODOBJECT_H

#include "../mozartcore.hh"

#include <iostream>

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////
// Object module //
///////////////////

class ModObject: public Module {
public:
  ModObject(): Module("Object") {}

  class New: public Builtin<New> {
  public:
    New(): Builtin("new") {}

    static void call(VM vm, In clazz, Out result) {
      auto ooAttr = build(vm, vm->coreatoms.ooAttr);
      auto attrModel = Dottable(clazz).dot(vm, ooAttr);

      auto ooFeat = build(vm, vm->coreatoms.ooFeat);
      auto featModel = Dottable(clazz).dot(vm, ooFeat);

      size_t attrCount = RecordLike(attrModel).width(vm);

      result = Object::build(vm, attrCount, clazz, attrModel, featModel);
    }
  };

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, ObjectLike(value).isObject(vm));
    }
  };

  class GetClass: public Builtin<GetClass>, public InlineAs<OpInlineGetClass> {
  public:
    GetClass(): Builtin("getClass") {}

    static void call(VM vm, In object, Out result) {
      result = ObjectLike(object).getClass(vm);
    }
  };

  class AttrGet: public Builtin<AttrGet> {
  public:
    AttrGet(): Builtin("attrGet") {}

    static void call(VM vm, In object, In attribute, Out result) {
      result = ObjectLike(object).attrGet(vm, attribute);
    }
  };

  class AttrPut: public Builtin<AttrPut> {
  public:
    AttrPut(): Builtin("attrPut") {}

    static void call(VM vm, In object, In attribute, In newValue) {
      ObjectLike(object).attrPut(vm, attribute, newValue);
    }
  };

  class AttrExchangeFun: public Builtin<AttrExchangeFun> {
  public:
    AttrExchangeFun(): Builtin("attrExchangeFun") {}

    static void call(VM vm, In object, In attribute,
                     In newValue, Out oldValue) {
      oldValue = ObjectLike(object).attrExchange(vm, attribute, newValue);
    }
  };

  class CellOrAttrGet: public Builtin<CellOrAttrGet> {
  public:
    CellOrAttrGet(): Builtin("cellOrAttrGet") {}

    static void call(VM vm, In object, In cellOrAttr, Out result) {
      if (CellLike(cellOrAttr).isCell(vm))
        result = CellLike(cellOrAttr).access(vm);
      else
        result = ObjectLike(object).attrGet(vm, cellOrAttr);
    }
  };

  class CellOrAttrPut: public Builtin<CellOrAttrPut> {
  public:
    CellOrAttrPut(): Builtin("cellOrAttrPut") {}

    static void call(VM vm, In object, In cellOrAttr, In newValue) {
      if (CellLike(cellOrAttr).isCell(vm))
        CellLike(cellOrAttr).assign(vm, newValue);
      else
        ObjectLike(object).attrPut(vm, cellOrAttr, newValue);
    }
  };

  class CellOrAttrExchangeFun: public Builtin<CellOrAttrExchangeFun> {
  public:
    CellOrAttrExchangeFun(): Builtin("cellOrAttrExchangeFun") {}

    static void call(VM vm, In object, In cellOrAttr,
                     In newValue, Out oldValue) {
      if (CellLike(cellOrAttr).isCell(vm))
        oldValue = CellLike(cellOrAttr).exchange(vm, newValue);
      else
        oldValue = ObjectLike(object).attrExchange(vm, cellOrAttr, newValue);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODOBJECT_H
