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

    static void call(VM vm, Out result) {
      result = Dictionary::build(vm);
    }
  };

  class Is: public Builtin<Is> {
  public:
    Is(): Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, DictionaryLike(value).isDictionary(vm));
    }
  };

  class IsEmpty: public Builtin<IsEmpty> {
  public:
    IsEmpty(): Builtin("isEmpty") {}

    static void call(VM vm, In dict, Out result) {
      result = build(vm, DictionaryLike(dict).dictIsEmpty(vm));
    }
  };

  class Member: public Builtin<Member> {
  public:
    Member(): Builtin("member") {}

    static void call(VM vm, In dict, In feature, Out result) {
      result = build(vm, DictionaryLike(dict).dictMember(vm, feature));
    }
  };

  class Get: public Builtin<Get> {
  public:
    Get(): Builtin("get") {}

    static void call(VM vm, In dict, In feature, Out result) {
      result = DictionaryLike(dict).dictGet(vm, feature);
    }
  };

  class CondGet: public Builtin<CondGet> {
  public:
    CondGet(): Builtin("condGet") {}

    static void call(VM vm, In dict, In feature, In defaultValue, Out result) {
      result = DictionaryLike(dict).dictCondGet(vm, feature, defaultValue);
    }
  };

  class Put: public Builtin<Put> {
  public:
    Put(): Builtin("put") {}

    static void call(VM vm, In dict, In feature, In newValue) {
      DictionaryLike(dict).dictPut(vm, feature, newValue);
    }
  };

  class ExchangeFun: public Builtin<ExchangeFun> {
  public:
    ExchangeFun(): Builtin("exchangeFun") {}

    static void call(VM vm, In dict, In feature, In newValue, Out oldValue) {
      oldValue = DictionaryLike(dict).dictExchange(vm, feature, newValue);
    }
  };

  class CondExchangeFun: public Builtin<CondExchangeFun> {
  public:
    CondExchangeFun(): Builtin("condExchangeFun") {}

    static void call(VM vm, In dict, In feature, In defaultValue,
                     In newValue, Out oldValue) {
      oldValue = DictionaryLike(dict).dictCondExchange(
        vm, feature, defaultValue, newValue);
    }
  };

  class Remove: public Builtin<Remove> {
  public:
    Remove(): Builtin("remove") {}

    static void call(VM vm, In dict, In feature) {
      DictionaryLike(dict).dictRemove(vm, feature);
    }
  };

  class RemoveAll: public Builtin<RemoveAll> {
  public:
    RemoveAll(): Builtin("removeAll") {}

    static void call(VM vm, In dict) {
      DictionaryLike(dict).dictRemoveAll(vm);
    }
  };

  class Keys: public Builtin<Keys> {
  public:
    Keys(): Builtin("keys") {}

    static void call(VM vm, In dict, Out result) {
      result = DictionaryLike(dict).dictKeys(vm);
    }
  };

  class Entries: public Builtin<Entries> {
  public:
    Entries(): Builtin("entries") {}

    static void call(VM vm, In dict, Out result) {
      result = DictionaryLike(dict).dictEntries(vm);
    }
  };

  class Items: public Builtin<Items> {
  public:
    Items(): Builtin("items") {}

    static void call(VM vm, In dict, Out result) {
      result = DictionaryLike(dict).dictItems(vm);
    }
  };

  class Clone: public Builtin<Clone> {
  public:
    Clone(): Builtin("clone") {}

    static void call(VM vm, In dict, Out result) {
      result = DictionaryLike(dict).dictClone(vm);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODDICTIONARY_H
