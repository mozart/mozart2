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
      auto intSeed = getArgument<nativeint>(vm, seed, MOZART_STR("integer"));

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
      auto strVar = vsToString<char>(vm, var);
      auto value = std::getenv(strVar.c_str());

      if (value == nullptr)
        result = build(vm, false);
      else
        result = build(vm, value);
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
      auto strFileName = ozStringToStdString(vm, fileName);
      auto strMode = ozStringToStdString(vm, mode);

      std::FILE* file = std::fopen(strFileName.c_str(), strMode.c_str());
      if (file == nullptr)
        raiseLastOSError(vm);

      result = build(vm, std::make_shared<WrappedFile>(file));
    }
  };

  class Fread: public Builtin<Fread> {
  public:
    Fread(): Builtin("fread") {}

    void operator()(VM vm, In fileNode, In count, In end,
                    Out actualCount, Out result) {
      auto file = getFileArgument(vm, fileNode)->file();
      auto intCount = getArgument<nativeint>(vm, count, MOZART_STR("integer"));

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
        raise(vm, MOZART_STR("system"), MOZART_STR("fread"));
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
      size_t size = ozListLength(vm, data);

      if (size == 0)
        return;

      void* buffer = vm->malloc(size);
      ozStringToBuffer(vm, data, size, static_cast<char*>(buffer));

      if (std::fwrite(buffer, 1, size, file) != size)
        raiseLastOSError(vm);

      writtenCount = build(vm, size);
    }
  };

  class Fseek: public Builtin<Fseek> {
  public:
    Fseek(): Builtin("fseek") {}

    void operator()(VM vm, In fileNode, In offset, In whence, Out where) {
      using namespace patternmatching;

      auto file = getFileArgument(vm, fileNode)->file();
      auto intOffset = getArgument<nativeint>(vm, offset, MOZART_STR("integer"));

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
        raiseLastOSError(vm);

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
        raiseSystemError(vm, error);
      }
    }
  };

  class TCPAccept: public Builtin<TCPAccept> {
  public:
    TCPAccept(): Builtin("tcpAccept") {}

    void operator()(VM vm, In acceptor, Out result) {
      auto tcpAcceptor = getArgument<std::shared_ptr<TCPAcceptor> >(
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
      auto tcpAcceptor = getArgument<std::shared_ptr<TCPAcceptor> >(
        vm, acceptor, MOZART_STR("TCP acceptor"));

      auto error = tcpAcceptor->cancel();
      if (!error)
        raise(vm, MOZART_STR("system"), MOZART_STR("cancel"), error.value());
    }
  };

  class TCPAcceptorClose: public Builtin<TCPAcceptorClose> {
  public:
    TCPAcceptorClose(): Builtin("tcpAcceptorClose") {}

    void operator()(VM vm, In acceptor) {
      auto tcpAcceptor = getArgument<std::shared_ptr<TCPAcceptor> >(
        vm, acceptor, MOZART_STR("TCP acceptor"));

      auto error = tcpAcceptor->close();
      if (error)
        raise(vm, MOZART_STR("system"), MOZART_STR("close"), error.value());
    }
  };

  class TCPConnect: public Builtin<TCPConnect> {
  public:
    TCPConnect(): Builtin("tcpConnect") {}

    void operator()(VM vm, In host, In service, Out status) {
      auto strHost = ozStringToStdString(vm, host);
      auto strService = ozStringToStdString(vm, service);

      auto tcpConnection = TCPConnection::create(BoostBasedVM::forVM(vm));

      auto statusNode =
        BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(status);

      tcpConnection->startAsyncConnect(strHost, strService, statusNode);
    }
  };

  class TCPConnectionRead: public Builtin<TCPConnectionRead> {
  public:
    TCPConnectionRead(): Builtin("tcpConnectionRead") {}

    void operator()(VM vm, In connection, In count, In tail, Out status) {
      // Fetch the TCP connection
      auto tcpConnection = getArgument<std::shared_ptr<TCPConnection> >(
        vm, connection, MOZART_STR("TCP connection"));

      // Fetch the count
      auto intCount = getArgument<nativeint>(vm, count, MOZART_STR("integer"));

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
      auto tcpConnection = getArgument<std::shared_ptr<TCPConnection> >(
        vm, connection, MOZART_STR("TCP connection"));

      // Fetch the data to write
      ozStringToBuffer(vm, data, tcpConnection->getWriteData());

      // 0 size
      if (tcpConnection->getWriteData().size() == 0) {
        status = build(vm, 0);
        return;
      }

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
      auto tcpConnection = getArgument<std::shared_ptr<TCPConnection> >(
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
        raiseSystemError(vm, error);
      }
    }
  };

  class TCPConnectionClose: public Builtin<TCPConnectionClose> {
  public:
    TCPConnectionClose(): Builtin("tcpConnectionClose") {}

    void operator()(VM vm, In connection) {
      using boost::asio::ip::tcp;

      // Fetch the TCP connection
      auto tcpConnection = getArgument<std::shared_ptr<TCPConnection> >(
        vm, connection, MOZART_STR("TCP connection"));

      try {
        tcpConnection->socket().shutdown(tcp::socket::shutdown_both);
        tcpConnection->socket().close();
      } catch (const boost::system::system_error& error) {
        raiseSystemError(vm, error);
      }
    }
  };
};

}

} }

#endif // MOZART_GENERATOR

#endif // __MODOSBOOST_H
