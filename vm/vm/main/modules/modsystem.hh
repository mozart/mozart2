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

#ifndef __MODSYSTEM_H
#define __MODSYSTEM_H

#include "../mozartcore.hh"

#include <iostream>

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////
// System module //
///////////////////

class ModSystem: public Module {
public:
  ModSystem(): Module("System") {}

  class PrintRepr: public Builtin<PrintRepr> {
  public:
    PrintRepr(): Builtin("printRepr") {}

    static void call(VM vm, In value, In toStdErr, In newLine) {
      auto boolToStdErr = getArgument<bool>(vm, toStdErr, "Boolean");
      auto boolNewLine = getArgument<bool>(vm, newLine, "Boolean");

      auto& config = vm->getPropertyRegistry().config;

      auto& stream = boolToStdErr ? std::cerr : std::cout;
      stream << repr(vm, value,
                     boolToStdErr ? config.errorsDepth : config.errorsWidth,
                     boolToStdErr ? config.printDepth : config.printWidth);
      if (boolNewLine)
        stream << std::endl;
    }
  };

  class GetRepr: public Builtin<GetRepr> {
  public:
    GetRepr(): Builtin("getRepr") {}

    static void call(VM vm, In value, In depth, In width, Out result) {
      // nil is a nasty one, because its repr is nil, which is the empty string
      if (value.is<Atom>() && (value.as<Atom>().value() == vm->coreatoms.nil)) {
        result = buildList(vm, (nativeint) 'n', (nativeint) 'i', (nativeint) 'l');
        return;
      }

      auto intDepth = getArgument<nativeint>(vm, depth);
      auto intWidth = getArgument<nativeint>(vm, width);

      auto& config = vm->getPropertyRegistry().config;
      if (intDepth <= 0)
        intDepth = config.printDepth;
      if (intWidth <= 0)
        intWidth = config.printWidth;

      std::basic_stringstream<char> buffer;
      buffer << repr(vm, value, intDepth, intWidth);
      auto bufferStr = buffer.str();

      auto utf8str = makeLString(bufferStr.c_str(), bufferStr.size());
      auto str = toUTF<char>(utf8str);

      result = Atom::build(vm, str.length, str.string);
    }
  };

  class PrintName: public Builtin<PrintName> {
  public:
    PrintName(): Builtin("printName") {}

    static void call(VM vm, In value, Out result) {
      result = build(vm, WithPrintName(value).getPrintName(vm));
    }
  };

  class PrintVS: public Builtin<PrintVS> {
  public:
    PrintVS(): Builtin("printVS") {}

    static void call(VM vm, In value, In toStdErr, In newLine) {
      auto boolToStdErr = getArgument<bool>(vm, toStdErr, "Boolean");
      auto boolNewLine = getArgument<bool>(vm, newLine, "Boolean");

      size_t valueBufSize = ozVSLengthForBuffer(vm, value);

      {
        std::string valueStr;
        ozVSGet(vm, value, valueBufSize, valueStr);

        auto& stream = boolToStdErr ? std::cerr : std::cout;
        stream << valueStr;
        if (boolNewLine)
          stream << std::endl;
      }
    }
  };

  class GCDo: public Builtin<GCDo> {
  public:
    GCDo(): Builtin("gcDo") {}

    static void call(VM vm) {
      vm->requestGC();
    }
  };

  class Eq: public Builtin<Eq> {
  public:
    Eq(): Builtin("eq") {}

    static void call(VM vm, In lhs, In rhs, Out result) {
      result = build(vm, lhs.isSameNode(rhs));
    }
  };

  class OnTopLevel: public Builtin<OnTopLevel> {
  public:
    OnTopLevel(): Builtin("onToplevel") {}

    static void call(VM vm, Out result) {
      result = build(vm, vm->isOnTopLevel());
    }
  };

  class Exit: public Builtin<Exit> {
  public:
    Exit(): Builtin("exit") {}

    static void call(VM vm, In exitCode) {
      std::exit(getArgument<nativeint>(vm, exitCode, "Integer"));
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODSYSTEM_H
