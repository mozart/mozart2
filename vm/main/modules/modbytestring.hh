// Copyright © 2012, Université catholique de Louvain
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

#ifndef __MODBYTESTRING_H
#define __MODBYTESTRING_H

#include "../mozartcore.hh"

#include <iostream>

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////////
// ByteString module //
///////////////////////

class ModByteString : public Module {
private:
  static OpResult parseEncoding(VM vm, In encodingNode,
                                ByteStringEncoding& encoding) {
    using namespace patternmatching;
    OpResult matchRes = OpResult::proceed();
    if (matches(vm, matchRes, encodingNode, MOZART_STR("latin1"))) {
      encoding = ByteStringEncoding::latin1;
    } else if (matches(vm, matchRes, encodingNode, MOZART_STR("iso8859_1"))) {
      encoding = ByteStringEncoding::latin1;
    } else if (matches(vm, matchRes, encodingNode, MOZART_STR("utf8"))) {
      encoding = ByteStringEncoding::utf8;
    } else if (matches(vm, matchRes, encodingNode, MOZART_STR("utf16"))) {
      encoding = ByteStringEncoding::utf16;
    } else if (matches(vm, matchRes, encodingNode, MOZART_STR("utf32"))) {
      encoding = ByteStringEncoding::utf8;
    } else {
      return matchTypeError(vm, matchRes, encodingNode,
                            MOZART_STR("latin1, utf8, utf16 or utf32"));
    }
    return OpResult::proceed();
  }

public:
  ModByteString() : Module("ByteString") {}

  class Is : public Builtin<Is> {
  public:
    Is() : Builtin("is") {}

    OpResult operator()(VM vm, In value, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(ByteStringLike(value).isByteString(vm, boolResult));
      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class Encode : public Builtin<Encode> {
  public:
    Encode() : Builtin("encode") {}

    OpResult operator()(VM vm, In string, In encodingNode,
                        In isLENode, In hasBOMNode, Out result) {
      ByteStringEncoding encoding = ByteStringEncoding::utf8;
      bool isLE, hasBOM;

      MOZART_CHECK_OPRESULT(parseEncoding(vm, encodingNode, encoding));
      MOZART_GET_ARG(isLE, isLENode, MOZART_STR("boolean"));
      MOZART_GET_ARG(hasBOM, hasBOMNode, MOZART_STR("boolean"));

      bool isVirtualString;
      MOZART_CHECK_OPRESULT(
        VirtualString(string).isVirtualString(vm, isVirtualString));
      if (!isVirtualString)
        return raiseTypeError(vm, MOZART_STR("VirtualString"), string);

      std::basic_ostringstream<nchar> combinedStringStream;
      VirtualString(string).toString(vm, combinedStringStream);
      std::basic_string<nchar> combinedString = combinedStringStream.str();
      LString<nchar> rawString (combinedString.data(), combinedString.length());

      return encodeToBytestring(vm, rawString, encoding, isLE, hasBOM, result);
    }
  };

  class Decode : public Builtin<Decode> {
  public:
    Decode() : Builtin("decode") {}

    OpResult operator()(VM vm, In value, In encodingNode,
                        In isLENode, In hasBOMNode, Out result) {
      ByteStringEncoding encoding = ByteStringEncoding::utf8;
      bool isLE, hasBOM;
      MOZART_CHECK_OPRESULT(parseEncoding(vm, encodingNode, encoding));
      MOZART_GET_ARG(isLE, isLENode, MOZART_STR("boolean"));
      MOZART_GET_ARG(hasBOM, hasBOMNode, MOZART_STR("boolean"));
      return ByteStringLike(value).bsDecode(vm, encoding, isLE, hasBOM, result);
    }
  };

  class Append : public Builtin<Append> {
  public:
    Append() : Builtin("append") {}

    OpResult operator()(VM vm, In left, In right, Out result) {
      return ByteStringLike(left).bsAppend(vm, right, result);
    }
  };

  class Slice : public Builtin<Slice> {
  public:
    Slice() : Builtin("slice") {}

    OpResult operator()(VM vm, In value, In fromNode, In toNode, Out result) {
      nativeint from, to;
      MOZART_GET_ARG(from, fromNode, MOZART_STR("integer"));
      MOZART_GET_ARG(to, toNode, MOZART_STR("integer"));
      return ByteStringLike(value).bsSlice(vm, from, to, result);
    }
  };

  class Length : public Builtin<Length> {
  public:
    Length() : Builtin("length") {}

    OpResult operator()(VM vm, In value, Out result) {
      nativeint integerResult = 0;
      MOZART_CHECK_OPRESULT(ByteStringLike(value).bsLength(vm, integerResult));
      result = SmallInt::build(vm, integerResult);
      return OpResult::proceed();
    }
  };

  class Get : public Builtin<Get> {
  public:
    Get() : Builtin("get") {}

    OpResult operator()(VM vm, In value, In indexNode, Out result) {
      nativeint index;
      unsigned char charResult = 0;
      MOZART_GET_ARG(index, indexNode, MOZART_STR("integer"));
      MOZART_CHECK_OPRESULT(ByteStringLike(value).bsGet(vm, index, charResult));
      result = SmallInt::build(vm, charResult);
      return OpResult::proceed();
    }
  };

  class StrChr : public Builtin<StrChr> {
  public:
    StrChr() : Builtin("strchr") {}

    OpResult operator()(VM vm, In value, In fromNode, In charNode, Out result) {
      nativeint index;
      char character;
      MOZART_GET_ARG(index, fromNode, MOZART_STR("integer"));
      MOZART_GET_ARG(character, charNode, MOZART_STR("char"));
      return ByteStringLike(value).bsStrChr(vm, index, character, result);
    }
  };
};

}

}

#endif

#endif // __MODBYTESTRING_H
