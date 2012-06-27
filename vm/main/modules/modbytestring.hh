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
  static OpResult parseEncoding(VM vm, In encodingNode, In encodingVariantList,
                                ByteStringEncoding& encoding,
                                EncodingVariant& variant) {
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

    variant = EncodingVariant::none;
    return ozListForEach(vm, encodingVariantList,
      [&](const AtomImpl* atom) -> OpResult {
        auto atomLStr = makeLString(atom->contents(), atom->length());
        if (atomLStr == MOZART_STR("bom")) {
          variant |= EncodingVariant::hasBOM;
        } else if (atomLStr == MOZART_STR("littleEndian")) {
          variant |= EncodingVariant::littleEndian;
        } else if (atomLStr == MOZART_STR("bigEndian")) {
          variant &= ~EncodingVariant::littleEndian;
        } else {
          return raiseTypeError(vm,
                                MOZART_STR("list of bom, littleEndian or bigEndian"),
                                encodingVariantList);
        }
        return OpResult::proceed();
      },
    MOZART_STR("List of Atoms"));
  }

public:
  ModByteString() : Module("ByteString") {}

  class Is : public Builtin<Is> {
  public:
    Is() : Builtin("is") {}

    OpResult operator()(VM vm, In value, Out result) {
      bool boolResult = false;
      MOZART_CHECK_OPRESULT(StringLike(value).isByteString(vm, boolResult));
      result = Boolean::build(vm, boolResult);
      return OpResult::proceed();
    }
  };

  class Encode : public Builtin<Encode> {
  public:
    Encode() : Builtin("encode") {}

    OpResult operator()(VM vm, In string, In encodingNode, In variantNode, Out result) {
      ByteStringEncoding encoding;
      EncodingVariant variant;
      MOZART_CHECK_OPRESULT(parseEncoding(vm, encodingNode, variantNode,
                                          encoding, variant));

      bool isVirtualString;
      MOZART_CHECK_OPRESULT(VirtualString(string).isVirtualString(vm, isVirtualString));
      if (!isVirtualString)
        return raiseTypeError(vm, MOZART_STR("VirtualString"), string);

      std::basic_ostringstream<nchar> combinedStringStream;
      VirtualString(string).toString(vm, combinedStringStream);
      auto combinedString = combinedStringStream.str();
      auto rawString = makeLString(combinedString.data(), combinedString.size());

      return encodeToBytestring(vm, rawString, encoding, variant, result);
    }
  };

  class Decode : public Builtin<Decode> {
  public:
    Decode() : Builtin("decode") {}

    OpResult operator()(VM vm, In value, In encodingNode, In variantNode, Out result) {
      if (!value.is<ByteString>())
        return raiseTypeError(vm, MOZART_STR("ByteString"), value);

      ByteStringEncoding encoding;
      EncodingVariant variant;
      MOZART_CHECK_OPRESULT(parseEncoding(vm, encodingNode, variantNode,
                                          encoding, variant));
      return value.as<ByteString>().decode(vm, encoding, variant, result);
    }
  };
};

}

}

#endif

#endif

