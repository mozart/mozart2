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

#ifndef __MODDICTIONARY_H
#define __MODDICTIONARY_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////////
// Dictionary module //
///////////////////////

class ModDictionary: public Module {
public:
  ModDictionary(): Module("Dictionary") {}

  class New: public Builtin<New> {
  public:
    New(): Builtin("new") {}

    OpResult operator()(VM vm, Out result) {
      result = Dictionary::build(vm);
      return OpResult::proceed();
    }
  };

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    OpResult operator()(VM vm, In value, Out result) {
      bool boolResult;
      MOZART_CHECK_OPRESULT(DictionaryLike(value).isDictionary(vm, boolResult));

      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class IsEmpty: public Builtin<IsEmpty> {
  public:
    IsEmpty(): Builtin("isEmpty") {}

    OpResult operator()(VM vm, In dict, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(DictionaryLike(dict).dictIsEmpty(vm, boolResult));

      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class Member: public Builtin<Member> {
  public:
    Member(): Builtin("member") {}

    OpResult operator()(VM vm, In dict, In feature, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(DictionaryLike(dict).dictMember(
        vm, feature, boolResult));

      result = trivialBuild(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class Get: public Builtin<Get> {
  public:
    Get(): Builtin("get") {}

    OpResult operator()(VM vm, In dict, In feature, Out result) {
      return DictionaryLike(dict).dictGet(vm, feature, result);
    }
  };

  class CondGet: public Builtin<CondGet> {
  public:
    CondGet(): Builtin("condGet") {}

    OpResult operator()(VM vm, In dict, In feature, In defaultValue,
                        Out result) {
      return DictionaryLike(dict).dictCondGet(vm, feature, defaultValue,
                                              result);
    }
  };

  class Put: public Builtin<Put> {
  public:
    Put(): Builtin("put") {}

    OpResult operator()(VM vm, In dict, In feature, In newValue) {
      return DictionaryLike(dict).dictPut(vm, feature, newValue);
    }
  };

  class ExchangeFun: public Builtin<ExchangeFun> {
  public:
    ExchangeFun(): Builtin("exchangeFun") {}

    OpResult operator()(VM vm, In dict, In feature, In newValue, Out oldValue) {
      return DictionaryLike(dict).dictExchange(vm, feature, newValue, oldValue);
    }
  };

  class CondExchangeFun: public Builtin<CondExchangeFun> {
  public:
    CondExchangeFun(): Builtin("condExchangeFun") {}

    OpResult operator()(VM vm, In dict, In feature, In defaultValue,
                        In newValue, Out oldValue) {
      return DictionaryLike(dict).dictCondExchange(vm, feature, defaultValue,
                                                   newValue, oldValue);
    }
  };

  class Remove: public Builtin<Remove> {
  public:
    Remove(): Builtin("remove") {}

    OpResult operator()(VM vm, In dict, In feature) {
      return DictionaryLike(dict).dictRemove(vm, feature);
    }
  };

  class RemoveAll: public Builtin<RemoveAll> {
  public:
    RemoveAll(): Builtin("removeAll") {}

    OpResult operator()(VM vm, In dict) {
      return DictionaryLike(dict).dictRemoveAll(vm);
    }
  };

  class Keys: public Builtin<Keys> {
  public:
    Keys(): Builtin("keys") {}

    OpResult operator()(VM vm, In dict, Out result) {
      return DictionaryLike(dict).dictKeys(vm, result);
    }
  };

  class Entries: public Builtin<Entries> {
  public:
    Entries(): Builtin("entries") {}

    OpResult operator()(VM vm, In dict, Out result) {
      return DictionaryLike(dict).dictEntries(vm, result);
    }
  };

  class Items: public Builtin<Items> {
  public:
    Items(): Builtin("items") {}

    OpResult operator()(VM vm, In dict, Out result) {
      return DictionaryLike(dict).dictItems(vm, result);
    }
  };

  class Clone: public Builtin<Clone> {
  public:
    Clone(): Builtin("clone") {}

    OpResult operator()(VM vm, In dict, Out result) {
      return DictionaryLike(dict).dictClone(vm, result);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODDICTIONARY_H
