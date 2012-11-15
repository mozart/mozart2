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

#ifndef __MODCODERS_H
#define __MODCODERS_H

#include "../mozartcore.hh"

#include <iostream>

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////
// Coders module //
///////////////////

class ModCoders : public Module {
private:
  static void parseEncoding(VM vm, In encodingNode, In encodingVariantList,
                            ByteStringEncoding& encoding,
                            EncodingVariant& variant) {
    using namespace patternmatching;

    if (matches(vm, encodingNode, MOZART_STR("latin1"))) {
      encoding = ByteStringEncoding::latin1;
    } else if (matches(vm, encodingNode, MOZART_STR("iso8859_1"))) {
      encoding = ByteStringEncoding::latin1;
    } else if (matches(vm, encodingNode, MOZART_STR("utf8"))) {
      encoding = ByteStringEncoding::utf8;
    } else if (matches(vm, encodingNode, MOZART_STR("utf16"))) {
      encoding = ByteStringEncoding::utf16;
    } else if (matches(vm, encodingNode, MOZART_STR("utf32"))) {
      encoding = ByteStringEncoding::utf8;
    } else {
      raiseTypeError(vm, MOZART_STR("latin1, utf8, utf16 or utf32"),
                     encodingNode);
    }

    variant = EncodingVariant::none;

    ozListForEach(vm, encodingVariantList,
      [&](atom_t atom) {
        auto atomLStr = makeLString(atom.contents(), atom.length());
        if (atomLStr == MOZART_STR("bom")) {
          variant |= EncodingVariant::hasBOM;
        } else if (atomLStr == MOZART_STR("littleEndian")) {
          variant |= EncodingVariant::littleEndian;
        } else if (atomLStr == MOZART_STR("bigEndian")) {
          variant &= ~EncodingVariant::littleEndian;
        } else {
          raiseTypeError(
            vm, MOZART_STR("list of bom, littleEndian or bigEndian"),
            encodingVariantList);
        }
      },
      MOZART_STR("List of Atoms"));
  }

public:
  ModCoders() : Module("Coders") {}

  class Encode : public Builtin<Encode> {
  public:
    Encode() : Builtin("encode") {}

    void operator()(VM vm, In string, In encodingNode,
                    In variantNode, Out result) {
      ByteStringEncoding encoding = ByteStringEncoding::utf8;
      EncodingVariant variant = EncodingVariant::none;
      parseEncoding(vm, encodingNode, variantNode, encoding, variant);

      size_t bufSize = ozVSLengthForBuffer(vm, string);

      mut::LString<unsigned char> encoded(nullptr);
      {
        std::vector<nchar> buffer;
        ozVSGet(vm, string, bufSize, buffer);
        auto rawString = makeLString(buffer.data(), buffer.size());

        encoded = newLString(vm, encodeGeneric(rawString, encoding, variant));
      }

      if (encoded.isError())
        raiseUnicodeError(vm, encoded.error);

      result = ByteString::build(vm, encoded);
    }
  };

  class Decode : public Builtin<Decode> {
  public:
    Decode() : Builtin("decode") {}

    void operator()(VM vm, In value, In encodingNode,
                    In variantNode, Out result) {
      ByteStringEncoding encoding = ByteStringEncoding::utf8;
      EncodingVariant variant = EncodingVariant::none;
      parseEncoding(vm, encodingNode, variantNode, encoding, variant);

      size_t bufSize = ozVBSLengthForBuffer(vm, value);

      mut::LString<nchar> decoded(nullptr);
      {
        std::vector<unsigned char> buffer;
        ozVBSGet(vm, value, bufSize, buffer);
        auto rawString = makeLString(buffer.data(), buffer.size());

        decoded = newLString(vm, decodeGeneric(rawString, encoding, variant));
      }

      if (decoded.isError())
        raiseUnicodeError(vm, decoded.error);

      result = String::build(vm, decoded);
    }
  };
};

}

}

#endif

#endif // __MODCODERS_H
