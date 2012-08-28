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
#include "boostenvdatatypes-decl.hh"

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
      result = SmallInt::build(vm, BoostBasedVM::forVM(vm).random_generator());
    }
  };

  class Srand: public Builtin<Srand> {
  public:
    Srand(): Builtin("srand") {}

    void operator()(VM vm, In seed) {
      nativeint intSeed;
      getArgument(vm, intSeed, seed, MOZART_STR("integer"));

      BoostBasedVM::forVM(vm).random_generator.seed(
        (BoostBasedVM::random_generator_t::result_type) intSeed);
    }
  };

  class RandLimits: public Builtin<RandLimits> {
  public:
    RandLimits(): Builtin("randLimits") {}

    void operator()(VM vm, Out min, Out max) {
      min = SmallInt::build(vm, BoostBasedVM::random_generator_t::min());
      max = SmallInt::build(vm, BoostBasedVM::random_generator_t::max());
    }
  };

  // Environment

  class GetEnv: public Builtin<GetEnv> {
  public:
    GetEnv(): Builtin("getEnv") {}

    void operator()(VM vm, In var, Out result) {
      std::string strVar;
      vsToString(vm, var, strVar);

      auto value = std::getenv(strVar.c_str());

      if (value == nullptr)
        result = build(vm, false);
      else
        result = build(vm, value);
    }
  };

  // File I/O

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
      std::string strFileName, strMode;
      ozStringToStdString(vm, fileName, strFileName);
      ozStringToStdString(vm, mode, strMode);

      std::FILE* file = std::fopen(strFileName.c_str(), strMode.c_str());
      if (file == nullptr)
        return raiseLastOSError(vm);

      result = build(vm, BoostBasedVM::forVM(vm).registerFile(file));
    }
  };

  class Fread: public Builtin<Fread> {
  public:
    Fread(): Builtin("fread") {}

    void operator()(VM vm, In fd, In count, In end,
                    Out actualCount, Out result) {
      std::FILE* file = nullptr;
      BoostBasedVM::forVM(vm).getFile(fd, file);

      nativeint intCount;
      getArgument(vm, intCount, count, MOZART_STR("integer"));

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
        return raise(vm, MOZART_STR("system"), MOZART_STR("fread"));
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

    void operator()(VM vm, In fd, In data, Out writtenCount) {
      std::FILE* file = nullptr;
      BoostBasedVM::forVM(vm).getFile(fd, file);

      size_t size = 0;
      ozListLength(vm, data, size);

      if (size == 0)
        return;

      void* buffer = vm->malloc(size);
      ozStringToBuffer(vm, data, size, static_cast<char*>(buffer));

      if (std::fwrite(buffer, 1, size, file) != size)
        return raiseLastOSError(vm);

      writtenCount = build(vm, size);
    }
  };

  class Fseek: public Builtin<Fseek> {
  public:
    Fseek(): Builtin("fseek") {}

    void operator()(VM vm, In fd, In offset, In whence, Out where) {
      using namespace patternmatching;

      std::FILE* file = nullptr;
      BoostBasedVM::forVM(vm).getFile(fd, file);

      nativeint intOffset;
      getArgument(vm, intOffset, offset, MOZART_STR("integer"));

      int intWhence;
      if (matches(vm, whence, MOZART_STR("SEEK_SET"))) {
        intWhence = SEEK_SET;
      } else if (matches(vm, whence, MOZART_STR("SEEK_CUR"))) {
        intWhence = SEEK_CUR;
      } else if (matches(vm, whence, MOZART_STR("SEEK_END"))) {
        intWhence = SEEK_END;
      } else {
        return raiseTypeError(
          vm, MOZART_STR("'SEEK_SET', 'SEEK_CUR' or 'SEEK_END'"), whence);
      }

      auto seekResult = std::fseek(file, (long) intOffset, intWhence);

      if (seekResult < 0)
        return raiseLastOSError(vm);

      where = SmallInt::build(vm, seekResult);
    }
  };

  class Fclose: public Builtin<Fclose> {
  public:
    Fclose(): Builtin("fclose") {}

    void operator()(VM vm, In fd) {
      BoostBasedVM& env = BoostBasedVM::forVM(vm);

      nativeint intfd = 0;
      getArgument(vm, intfd, fd, MOZART_STR("filedesc"));

      // Never actually close standard I/O
      if ((intfd == env.fdStdin) || (intfd == env.fdStdout) ||
          (intfd == env.fdStderr))
        return;

      std::FILE* file = nullptr;
      env.getFile(intfd, file);

      if (std::fclose(file) != 0)
        return raiseLastOSError(vm);

      env.unregisterFile(intfd);
    }
  };

  class Stdin: public Builtin<Stdin> {
  public:
    Stdin(): Builtin("stdin") {}

    void operator()(VM vm, Out result) {
      result = SmallInt::build(vm, BoostBasedVM::forVM(vm).fdStdin);
    }
  };

  class Stdout: public Builtin<Stdout> {
  public:
    Stdout(): Builtin("stdout") {}

    void operator()(VM vm, Out result) {
      result = SmallInt::build(vm, BoostBasedVM::forVM(vm).fdStdout);
    }
  };

  class Stderr: public Builtin<Stderr> {
  public:
    Stderr(): Builtin("stderr") {}

    void operator()(VM vm, Out result) {
      result = SmallInt::build(vm, BoostBasedVM::forVM(vm).fdStderr);
    }
  };

  // Socket I/O

  class TCPAcceptorCreate: public Builtin<TCPAcceptorCreate> {
  public:
    TCPAcceptorCreate(): Builtin("tcpAcceptorCreate") {}

    void operator()(VM vm, In ipVersion, In port, Out result) {
      using boost::asio::ip::tcp;

      nativeint intIPVersion, intPort;

      getArgument(vm, intIPVersion, ipVersion, MOZART_STR("4 or 6"));
      if ((intIPVersion != 4) && (intIPVersion != 6))
        return raiseTypeError(vm, MOZART_STR("4 or 6"), ipVersion);

      getArgument(vm, intPort, port, MOZART_STR("valid port number"));
      if ((intPort <= 0) ||
          (intPort > std::numeric_limits<unsigned short>::max()))
        return raiseTypeError(vm, MOZART_STR("valid port number"), port);

      tcp::endpoint endpoint;
      if (intIPVersion == 4)
        endpoint = tcp::endpoint(tcp::v4(), intPort);
      else
        endpoint = tcp::endpoint(tcp::v6(), intPort);

      try {
        auto acceptor = TCPAcceptor::create(BoostBasedVM::forVM(vm), endpoint);
        result = OzTCPAcceptor::build(vm, acceptor);
      } catch (const boost::system::system_error& error) {
        raiseSystemError(vm, error);
      }
    }
  };

  class TCPAccept: public Builtin<TCPAccept> {
  public:
    TCPAccept(): Builtin("tcpAccept") {}

    void operator()(VM vm, In acceptor, Out result) {
      std::shared_ptr<TCPAcceptor> tcpAcceptor;
      getArgument(vm, tcpAcceptor, acceptor, MOZART_STR("TCP acceptor"));

      StableNode** connectionNode;
      BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(connectionNode, result);

      tcpAcceptor->startAsyncAccept(connectionNode);
    }
  };

  class TCPCancelAccept: public Builtin<TCPCancelAccept> {
  public:
    TCPCancelAccept(): Builtin("tcpCancelAccept") {}

    void operator()(VM vm, In acceptor) {
      std::shared_ptr<TCPAcceptor> tcpAcceptor;
      getArgument(vm, tcpAcceptor, acceptor, MOZART_STR("TCP acceptor"));

      auto error = tcpAcceptor->cancel();
      if (!error)
        return raise(vm, MOZART_STR("system"),
                     MOZART_STR("cancel"), error.value());
    }
  };

  class TCPAcceptorClose: public Builtin<TCPAcceptorClose> {
  public:
    TCPAcceptorClose(): Builtin("tcpAcceptorClose") {}

    void operator()(VM vm, In acceptor) {
      std::shared_ptr<TCPAcceptor> tcpAcceptor;
      getArgument(vm, tcpAcceptor, acceptor, MOZART_STR("TCP acceptor"));

      auto error = tcpAcceptor->close();
      if (error)
        return raise(vm, MOZART_STR("system"),
                     MOZART_STR("close"), error.value());
    }
  };

  class TCPConnect: public Builtin<TCPConnect> {
  public:
    TCPConnect(): Builtin("tcpConnect") {}

    void operator()(VM vm, In host, In service, Out status) {
      std::string strHost, strService;
      ozStringToStdString(vm, host, strHost);
      ozStringToStdString(vm, service, strService);

      auto tcpConnection = TCPConnection::create(BoostBasedVM::forVM(vm));

      StableNode** statusNode;
      BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(statusNode, status);

      tcpConnection->startAsyncConnect(strHost, strService, statusNode);
    }
  };

  class TCPConnectionRead: public Builtin<TCPConnectionRead> {
  public:
    TCPConnectionRead(): Builtin("tcpConnectionRead") {}

    void operator()(VM vm, In connection, In count, In tail, Out status) {
      // Fetch the TCP connection
      std::shared_ptr<TCPConnection> tcpConnection;
      getArgument(vm, tcpConnection, connection, MOZART_STR("TCP connection"));

      // Fetch the count
      nativeint intCount;
      getArgument(vm, intCount, count, MOZART_STR("integer"));

      // 0 size
      if (intCount <= 0) {
        status = buildTuple(vm, MOZART_STR("succeeded"), 0, tail);
        return;
      }

      // Resize the buffer
      size_t size = (size_t) intCount;
      tcpConnection->getReadData().resize(size);

      auto& env = BoostBasedVM::forVM(vm);

      StableNode** tailNode = env.allocAsyncIONode(tail.getStableRef(vm));
      StableNode** statusNode;
      env.createAsyncIOFeedbackNode(statusNode, status);

      tcpConnection->startAsyncReadSome(tailNode, statusNode);
    }
  };

  class TCPConnectionWrite: public Builtin<TCPConnectionWrite> {
  public:
    TCPConnectionWrite(): Builtin("tcpConnectionWrite") {}

    void operator()(VM vm, In connection, In data, Out status) {
      // Fetch the TCP connection
      std::shared_ptr<TCPConnection> tcpConnection;
      getArgument(vm, tcpConnection, connection, MOZART_STR("TCP connection"));

      // Fetch the data to write
      ozStringToBuffer(vm, data, tcpConnection->getWriteData());

      // 0 size
      if (tcpConnection->getWriteData().size() == 0) {
        status = build(vm, 0);
        return;
      }

      StableNode** statusNode;
      BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(statusNode, status);

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
      std::shared_ptr<TCPConnection> tcpConnection;
      getArgument(vm, tcpConnection, connection, MOZART_STR("TCP connection"));

      // Fetch what channels must be shut down
      tcp::socket::shutdown_type whatValue;
      if (matches(vm, what, MOZART_STR("receive"))) {
        whatValue = tcp::socket::shutdown_receive;
      } else if (matches(vm, what, MOZART_STR("send"))) {
        whatValue = tcp::socket::shutdown_send;
      } else if (matches(vm, what, MOZART_STR("both"))) {
        whatValue = tcp::socket::shutdown_both;
      } else {
        return raiseTypeError(
          vm, MOZART_STR("'receive', 'send' or 'both'"), what);
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
      std::shared_ptr<TCPConnection> tcpConnection;
      getArgument(vm, tcpConnection, connection, MOZART_STR("TCP connection"));

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
