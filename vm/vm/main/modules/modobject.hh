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

    OpResult operator()(VM vm, In clazz, Out result) {
      UnstableNode attrModel, featModel;

      UnstableNode ooAttr = build(vm, vm->coreatoms.ooAttr);
      MOZART_CHECK_OPRESULT(Dottable(clazz).dot(vm, ooAttr, attrModel));

      UnstableNode ooFeat = build(vm, vm->coreatoms.ooFeat);
      MOZART_CHECK_OPRESULT(Dottable(clazz).dot(vm, ooFeat, featModel));

      size_t attrCount = 0;
      MOZART_CHECK_OPRESULT(RecordLike(attrModel).width(vm, attrCount));

      result = Object::build(vm, attrCount, clazz, attrModel, featModel);
      return OpResult::proceed();
    }
  };

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    OpResult operator()(VM vm, In value, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(ObjectLike(value).isObject(vm, boolResult));

      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class GetClass: public Builtin<GetClass>, public InlineAs<OpInlineGetClass> {
  public:
    GetClass(): Builtin("getClass") {}

    OpResult operator()(VM vm, In object, Out result) {
      return ObjectLike(object).getClass(vm, result);
    }
  };

  class AttrGet: public Builtin<AttrGet> {
  public:
    AttrGet(): Builtin("attrGet") {}

    OpResult operator()(VM vm, In object, In attribute, Out result) {
      return ObjectLike(object).attrGet(vm, attribute, result);
    }
  };

  class AttrPut: public Builtin<AttrPut> {
  public:
    AttrPut(): Builtin("attrPut") {}

    OpResult operator()(VM vm, In object, In attribute, In newValue) {
      return ObjectLike(object).attrPut(vm, attribute, newValue);
    }
  };

  class AttrExchangeFun: public Builtin<AttrExchangeFun> {
  public:
    AttrExchangeFun(): Builtin("attrExchangeFun") {}

    OpResult operator()(VM vm, In object, In attribute,
                        In newValue, Out oldValue) {
      return ObjectLike(object).attrExchange(vm, attribute,
                                             newValue, oldValue);
    }
  };

  class CellOrAttrGet: public Builtin<CellOrAttrGet> {
  public:
    CellOrAttrGet(): Builtin("cellOrAttrGet") {}

    OpResult operator()(VM vm, In object, In cellOrAttr, Out result) {
      bool isCell = false;
      MOZART_CHECK_OPRESULT(CellLike(cellOrAttr).isCell(vm, isCell));

      if (isCell)
        return CellLike(cellOrAttr).access(vm, result);
      else
        return ObjectLike(object).attrGet(vm, cellOrAttr, result);
    }
  };

  class CellOrAttrPut: public Builtin<CellOrAttrPut> {
  public:
    CellOrAttrPut(): Builtin("cellOrAttrPut") {}

    OpResult operator()(VM vm, In object, In cellOrAttr, In newValue) {
      bool isCell = false;
      MOZART_CHECK_OPRESULT(CellLike(cellOrAttr).isCell(vm, isCell));

      if (isCell)
        return CellLike(cellOrAttr).assign(vm, newValue);
      else
        return ObjectLike(object).attrPut(vm, cellOrAttr, newValue);
    }
  };

  class CellOrAttrExchangeFun: public Builtin<CellOrAttrExchangeFun> {
  public:
    CellOrAttrExchangeFun(): Builtin("cellOrAttrExchangeFun") {}

    OpResult operator()(VM vm, In object, In cellOrAttr,
                        In newValue, Out oldValue) {
      bool isCell = false;
      MOZART_CHECK_OPRESULT(CellLike(cellOrAttr).isCell(vm, isCell));

      if (isCell)
        return CellLike(cellOrAttr).exchange(vm, newValue, oldValue);
      else
        return ObjectLike(object).attrExchange(vm, cellOrAttr,
                                               newValue, oldValue);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODOBJECT_H
