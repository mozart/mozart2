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
#include "boostenvtcp-decl.hh"

#include <iostream>

#include <boost/filesystem.hpp>

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

    void operator()(VM vm, Out result) {
      result = build(vm, (nativeint) BoostBasedVM::forVM(vm).random_generator());
    }
  };

  class Srand: public Builtin<Srand> {
  public:
    Srand(): Builtin("srand") {}

    void operator()(VM vm, In seed) {
      auto intSeed = getArgument<nativeint>(vm, seed);

      BoostBasedVM::forVM(vm).random_generator.seed(
        (BoostBasedVM::random_generator_t::result_type) intSeed);
    }
  };

  class RandLimits: public Builtin<RandLimits> {
  public:
    RandLimits(): Builtin("randLimits") {}

    void operator()(VM vm, Out min, Out max) {
      min = build(vm, (nativeint) BoostBasedVM::random_generator_t::min());
      max = build(vm, (nativeint) BoostBasedVM::random_generator_t::max());
    }
  };

  // Environment

  class GetEnv: public Builtin<GetEnv> {
  public:
    GetEnv(): Builtin("getEnv") {}

    void operator()(VM vm, In var, Out result) {
      size_t bufSize = ozVSLengthForBuffer(vm, var);
      char* value;

      {
        std::vector<char> varVector;
        ozVSGetNullTerminated(vm, var, bufSize, varVector);
        value = std::getenv(varVector.data());
      }

      if (value == nullptr)
        result = build(vm, false);
      else
        result = build(vm, systemStrToAtom(vm, value));
    }
  };

  // File I/O

private:
  class WrappedFile {
  public:
    WrappedFile(std::FILE* file): _file(file), _closed(false) {
      assert(file != nullptr);
    }

    ~WrappedFile() {
      close();
    }

    std::FILE* file() {
      return _file;
    }

    bool isClosed() {
      return _closed;
    }

    void close() {
      if (!_closed) {
        // Never actually close standard I/O
        if ((_file != stdin) && (_file != stdout) && (_file != stderr))
          std::fclose(_file);
        _file = nullptr;
        _closed = true;
      }
    }
  private:
    std::FILE* _file;
    bool _closed;
  };

  static WrappedFile* getFileArgument(VM vm, RichNode arg) {
    auto wrappedFile = getPointerArgument<WrappedFile>(vm, arg,
                                                       MOZART_STR("file"));

    if (wrappedFile->isClosed()) {
      raiseSystem(vm, MOZART_STR("os"), MOZART_STR("os"),
                  MOZART_STR("close"), 9, MOZART_STR("Bad filedescriptor"));
    }

    return wrappedFile;
  }

