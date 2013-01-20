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

#ifndef __MODVIRTUALBYTESTRING_H
#define __MODVIRTUALBYTESTRING_H

#include "../mozartcore.hh"

#include <sstream>
#include <cstdlib>

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////////////////
// VirtualByteString module //
//////////////////////////////

class ModVirtualByteString : public Module {
public:
  ModVirtualByteString() : Module("VirtualByteString") {}

  class Is : public Builtin<Is> {
  public:
    Is() : Builtin("is") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, ozIsVirtualByteString(vm, value));
    }
  };

  class ToCompactByteString : public Builtin<ToCompactByteString> {
  public:
    ToCompactByteString() : Builtin("toCompactByteString") {}

    static void call(VM vm, In value, Out result) {
      size_t bufSize = ozVBSLengthForBuffer(vm, value);

      if (value.is<ByteString>()) {
        result.copy(vm, value);
        return;
      }

      {
        std::vector<unsigned char> buffer;
        ozVBSGet(vm, value, bufSize, buffer);
        result = ByteString::build(vm, newLString(vm, buffer));
      }
    }
  };

  class ToByteList : public Builtin<ToByteList> {
  public:
    ToByteList() : Builtin("toByteList") {}

    static void call(VM vm, In value, In tail, Out result) {
      size_t bufSize = ozVBSLengthForBuffer(vm, value);

      if (value.is<Cons>() ||
          patternmatching::matches(vm, value, vm->coreatoms.nil)) {
        result.copy(vm, value);
        return;
      }

      {
        std::vector<unsigned char> buffer;
        ozVBSGet(vm, value, bufSize, buffer);

        OzListBuilder builder(vm);
        for (auto iter = buffer.rbegin(); iter != buffer.rend(); ++iter)
          builder.push_front(vm, (nativeint) *iter);
        result = builder.get(vm, tail);
      }
    }
  };

  class Length : public Builtin<Length> {
  public:
    Length() : Builtin("length") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, ozVBSLength(vm, value));
    }
  };
};

}

}

#endif

#endif // __MODVIRTUALBYTESTRING_H
