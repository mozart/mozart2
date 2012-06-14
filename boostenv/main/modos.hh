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

#ifndef __MODOSBOOST_H
#define __MODOSBOOST_H

#include <mozart.hh>

#include "boostenv-decl.hh"

#include <iostream>

#ifndef MOZART_GENERATOR

namespace mozart { namespace boostenv {

namespace builtins {

using namespace ::mozart::builtins;

///////////////
// OS module //
///////////////

class ModOS: public Module {
private:
  static const size_t MaxBufferSize = 1024*1024;
public:
  ModOS(): Module("OS") {}

  // Random number generation

  class Rand: public Builtin<Rand> {
  public:
    Rand(): Builtin("rand") {}

    OpResult operator()(VM vm, Out result) {
      result = SmallInt::build(vm, BoostBasedVM::forVM(vm).random_generator());

      return OpResult::proceed();
    }
  };

  class Srand: public Builtin<Srand> {
  public:
    Srand(): Builtin("srand") {}

    OpResult operator()(VM vm, In seed) {
      nativeint intSeed;
      MOZART_GET_ARG(intSeed, seed, u"integer");

      BoostBasedVM::forVM(vm).random_generator.seed(
        (BoostBasedVM::random_generator_t::result_type) intSeed);

      return OpResult::proceed();
    }
  };

  class RandLimits: public Builtin<RandLimits> {
  public:
    RandLimits(): Builtin("randLimits") {}

    OpResult operator()(VM vm, Out min, Out max) {
      min = SmallInt::build(vm, BoostBasedVM::random_generator_t::min());
      max = SmallInt::build(vm, BoostBasedVM::random_generator_t::max());

      return OpResult::proceed();
    }
  };

  // File I/O

  class Fopen: public Builtin<Fopen> {
  public:
    Fopen(): Builtin("fopen") {}

    OpResult operator()(VM vm, In fileName, In mode, Out result) {
      std::string strFileName, strMode;
      MOZART_CHECK_OPRESULT(ozStringToStdString(vm, fileName, strFileName));
      MOZART_CHECK_OPRESULT(ozStringToStdString(vm, mode, strMode));

      std::FILE* file = std::fopen(strFileName.c_str(), strMode.c_str());
      if (file == nullptr)
        return raiseLastOSError(vm);

      result = trivialBuild(vm, BoostBasedVM::forVM(vm).registerFile(file));
      return OpResult::proceed();
    }
  };

  class Fread: public Builtin<Fread> {
  public:
    Fread(): Builtin("fread") {}

    OpResult operator()(VM vm, In fd, In count, In end,
                        Out actualCount, Out result) {
      std::FILE* file = nullptr;
      MOZART_CHECK_OPRESULT(BoostBasedVM::forVM(vm).getFile(fd, file));

      nativeint intCount;
      MOZART_GET_ARG(intCount, count, u"integer");

      if (intCount <= 0) {
        actualCount = trivialBuild(vm, 0);
        result.copy(vm, end);
        return OpResult::proceed();
      }

      size_t bufferSize = std::min((size_t) intCount, MaxBufferSize);
      void* buffer = vm->malloc(bufferSize);

      size_t readCount = std::fread(buffer, 1, bufferSize, file);

      if ((readCount < bufferSize) && std::ferror(file)) {
        // error
        vm->free(buffer, bufferSize);
        return raise(vm, u"system", u"fread");
      }

      char* charBuffer = static_cast<char*>(buffer);

      UnstableNode res(vm, end);
      for (size_t i = readCount; i > 0; i--)
        res = buildCons(vm, charBuffer[i-1], std::move(res));

      vm->free(buffer, bufferSize);

      actualCount = trivialBuild(vm, readCount);
      result = std::move(res);

      return OpResult::proceed();
    }
  };

  class Fwrite: public Builtin<Fwrite> {
  public:
    Fwrite(): Builtin("fwrite") {}

    OpResult operator()(VM vm, In fd, In data, Out writtenCount) {
      std::FILE* file = nullptr;
      MOZART_CHECK_OPRESULT(BoostBasedVM::forVM(vm).getFile(fd, file));

      size_t size = 0;
      MOZART_CHECK_OPRESULT(ozListLength(vm, data, size));

      if (size == 0)
        return OpResult::proceed();

      void* buffer = vm->malloc(size);
      MOZART_CHECK_OPRESULT(ozStringToBuffer(vm, data, size,
                                             static_cast<char*>(buffer)));

      if (std::fwrite(buffer, 1, size, file) != size)
        return raiseLastOSError(vm);

      writtenCount = trivialBuild(vm, size);
      return OpResult::proceed();
    }
  };

  class Fseek: public Builtin<Fseek> {
  public:
    Fseek(): Builtin("fseek") {}

    OpResult operator()(VM vm, In fd, In offset, In whence, Out where) {
      using namespace patternmatching;

      std::FILE* file = nullptr;
      MOZART_CHECK_OPRESULT(BoostBasedVM::forVM(vm).getFile(fd, file));

      nativeint intOffset;
      MOZART_GET_ARG(intOffset, offset, u"integer");

      int intWhence;
      OpResult res = OpResult::proceed();
      if (matches(vm, res, whence, u"SEEK_SET")) {
        intWhence = SEEK_SET;
      } else if (matches(vm, res, whence, u"SEEK_CUR")) {
        intWhence = SEEK_CUR;
      } else if (matches(vm, res, whence, u"SEEK_END")) {
        intWhence = SEEK_END;
      } else {
        return matchTypeError(vm, res, whence,
                              u"'SEEK_SET', 'SEEK_CUR' or 'SEEK_END'");
      }

      auto seekResult = std::fseek(file, (long) intOffset, intWhence);

      if (seekResult < 0)
        return raiseLastOSError(vm);

      where = SmallInt::build(vm, seekResult);
      return OpResult::proceed();
    }
  };

  class Fclose: public Builtin<Fclose> {
  public:
    Fclose(): Builtin("fclose") {}

    OpResult operator()(VM vm, In fd) {
      BoostBasedVM& env = BoostBasedVM::forVM(vm);

      nativeint intfd = 0;
      MOZART_GET_ARG(intfd, fd, u"filedesc");

      // Never actually close standard I/O
      if ((intfd == env.fdStdin) || (intfd == env.fdStdout) ||
          (intfd == env.fdStderr))
        return OpResult::proceed();

      std::FILE* file = nullptr;
      MOZART_CHECK_OPRESULT(env.getFile(intfd, file));

      if (std::fclose(file) != 0)
        return raiseLastOSError(vm);

      env.unregisterFile(intfd);
      return OpResult::proceed();
    }
  };

  class Stdin: public Builtin<Stdin> {
  public:
    Stdin(): Builtin("stdin") {}

    OpResult operator()(VM vm, Out result) {
      result = SmallInt::build(vm, BoostBasedVM::forVM(vm).fdStdin);
      return OpResult::proceed();
    }
  };

  class Stdout: public Builtin<Stdout> {
  public:
    Stdout(): Builtin("stdout") {}

    OpResult operator()(VM vm, Out result) {
      result = SmallInt::build(vm, BoostBasedVM::forVM(vm).fdStdout);
      return OpResult::proceed();
    }
  };

  class Stderr: public Builtin<Stderr> {
  public:
    Stderr(): Builtin("stderr") {}

    OpResult operator()(VM vm, Out result) {
      result = SmallInt::build(vm, BoostBasedVM::forVM(vm).fdStderr);
      return OpResult::proceed();
    }
  };
};

}

} }

#endif // MOZART_GENERATOR

#endif // __MODOSBOOST_H