public:
  class GetCWD: public Builtin<GetCWD> {
  public:
    GetCWD(): Builtin("getCWD") {}

    void operator()(VM vm, Out result) {
      auto nativeStr = boost::filesystem::current_path().native();
      auto nresult = toUTF<nchar>(makeLString(nativeStr.c_str(),
                                              nativeStr.size()));

      result = Atom::build(vm, nresult.length, nresult.string);
    }
  };

  class Tmpnam: public Builtin<Tmpnam> {
  public:
    Tmpnam(): Builtin("tmpnam") {}

    void operator()(VM vm, Out result) {
      std::string nativeStr =
        std::string("/tmp/temp-") + vm->genUUID().toString();
      auto nresult = toUTF<nchar>(makeLString(nativeStr.c_str(),
                                              nativeStr.size()));

      result = Atom::build(vm, nresult.length, nresult.string);
    }
  };

  class Fopen: public Builtin<Fopen> {
  public:
    Fopen(): Builtin("fopen") {}

    void operator()(VM vm, In fileName, In mode, Out result) {
      size_t fileNameBufSize = ozVSLengthForBuffer(vm, fileName);
      size_t modeBufSize = ozVSLengthForBuffer(vm, mode);

      std::FILE* file;
      {
        std::vector<char> strFileName, strMode;
        ozVSGetNullTerminated(vm, fileName, fileNameBufSize, strFileName);
        ozVSGetNullTerminated(vm, mode, modeBufSize, strMode);

        file = std::fopen(strFileName.data(), strMode.data());
      }

      if (file == nullptr)
        raiseLastOSError(vm, MOZART_STR("fopen"));

      result = build(vm, std::make_shared<WrappedFile>(file));
    }
  };

  class Fread: public Builtin<Fread> {
  public:
    Fread(): Builtin("fread") {}

    void operator()(VM vm, In fileNode, In count, In end,
                    Out actualCount, Out result) {
      auto file = getFileArgument(vm, fileNode)->file();
      auto intCount = getArgument<nativeint>(vm, count);

      if (intCount <= 0) {
        actualCount = build(vm, 0);
        result.copy(vm, end);
        return;
      }

      size_t bufferSize = std::min((size_t) intCount, MaxBufferSize);
      void* buffer = vm->malloc(bufferSize);

      size_t readCount = std::fread(buffer, 1, bufferSize, file);

      if ((readCount < bufferSize) && std::ferror(file)) {
        // error
        vm->free(buffer, bufferSize);
        raiseLastOSError(vm, MOZART_STR("fread"));
      }

      char* charBuffer = static_cast<char*>(buffer);

      UnstableNode res(vm, end);
      for (size_t i = readCount; i > 0; i--)
        res = buildCons(vm, charBuffer[i-1], std::move(res));

      vm->free(buffer, bufferSize);

      actualCount = build(vm, readCount);
      result = std::move(res);
    }
  };

  class Fwrite: public Builtin<Fwrite> {
  public:
    Fwrite(): Builtin("fwrite") {}

    void operator()(VM vm, In fileNode, In data, Out writtenCount) {
      auto file = getFileArgument(vm, fileNode)->file();
      size_t bufSize = ozVBSLengthForBuffer(vm, data);

      if (bufSize == 0) {
        writtenCount = build(vm, 0);
        return;
      }

      size_t writtenSize;
      {
        std::vector<char> buffer;
        ozVBSGet(vm, data, bufSize, buffer);
        bufSize = buffer.size();

        writtenSize = std::fwrite(buffer.data(), 1, bufSize, file);
      }

      if (writtenSize != bufSize)
        raiseLastOSError(vm, MOZART_STR("fwrite"));

      writtenCount = build(vm, writtenSize);
    }
  };

  class Fseek: public Builtin<Fseek> {
  public:
    Fseek(): Builtin("fseek") {}

    void operator()(VM vm, In fileNode, In offset, In whence, Out where) {
      using namespace patternmatching;

      auto file = getFileArgument(vm, fileNode)->file();
      auto intOffset = getArgument<nativeint>(vm, offset);

      int intWhence;
      if (matches(vm, whence, MOZART_STR("SEEK_SET"))) {
        intWhence = SEEK_SET;
      } else if (matches(vm, whence, MOZART_STR("SEEK_CUR"))) {
        intWhence = SEEK_CUR;
      } else if (matches(vm, whence, MOZART_STR("SEEK_END"))) {
        intWhence = SEEK_END;
      } else {
        raiseTypeError(
          vm, MOZART_STR("'SEEK_SET', 'SEEK_CUR' or 'SEEK_END'"), whence);
      }

      nativeint seekResult = std::fseek(file, (long) intOffset, intWhence);

      if (seekResult < 0)
        raiseLastOSError(vm, MOZART_STR("fseek"));

      where = build(vm, seekResult);
    }
  };

  class Fclose: public Builtin<Fclose> {
  public:
    Fclose(): Builtin("fclose") {}

    void operator()(VM vm, In fileNode) {
      auto wrappedFile = getFileArgument(vm, fileNode);
      wrappedFile->close();
    }
  };

  class Stdin: public Builtin<Stdin> {
  public:
    Stdin(): Builtin("stdin") {}

    void operator()(VM vm, Out result) {
      result = build(vm, std::make_shared<WrappedFile>(stdin));
    }
  };

  class Stdout: public Builtin<Stdout> {
  public:
    Stdout(): Builtin("stdout") {}

    void operator()(VM vm, Out result) {
      result = build(vm, std::make_shared<WrappedFile>(stdout));
    }
  };

  class Stderr: public Builtin<Stderr> {
  public:
    Stderr(): Builtin("stderr") {}

    void operator()(VM vm, Out result) {
      result = build(vm, std::make_shared<WrappedFile>(stderr));
    }
  };

  // Socket I/O

  class TCPAcceptorCreate: public Builtin<TCPAcceptorCreate> {
  public:
    TCPAcceptorCreate(): Builtin("tcpAcceptorCreate") {}

    void operator()(VM vm, In ipVersion, In port, Out result) {
      using boost::asio::ip::tcp;

      auto intIPVersion = getArgument<nativeint>(vm, ipVersion,
                                                 MOZART_STR("4 or 6"));
      if ((intIPVersion != 4) && (intIPVersion != 6))
        raiseTypeError(vm, MOZART_STR("4 or 6"), ipVersion);

      auto intPort = getArgument<nativeint>(vm, port,
                                            MOZART_STR("valid port number"));
      if ((intPort <= 0) ||
          (intPort > std::numeric_limits<unsigned short>::max()))
        raiseTypeError(vm, MOZART_STR("valid port number"), port);

      tcp::endpoint endpoint;
      if (intIPVersion == 4)
        endpoint = tcp::endpoint(tcp::v4(), intPort);
      else
        endpoint = tcp::endpoint(tcp::v6(), intPort);

      try {
        auto acceptor = TCPAcceptor::create(BoostBasedVM::forVM(vm), endpoint);
        result = build(vm, acceptor);
      } catch (const boost::system::system_error& error) {
        raiseOSError(vm, MOZART_STR("tcpAcceptorCreate"), error);
      }
    }
  };

  class TCPAccept: public Builtin<TCPAccept> {
  public:
    TCPAccept(): Builtin("tcpAccept") {}

    void operator()(VM vm, In acceptor, Out result) {
      auto tcpAcceptor = getPointerArgument<TCPAcceptor>(
        vm, acceptor, MOZART_STR("TCP acceptor"));

      auto connectionNode =
        BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(result);

      tcpAcceptor->startAsyncAccept(connectionNode);
    }
  };

  class TCPCancelAccept: public Builtin<TCPCancelAccept> {
  public:
    TCPCancelAccept(): Builtin("tcpCancelAccept") {}

    void operator()(VM vm, In acceptor) {
      auto tcpAcceptor = getPointerArgument<TCPAcceptor>(
        vm, acceptor, MOZART_STR("TCP acceptor"));

      auto error = tcpAcceptor->cancel();
      if (!error)
        raiseOSError(vm, MOZART_STR("cancel"), error);
    }
  };

  class TCPAcceptorClose: public Builtin<TCPAcceptorClose> {
  public:
    TCPAcceptorClose(): Builtin("tcpAcceptorClose") {}

    void operator()(VM vm, In acceptor) {
      auto tcpAcceptor = getPointerArgument<TCPAcceptor>(
        vm, acceptor, MOZART_STR("TCP acceptor"));

      auto error = tcpAcceptor->close();
      if (error)
        raiseOSError(vm, MOZART_STR("close"), error);
    }
  };

  class TCPConnect: public Builtin<TCPConnect> {
  public:
    TCPConnect(): Builtin("tcpConnect") {}

    void operator()(VM vm, In host, In service, Out status) {
      size_t hostBufSize = ozVSLengthForBuffer(vm, host);
      size_t serviceBufSize = ozVSLengthForBuffer(vm, service);

      {
        std::string strHost, strService;
        ozVSGet(vm, host, hostBufSize, strHost);
        ozVSGet(vm, service, serviceBufSize, strService);

        auto tcpConnection = TCPConnection::create(BoostBasedVM::forVM(vm));

        auto statusNode =
          BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(status);

        tcpConnection->startAsyncConnect(strHost, strService, statusNode);
      }
    }
  };

  class TCPConnectionRead: public Builtin<TCPConnectionRead> {
  public:
    TCPConnectionRead(): Builtin("tcpConnectionRead") {}

    void operator()(VM vm, In connection, In count, In tail, Out status) {
      // Fetch the TCP connection
      auto tcpConnection = getPointerArgument<TCPConnection>(
        vm, connection, MOZART_STR("TCP connection"));

      // Fetch the count
      auto intCount = getArgument<nativeint>(vm, count);

      // 0 size
      if (intCount <= 0) {
        status = buildTuple(vm, MOZART_STR("succeeded"), 0, tail);
        return;
      }

      // Resize the buffer
      size_t size = (size_t) intCount;
      tcpConnection->getReadData().resize(size);

      auto& env = BoostBasedVM::forVM(vm);

      auto tailNode = env.allocAsyncIONode(tail.getStableRef(vm));
      auto statusNode = env.createAsyncIOFeedbackNode(status);

      tcpConnection->startAsyncReadSome(tailNode, statusNode);
    }
  };

  class TCPConnectionWrite: public Builtin<TCPConnectionWrite> {
  public:
    TCPConnectionWrite(): Builtin("tcpConnectionWrite") {}

    void operator()(VM vm, In connection, In data, Out status) {
      // Fetch the TCP connection
      auto tcpConnection = getPointerArgument<TCPConnection>(
        vm, connection, MOZART_STR("TCP connection"));

      size_t bufSize = ozVBSLengthForBuffer(vm, data);

      // 0 size
      if (bufSize == 0) {
        status = build(vm, 0);
        return;
      }

      // Fetch the data to write
      tcpConnection->getWriteData().clear();
      ozVBSGet(vm, data, bufSize, tcpConnection->getWriteData());

      auto statusNode =
        BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(status);

      tcpConnection->startAsyncWrite(statusNode);
    }
  };

  class TCPConnectionShutdown: public Builtin<TCPConnectionShutdown> {
  public:
    TCPConnectionShutdown(): Builtin("tcpConnectionShutdown") {}

    void operator()(VM vm, In connection, In what) {
      using namespace patternmatching;
      using boost::asio::ip::tcp;

      // Fetch the TCP connection
      auto tcpConnection = getPointerArgument<TCPConnection>(
        vm, connection, MOZART_STR("TCP connection"));

      // Fetch what channels must be shut down
      tcp::socket::shutdown_type whatValue;
      if (matches(vm, what, MOZART_STR("receive"))) {
        whatValue = tcp::socket::shutdown_receive;
      } else if (matches(vm, what, MOZART_STR("send"))) {
        whatValue = tcp::socket::shutdown_send;
      } else if (matches(vm, what, MOZART_STR("both"))) {
        whatValue = tcp::socket::shutdown_both;
      } else {
        raiseTypeError(vm, MOZART_STR("'receive', 'send' or 'both'"), what);
      }

      try {
        tcpConnection->socket().shutdown(whatValue);
      } catch (const boost::system::system_error& error) {
        raiseOSError(vm, MOZART_STR("shutdown"), error);
      }
    }
  };

  class TCPConnectionClose: public Builtin<TCPConnectionClose> {
  public:
    TCPConnectionClose(): Builtin("tcpConnectionClose") {}

    void operator()(VM vm, In connection) {
      using boost::asio::ip::tcp;

      // Fetch the TCP connection
      auto tcpConnection = getPointerArgument<TCPConnection>(
        vm, connection, MOZART_STR("TCP connection"));

      try {
        tcpConnection->socket().shutdown(tcp::socket::shutdown_both);
        tcpConnection->socket().close();
      } catch (const boost::system::system_error& error) {
        raiseOSError(vm, MOZART_STR("close"), error);
      }
    }
  };
};

}

} }

#endif // MOZART_GENERATOR

#endif // __MODOSBOOST_H
