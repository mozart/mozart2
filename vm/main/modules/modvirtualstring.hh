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

    void operator()(VM vm, In value, Out result) {
      result = build(vm, VirtualString(value).isVirtualString(vm));
    }
  };

  class ToString : public Builtin<ToString> {
  public:
    ToString() : Builtin("toString") {}

    void operator()(VM vm, In value, Out result) {
      std::basic_ostringstream<nchar> stringStream;
      VirtualString(value).toString(vm, stringStream);
      result = String::build(vm, newLString(vm, stringStream.str()));
    }
  };

  class Length : public Builtin<Length> {
  public:
    Length() : Builtin("length") {}

    void operator()(VM vm, In value, Out result) {
      result = build(vm, VirtualString(value).vsLength(vm));
    }
  };

  class ToFloat : public Builtin<ToFloat> {
  public:
    ToFloat() : Builtin("toFloat") {}

    void operator()(VM vm, In value, Out result) {
      std::basic_ostringstream<nchar> stringStream;
      VirtualString(value).toString(vm, stringStream);

      auto bufferStr = stringStream.str();
      auto nstr = makeLString(bufferStr.c_str(), bufferStr.size());
      auto utf8str = toUTF<char>(nstr);
      std::stringstream strStream;
      strStream << utf8str;

      auto str = strStream.str();

      for (auto iter = str.begin(); iter != str.end(); ++iter)
        if (*iter == '~')
          *iter = '-';

      char* end = nullptr;
      double doubleResult = 0.0;
      doubleResult = std::strtod(str.c_str(), &end);

      if (*end != '\0')
        raiseKernelError(vm, MOZART_STR("stringNoFloat"), value);

      result = build(vm, doubleResult);
    }
  };
};

}

}

#endif

#endif // __MODVIRTUALSTRING_H
