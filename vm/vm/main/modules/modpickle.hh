// Copyright © 2014, Université catholique de Louvain
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

#ifndef MOZART_MODPICKLE_H
#define MOZART_MODPICKLE_H

#include "../mozartcore.hh"

#include <fstream>

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

///////////////////
// Pickle module //
///////////////////

class ModPickle: public Module {
public:
  ModPickle(): Module("Pickle") {}

  class Pack: public Builtin<Pack> {
  public:
    Pack(): Builtin("pack") {}

    static void call(VM vm, In value, Out result) {
      std::ostringstream buf;
      pickle(vm, value, buf);
      std::string str = buf.str();
      auto bytes = newLString(vm,
        reinterpret_cast<const unsigned char*>(str.data()), str.size());
      result = ByteString::build(vm, bytes);
    }
  };

  class Unpack: public Builtin<Unpack> {
  public:
    Unpack(): Builtin("unpack") {}

    static void call(VM vm, In vbs, Out result) {
      // VBS to vector<unsigned char>
      size_t bufSize = ozVBSLengthForBuffer(vm, vbs);
      std::vector<unsigned char> buffer;
      ozVBSGet(vm, vbs, bufSize, buffer);

      // unpickle
      std::string str(buffer.begin(), buffer.end());
      std::istringstream input(str);
      result = unpickle(vm, input);
    }
  };

  class Save: public Builtin<Save> {
  public:
    Save(): Builtin("save") {}

    static void call(VM vm, In value, In fileNameVS) {
      size_t fileNameSize = ozVSLengthForBuffer(vm, fileNameVS);
      std::string fileName;
      ozVSGet(vm, fileNameVS, fileNameSize, fileName);

      std::ofstream file(fileName, std::ios_base::binary);
      pickle(vm, value, file);
    }
  };

  class Load: public Builtin<Load> {
  public:
    Load(): Builtin("load") {}

    static void call(VM vm, In fileNameVS, Out result) {
      size_t fileNameSize = ozVSLengthForBuffer(vm, fileNameVS);
      std::string fileName;
      ozVSGet(vm, fileNameVS, fileNameSize, fileName);

      std::ifstream file(fileName, std::ios_base::binary);
      result = unpickle(vm, file);
    }
  };
};

}

}

#endif // MOZART_GENERATOR

#endif // MOZART_MODPICKLE_H
