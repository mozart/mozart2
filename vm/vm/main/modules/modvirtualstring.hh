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

#ifndef __MODVIRTUALSTRING_H
#define __MODVIRTUALSTRING_H

#include "../mozartcore.hh"

#include <sstream>
#include <cstdlib>

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////////////
// VirtualString module //
//////////////////////////

class ModVirtualString : public Module {
public:
  ModVirtualString() : Module("VirtualString") {}

  class Is : public Builtin<Is> {
  public:
    Is() : Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, ozIsVirtualString(vm, value));
    }
  };

  class ToCompactString : public Builtin<ToCompactString> {
  public:
    ToCompactString() : Builtin("toCompactString") {}

    static void call(VM vm, In value, Out result) {
      size_t bufSize = ozVSLengthForBuffer(vm, value);

      if (value.is<String>()) {
        result.copy(vm, value);
        return;
      }

      {
        std::vector<nchar> buffer;
        ozVSGet(vm, value, bufSize, buffer);
        result = String::build(vm, newLString(vm, buffer));
      }
    }
  };

  class ToCharList : public Builtin<ToCharList> {
  public:
    ToCharList() : Builtin("toCharList") {}

    static void call(VM vm, In value, In tail, Out result) {
      size_t bufSize = ozVSLengthForBuffer(vm, value);

      if (value.is<Cons>() ||
          patternmatching::matches(vm, value, vm->coreatoms.nil)) {
        result.copy(vm, value);
        return;
      }

      {
        std::vector<nchar> buffer;
        ozVSGet(vm, value, bufSize, buffer);

        OzListBuilder builder(vm);
        forEachCodePoint(makeLString(buffer.data(), buffer.size()),
          [vm, &builder] (char32_t c) -> bool {
            builder.push_back(vm, (nativeint) c);
            return true;
          }
        );
        result = builder.get(vm, tail);
      }
    }
  };

  class ToAtom : public Builtin<ToAtom> {
  public:
    ToAtom() : Builtin("toAtom") {}

    static void call(VM vm, In value, Out result) {
      size_t bufSize = ozVSLengthForBuffer(vm, value);

      if (value.is<Atom>()) {
        result.copy(vm, value);
        return;
      }

      {
        std::vector<nchar> buffer;
        ozVSGet(vm, value, bufSize, buffer);
        result = Atom::build(vm, buffer.size(), buffer.data());
      }
    }
  };

  class Length : public Builtin<Length> {
  public:
    Length() : Builtin("length") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, ozVSLength(vm, value));
    }
  };

  class ToFloat : public Builtin<ToFloat> {
  public:
    ToFloat() : Builtin("toFloat") {}

    static void call(VM vm, In value, Out result) {
      size_t bufSize = ozVSLengthForBuffer(vm, value);

      bool success;
      double doubleResult;

      {
        std::string str;
        ozVSGet(vm, value, bufSize, str);

        for (auto iter = str.begin(); iter != str.end(); ++iter)
          if (*iter == '~')
            *iter = '-';

        char* end = nullptr;
        doubleResult = std::strtod(str.c_str(), &end);
        success = *end == '\0';
      }

      if (!success)
        raiseKernelError(vm, MOZART_STR("stringNoFloat"), value);

      result = build(vm, doubleResult);
    }
  };
};

}

}

#endif

#endif // __MODVIRTUALSTRING_H
