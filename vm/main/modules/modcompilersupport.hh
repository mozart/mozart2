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

#ifndef __MODCOMPILERSUPPORT_H
#define __MODCOMPILERSUPPORT_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

////////////////////////////
// CompilerSupport module //
////////////////////////////

class ModCompilerSupport: public Module {
public:
  ModCompilerSupport(): Module("CompilerSupport") {}

  class NewCodeArea: public Builtin<NewCodeArea> {
  public:
    NewCodeArea(): Builtin("newCodeArea") {}

    OpResult operator()(VM vm, In byteCodeList, In XCount, In KsList,
                        Out result) {
      // Read byte code
      std::vector<ByteCode> byteCode;

      ozListForEach(vm, byteCodeList,
        [&] (nativeint elem) -> OpResult {
          if ((elem < std::numeric_limits<ByteCode>::min()) ||
              (elem > std::numeric_limits<ByteCode>::max())) {
            return raiseTypeError(vm, MOZART_STR("Byte code element"),
                                  build(vm, elem));
          } else {
            byteCode.push_back((ByteCode) elem);
            return OpResult::proceed();
          }
        },
        MOZART_STR("List of byte code elements")
      );

      // Read X count
      nativeint intXCount = 0;
      MOZART_GET_ARG(intXCount, XCount, MOZART_STR("positive integer"));

      // Read number of K registers
      size_t KCount = 0;
      MOZART_CHECK_OPRESULT(ozListLength(vm, KsList, KCount));

      // Create the code area
      result = CodeArea::build(vm, KCount, &byteCode.front(),
                               byteCode.size() * sizeof(ByteCode),
                               intXCount);

      // Fill the K registers
      ArrayInitializer KInitializer = result;
      size_t index = 0;

      ozListForEach(vm, KsList,
        [&] (UnstableNode& elem) -> OpResult {
          KInitializer.initElement(vm, index, elem);
          index++;
          return OpResult::proceed();
        },
        MOZART_STR("list")
      );

      return OpResult::proceed();
    }
  };

  class NewAbstraction: public Builtin<NewAbstraction> {
  public:
    NewAbstraction(): Builtin("newAbstraction") {}

    OpResult operator()(VM vm, In arity, In body, In GsList, Out result) {
      // Read arity
      nativeint intArity = 0;
      MOZART_GET_ARG(intArity, arity, MOZART_STR("positive integer"));

      // Check the type of the code area
      bool bodyIsCodeArea = false;
      MOZART_CHECK_OPRESULT(
        CodeAreaProvider(body).isCodeAreaProvider(vm, bodyIsCodeArea));
      if (!bodyIsCodeArea) {
        return raiseTypeError(vm, MOZART_STR("Code area"), body);
      }

      // Read number of G registers
      size_t GCount = 0;
      MOZART_CHECK_OPRESULT(ozListLength(vm, GsList, GCount));

      // Create the abstraction
      result = Abstraction::build(vm, GCount, intArity, body);

      // Fill the G registers
      ArrayInitializer GInitializer = result;
      size_t index = 0;

      ozListForEach(vm, GsList,
        [&] (UnstableNode& elem) -> OpResult {
          GInitializer.initElement(vm, index, elem);
          index++;
          return OpResult::proceed();
        },
        MOZART_STR("list")
      );

      return OpResult::proceed();
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // __MODCOMPILERSUPPORT_H
