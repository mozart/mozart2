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
      MOZART_GET_ARG(intSeed, seed, MOZART_STR("integer"));

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

      result = build(vm, BoostBasedVM::forVM(vm).registerFile(file));
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
      MOZART_GET_ARG(intCount, count, MOZART_STR("integer"));

      if (intCount <= 0) {
        actualCount = build(vm, 0);
        result.copy(vm, end);
        return OpResult::proceed();
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

      writtenCount = build(vm, size);
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
      MOZART_GET_ARG(intOffset, offset, MOZART_STR("integer"));

      int intWhence;
      OpResult res = OpResult::proceed();
      if (matches(vm, res, whence, MOZART_STR("SEEK_SET"))) {
        intWhence = SEEK_SET;
      } else if (matches(vm, res, whence, MOZART_STR("SEEK_CUR"))) {
        intWhence = SEEK_CUR;
      } else if (matches(vm, res, whence, MOZART_STR("SEEK_END"))) {
        intWhence = SEEK_END;
      } else {
        return matchTypeError(
          vm, res, whence, MOZART_STR("'SEEK_SET', 'SEEK_CUR' or 'SEEK_END'"));
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
      MOZART_GET_ARG(intfd, fd, MOZART_STR("filedesc"));

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

  // Socket I/O

  class TCPAcceptorCreate: public Builtin<TCPAcceptorCreate> {
  public:
    TCPAcceptorCreate(): Builtin("tcpAcceptorCreate") {}

    OpResult operator()(VM vm, In ipVersion, In port, Out result) {
      using boost::asio::ip::tcp;

      nativeint intIPVersion, intPort;

      MOZART_GET_ARG(intIPVersion, ipVersion, MOZART_STR("4 or 6"));
      if ((intIPVersion != 4) && (intIPVersion != 6))
        return raiseTypeError(vm, MOZART_STR("4 or 6"), ipVersion);

      MOZART_GET_ARG(intPort, port, MOZART_STR("valid port number"));
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
        return OpResult::proceed();
      } catch (const boost::system::system_error& error) {
        return raiseSystemError(vm, error);
      }
    }
  };

  class TCPAccept: public Builtin<TCPAccept> {
  public:
    TCPAccept(): Builtin("tcpAccept") {}

    OpResult operator()(VM vm, In acceptor, Out result) {
      std::shared_ptr<TCPAcceptor> tcpAcceptor;
      MOZART_GET_ARG(tcpAcceptor, acceptor, MOZART_STR("TCP acceptor"));

      StableNode** connectionNode;
      BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(connectionNode, result);

      tcpAcceptor->startAsyncAccept(connectionNode);

      return OpResult::proceed();
    }
  };

  class TCPCancelAccept: public Builtin<TCPCancelAccept> {
  public:
    TCPCancelAccept(): Builtin("tcpCancelAccept") {}

    OpResult operator()(VM vm, In acceptor) {
      std::shared_ptr<TCPAcceptor> tcpAcceptor;
      MOZART_GET_ARG(tcpAcceptor, acceptor, MOZART_STR("TCP acceptor"));

      auto error = tcpAcceptor->cancel();
      if (!error)
        return raise(vm, MOZART_STR("system"),
                     MOZART_STR("cancel"), error.value());

      return OpResult::proceed();
    }
  };

  class TCPAcceptorClose: public Builtin<TCPAcceptorClose> {
  public:
    TCPAcceptorClose(): Builtin("tcpAcceptorClose") {}

    OpResult operator()(VM vm, In acceptor) {
      std::shared_ptr<TCPAcceptor> tcpAcceptor;
      MOZART_GET_ARG(tcpAcceptor, acceptor, MOZART_STR("TCP acceptor"));

      auto error = tcpAcceptor->close();
      if (error)
        return raise(vm, MOZART_STR("system"),
                     MOZART_STR("close"), error.value());

      return OpResult::proceed();
    }
  };

  class TCPConnect: public Builtin<TCPConnect> {
  public:
    TCPConnect(): Builtin("tcpConnect") {}

    OpResult operator()(VM vm, In host, In service, Out status) {
      std::string strHost, strService;
      MOZART_CHECK_OPRESULT(ozStringToStdString(vm, host, strHost));
      MOZART_CHECK_OPRESULT(ozStringToStdString(vm, service, strService));

      auto tcpConnection = TCPConnection::create(BoostBasedVM::forVM(vm));

      StableNode** statusNode;
      BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(statusNode, status);

      tcpConnection->startAsyncConnect(strHost, strService, statusNode);

      return OpResult::proceed();
    }
  };

  class TCPConnectionRead: public Builtin<TCPConnectionRead> {
  public:
    TCPConnectionRead(): Builtin("tcpConnectionRead") {}

    OpResult operator()(VM vm, In connection, In count, In tail, Out status) {
      // Fetch the TCP connection
      std::shared_ptr<TCPConnection> tcpConnection;
      MOZART_GET_ARG(tcpConnection, connection, MOZART_STR("TCP connection"));

      // Fetch the count
      nativeint intCount;
      MOZART_GET_ARG(intCount, count, MOZART_STR("integer"));

      // 0 size
      if (intCount <= 0) {
        status = buildTuple(vm, MOZART_STR("succeeded"), 0, tail);
        return OpResult::proceed();
      }

      // Resize the buffer
      size_t size = (size_t) intCount;
      tcpConnection->getReadData().resize(size);

      auto& env = BoostBasedVM::forVM(vm);

      StableNode** tailNode = env.allocAsyncIONode(tail.getStableRef(vm));
      StableNode** statusNode;
      env.createAsyncIOFeedbackNode(statusNode, status);

      tcpConnection->startAsyncRead(tailNode, statusNode);

      return OpResult::proceed();
    }
  };

  class TCPConnectionWrite: public Builtin<TCPConnectionWrite> {
  public:
    TCPConnectionWrite(): Builtin("tcpConnectionWrite") {}

    OpResult operator()(VM vm, In connection, In data, Out status) {
      // Fetch the TCP connection
      std::shared_ptr<TCPConnection> tcpConnection;
      MOZART_GET_ARG(tcpConnection, connection, MOZART_STR("TCP connection"));

      // Fetch the data to write
      MOZART_CHECK_OPRESULT(ozStringToBuffer(
        vm, data, tcpConnection->getWriteData()));

      // 0 size
      if (tcpConnection->getWriteData().size() == 0) {
        status = build(vm, 0);
        return OpResult::proceed();
      }

      StableNode** statusNode;
      BoostBasedVM::forVM(vm).createAsyncIOFeedbackNode(statusNode, status);

      tcpConnection->startAsyncWrite(statusNode);

      return OpResult::proceed();
    }
  };

  class TCPConnectionShutdown: public Builtin<TCPConnectionShutdown> {
  public:
    TCPConnectionShutdown(): Builtin("tcpConnectionShutdown") {}

    OpResult operator()(VM vm, In connection, In what) {
      using namespace patternmatching;
      using boost::asio::ip::tcp;

      // Fetch the TCP connection
      std::shared_ptr<TCPConnection> tcpConnection;
      MOZART_GET_ARG(tcpConnection, connection, MOZART_STR("TCP connection"));

      // Fetch what channels must be shut down
      OpResult res = OpResult::proceed();
      tcp::socket::shutdown_type whatValue;
      if (matches(vm, res, what, MOZART_STR("receive"))) {
        whatValue = tcp::socket::shutdown_receive;
      } else if (matches(vm, res, what, MOZART_STR("send"))) {
        whatValue = tcp::socket::shutdown_send;
      } else if (matches(vm, res, what, MOZART_STR("both"))) {
        whatValue = tcp::socket::shutdown_both;
      } else {
        return matchTypeError(
          vm, res, what, MOZART_STR("'receive', 'send' or 'both'"));
      }

      try {
        tcpConnection->socket().shutdown(whatValue);
        return OpResult::proceed();
      } catch (const boost::system::system_error& error) {
        return raiseSystemError(vm, error);
      }
    }
  };

  class TCPConnectionClose: public Builtin<TCPConnectionClose> {
  public:
    TCPConnectionClose(): Builtin("tcpConnectionClose") {}

    OpResult operator()(VM vm, In connection) {
      using boost::asio::ip::tcp;

      // Fetch the TCP connection
      std::shared_ptr<TCPConnection> tcpConnection;
      MOZART_GET_ARG(tcpConnection, connection, MOZART_STR("TCP connection"));

      try {
        tcpConnection->socket().shutdown(tcp::socket::shutdown_both);
        tcpConnection->socket().close();
        return OpResult::proceed();
      } catch (const boost::system::system_error& error) {
        return raiseSystemError(vm, error);
      }
    }
  };
};

}

} }

#endif // MOZART_GENERATOR

#endif // __MODOSBOOST_H
