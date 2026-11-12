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

#ifndef MOZART_MODOSBOOST_H
#define MOZART_MODOSBOOST_H

#include <mozart.hh>

#include "boostenv-decl.hh"
#include "boostenvtcp-decl.hh"
#include "boostenvpipe-decl.hh"

#include <iostream>

#include <boost/filesystem.hpp>

#ifdef MOZART_WINDOWS
#  include <windows.h>
#else
#  include <unistd.h>
#  include <sys/time.h>
#  include <sys/resource.h>
#  include <sys/utsname.h>
#endif

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

  static BoostEnvironment& env(VM vm) {
    return BoostEnvironment::forVM(vm);
  }

  static VMIdentifier ident(VM vm) {
    return BoostVM::forVM(vm).identifier;
  }

public:
  ModOS(): Module("OS") {}

  // Bootstrap

  class BootURLLoad: public Builtin<BootURLLoad> {
  public:
    BootURLLoad(): Builtin("bootURLLoad") {}

    static void call(VM vm, In url, Out result) {
      size_t urlBufSize = ozVSLengthForBuffer(vm, url);

      bool ok;
      {
        std::string urlString;
        ozVSGet(vm, url, urlBufSize, urlString);

        auto& bootLoader = BoostEnvironment::forVM(vm).bootLoader;
        ok = bootLoader && bootLoader(vm, urlString, result);
      }

      if (!ok)
        raiseOSError(vm, "bootURLLoad", 1, "panic: cannot open boot URL");
    }
  };

  // Random number generation

  class Rand: public Builtin<Rand> {
  public:
    Rand(): Builtin("rand") {}

    static void call(VM vm, Out result) {
      result = build(vm, (nativeint) BoostVM::forVM(vm).random_generator());
    }
  };

  class Srand: public Builtin<Srand> {
  public:
    Srand(): Builtin("srand") {}

    static void call(VM vm, In seed) {
      auto intSeed = getArgument<nativeint>(vm, seed);

      BoostVM::forVM(vm).random_generator.seed(
        (BoostVM::random_generator_t::result_type) intSeed);
    }
  };

  class RandLimits: public Builtin<RandLimits> {
  public:
    RandLimits(): Builtin("randLimits") {}

    static void call(VM vm, Out min, Out max) {
      min = build(vm, (nativeint) BoostVM::random_generator_t::min());
      max = build(vm, (nativeint) BoostVM::random_generator_t::max());
    }
  };

  // Environment

  class GetEnv: public Builtin<GetEnv> {
  public:
    GetEnv(): Builtin("getEnv") {}

    static void call(VM vm, In var, Out result) {
      // TODO Unicode on Windows!!!
      size_t bufSize = ozVSLengthForBuffer(vm, var);
      char* value;

      {
        std::vector<char> varVector;
        ozVSGetNullTerminated(vm, var, bufSize, varVector);

        BoostEnvironment::forVM(vm).withProtectedEnvironmentVariables([&] {
          value = std::getenv(varVector.data());
        });
      }

      if (value == nullptr)
        result = build(vm, false);
      else
        result = build(vm, vm->getAtom(value));
    }
  };

  class PutEnv: public Builtin<PutEnv> {
  public:
    PutEnv(): Builtin("putEnv") {}

    static void call(VM vm, In var, In value) {
      // TODO Unicode on Windows!!!
      size_t varBufSize = ozVSLengthForBuffer(vm, var);
      size_t valueBufSize = ozVSLengthForBuffer(vm, value);

      bool succeeded;

      {
        std::vector<char> varVector, valueVector;
        ozVSGetNullTerminated(vm, var, varBufSize, varVector);
        ozVSGetNullTerminated(vm, value, valueBufSize, valueVector);

        BoostEnvironment::forVM(vm).withProtectedEnvironmentVariables([&] {
#ifdef MOZART_WINDOWS
          succeeded = SetEnvironmentVariable(varVector.data(),
                                           valueVector.data()) != FALSE;
#else
          succeeded = setenv(varVector.data(), valueVector.data(), true) == 0;
#endif
        });
      }

      if (!succeeded)
        raiseOSError(vm, "putenv", 0, "OS.putEnv failed.");
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
    auto wrappedFile = getPointerArgument<WrappedFile>(vm, arg, "file");

    if (wrappedFile->isClosed())
      raiseOSError(vm, "close", 9, "Bad filedescriptor");

    return wrappedFile;
  }

public:
  class GetDir: public Builtin<GetDir> {
  public:
    GetDir(): Builtin("getDir") {}

    static void call(VM vm, In directory, Out result) {
      using namespace boost::filesystem;

      size_t dirBufSize = ozVSLengthForBuffer(vm, directory);

      directory_iterator iter;
      boost::system::error_code ec;
      {
        path::string_type strDirectory;
        ozVSGet(vm, directory, dirBufSize, strDirectory);

        path pathDirectory(strDirectory);
        iter = directory_iterator(pathDirectory, ec);
      }

      if (ec)
        raiseOSError(vm, "getDir", ec);

      {
        OzListBuilder builder(vm);
        for (; iter != directory_iterator(); ++iter) {
          auto nativeFileName = iter->path().filename().native();
          auto mozartFileName = toUTF<char>(
            makeLString(nativeFileName.c_str(), nativeFileName.size()));

          builder.push_back(vm, vm->getAtom(mozartFileName.length,
                                            mozartFileName.string));
        }
        result = builder.get(vm);
      }
    }
  };

  class GetCWD: public Builtin<GetCWD> {
  public:
    GetCWD(): Builtin("getCWD") {}

    static void call(VM vm, Out result) {
      auto nativeStr = boost::filesystem::current_path().native();
      auto nresult = toUTF<char>(makeLString(nativeStr.c_str(),
                                              nativeStr.size()));

      result = Atom::build(vm, nresult.length, nresult.string);
    }
  };

  class ChDir: public Builtin<ChDir> {
  public:
    ChDir(): Builtin("chDir") {}

    static void call(VM vm, In dir) {
      size_t dirBufSize = ozVSLengthForBuffer(vm, dir);
      std::string dirStr;

      ozVSGet(vm, dir, dirBufSize, dirStr);

      boost::system::error_code ec;
      boost::filesystem::current_path(dirStr, ec);
      if (ec) {
        raiseOSError(vm, "chdir", ec);
      }
    }
  };

  class Tmpnam: public Builtin<Tmpnam> {
  public:
    Tmpnam(): Builtin("tmpnam") {}

    static void call(VM vm, Out result) {
      // TODO Windows
      std::string filename =
        std::string("/tmp/temp-") + vm->genUUID().toString();
      result = build(vm, vm->getAtom(filename));
    }
  };

  class Fopen: public Builtin<Fopen> {
  public:
    Fopen(): Builtin("fopen") {}

    static void call(VM vm, In fileName, In mode, Out result) {
      // TODO Unicode on Windows!!!
      size_t fileNameBufSize = ozVSLengthForBuffer(vm, fileName);
      size_t modeBufSize = ozVSLengthForBuffer(vm, mode);

      std::FILE* file;
      {
        std::string strFileName;
        std::vector<char> strMode;
        ozVSGet(vm, fileName, fileNameBufSize, strFileName);
        ozVSGetNullTerminated(vm, mode, modeBufSize, strMode);

        boost::filesystem::path filePath(strFileName);
        file = std::fopen(filePath.make_preferred().string().c_str(),
                          strMode.data());
      }

      if (file == nullptr)
        raiseLastOSError(vm, "fopen");

      result = build(vm, std::make_shared<WrappedFile>(file));
    }
  };

  class Fread: public Builtin<Fread> {
  public:
    Fread(): Builtin("fread") {}

    static void call(VM vm, In fileNode, In count, In end,
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
        raiseLastOSError(vm, "fread");
      }

      char* charBuffer = static_cast<char*>(buffer);

      UnstableNode res(vm, end);
      for (size_t i = readCount; i > 0; i--)
        res = buildCons(vm, (nativeint) (unsigned char) charBuffer[i-1],
                        std::move(res));

      vm->free(buffer, bufferSize);

      actualCount = build(vm, readCount);
      result = std::move(res);
    }
  };

  class Fwrite: public Builtin<Fwrite> {
  public:
    Fwrite(): Builtin("fwrite") {}

    static void call(VM vm, In fileNode, In data, Out writtenCount) {
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
        raiseLastOSError(vm, "fwrite");

      writtenCount = build(vm, writtenSize);
    }
  };

  class Fseek: public Builtin<Fseek> {
  public:
    Fseek(): Builtin("fseek") {}

    static void call(VM vm, In fileNode, In offset, In whence, Out where) {
      using namespace patternmatching;

      auto file = getFileArgument(vm, fileNode)->file();
      auto intOffset = getArgument<nativeint>(vm, offset);

      int intWhence;
      if (matches(vm, whence, "SEEK_SET")) {
        intWhence = SEEK_SET;
      } else if (matches(vm, whence, "SEEK_CUR")) {
        intWhence = SEEK_CUR;
      } else if (matches(vm, whence, "SEEK_END")) {
        intWhence = SEEK_END;
      } else {
        raiseTypeError(
          vm, "'SEEK_SET', 'SEEK_CUR' or 'SEEK_END'", whence);
      }

      nativeint seekResult = std::fseek(file, (long) intOffset, intWhence);

      if (seekResult < 0)
        raiseLastOSError(vm, "fseek");

      where = build(vm, seekResult);
    }
  };

  class Fclose: public Builtin<Fclose> {
  public:
    Fclose(): Builtin("fclose") {}

    static void call(VM vm, In fileNode) {
      auto wrappedFile = getFileArgument(vm, fileNode);
      wrappedFile->close();
    }
  };

  class Stdin: public Builtin<Stdin> {
  public:
    Stdin(): Builtin("stdin") {}

    static void call(VM vm, Out result) {
      result = build(vm, std::make_shared<WrappedFile>(stdin));
    }
  };

  class Stdout: public Builtin<Stdout> {
  public:
    Stdout(): Builtin("stdout") {}

    static void call(VM vm, Out result) {
      result = build(vm, std::make_shared<WrappedFile>(stdout));
    }
  };

  class Stderr: public Builtin<Stderr> {
  public:
    Stderr(): Builtin("stderr") {}

    static void call(VM vm, Out result) {
      result = build(vm, std::make_shared<WrappedFile>(stderr));
    }
  };

  class System: public Builtin<System> {
  public:
    System(): Builtin("system") {}

    static void call(VM vm, In cmd, Out status) {
      size_t cmdBufSize = ozVSLengthForBuffer(vm, cmd);
      std::string cmdStr;

      ozVSGet(vm, cmd, cmdBufSize, cmdStr);
      status = build(vm, system(cmdStr.c_str()));
    }
  };

  // Socket I/O

private:
  static TCPAcceptor* getTCPAcceptorArg(VM vm, In acceptor) {
    return getPointerArgument<TCPAcceptor>(vm, acceptor, "TCP acceptor");
  }

  static TCPConnection* getTCPConnectionArg(VM vm, In connection) {
    return getPointerArgument<TCPConnection>(vm, connection, "TCP connection");
  }

public:
  class TCPAcceptorCreate: public Builtin<TCPAcceptorCreate> {
  public:
    TCPAcceptorCreate(): Builtin("tcpAcceptorCreate") {}

    static void call(VM vm, In ipVersion, In port, Out result) {
      using boost::asio::ip::tcp;

      auto intIPVersion = getArgument<nativeint>(vm, ipVersion, "4 or 6");
      if ((intIPVersion != 4) && (intIPVersion != 6))
        raiseTypeError(vm, "4 or 6", ipVersion);

      auto intPort = getArgument<nativeint>(vm, port, "valid port number");
      if ((intPort <= 0) ||
          (intPort > std::numeric_limits<unsigned short>::max()))
        raiseTypeError(vm, "valid port number", port);

      tcp::endpoint endpoint;
      if (intIPVersion == 4)
        endpoint = tcp::endpoint(tcp::v4(), intPort);
      else
        endpoint = tcp::endpoint(tcp::v6(), intPort);

      try {
        auto acceptor = TCPAcceptor::create(env(vm), ident(vm), endpoint);
        result = build(vm, acceptor);
      } catch (const boost::system::system_error& error) {
        raiseOSError(vm, "tcpAcceptorCreate", error);
      }
    }
  };

  class TCPAccept: public Builtin<TCPAccept> {
  public:
    TCPAccept(): Builtin("tcpAccept") {}

    static void call(VM vm, In acceptor, Out result) {
      auto tcpAcceptor = getTCPAcceptorArg(vm, acceptor);

      auto connectionNode =
        BoostVM::forVM(vm).createAsyncIOFeedbackNode(result);

      tcpAcceptor->startAsyncAccept(connectionNode);
    }
  };

  class TCPCancelAccept: public Builtin<TCPCancelAccept> {
  public:
    TCPCancelAccept(): Builtin("tcpCancelAccept") {}

    static void call(VM vm, In acceptor) {
      auto tcpAcceptor = getTCPAcceptorArg(vm, acceptor);

      auto error = tcpAcceptor->cancel();
      if (error)
        raiseOSError(vm, "cancel", error);
    }
  };

  class TCPAcceptorClose: public Builtin<TCPAcceptorClose> {
  public:
    TCPAcceptorClose(): Builtin("tcpAcceptorClose") {}

    static void call(VM vm, In acceptor) {
      auto tcpAcceptor = getTCPAcceptorArg(vm, acceptor);

      auto error = tcpAcceptor->close();
      if (error)
        raiseOSError(vm, "close", error);
    }
  };

  class TCPConnect: public Builtin<TCPConnect> {
  public:
    TCPConnect(): Builtin("tcpConnect") {}

    static void call(VM vm, In host, In service, Out status) {
      size_t hostBufSize = ozVSLengthForBuffer(vm, host);
      size_t serviceBufSize = ozVSLengthForBuffer(vm, service);

      {
        std::string strHost, strService;
        ozVSGet(vm, host, hostBufSize, strHost);
        ozVSGet(vm, service, serviceBufSize, strService);

        auto tcpConnection = TCPConnection::create(env(vm), ident(vm));

        auto statusNode =
          BoostVM::forVM(vm).createAsyncIOFeedbackNode(status);

        tcpConnection->startAsyncConnect(strHost, strService, statusNode);
      }
    }
  };

private:
  template <typename T, typename P>
  static void baseSocketConnectionRead(
    VM vm, BaseSocketConnection<T, P>* connection,
    In count, In tail, Out status) {

    // Fetch the count
    auto intCount = getArgument<nativeint>(vm, count);

    // 0 size
    if (intCount <= 0) {
      status = buildTuple(vm, "succeeded", 0, tail);
      return;
    }

    // Resize the buffer
    size_t size = (size_t) intCount;
    connection->getReadData().resize(size);

    auto tailNode = BoostVM::forVM(vm).allocAsyncIONode(tail.getStableRef(vm));
    auto statusNode = BoostVM::forVM(vm).createAsyncIOFeedbackNode(status);

    connection->startAsyncReadSome(tailNode, statusNode);
  }

  template <typename T, typename P>
  static void baseSocketConnectionWrite(
    VM vm, BaseSocketConnection<T, P>* connection, In data, Out status) {

    size_t bufSize = ozVBSLengthForBuffer(vm, data);

    // 0 size
    if (bufSize == 0) {
      status = build(vm, 0);
      return;
    }

    // Fetch the data to write
    connection->getWriteData().clear();
    ozVBSGet(vm, data, bufSize, connection->getWriteData());

    auto statusNode =
      BoostVM::forVM(vm).createAsyncIOFeedbackNode(status);

    connection->startAsyncWrite(statusNode);
  }

  template <typename T, typename P>
  static void baseSocketConnectionShutdown(
    VM vm, BaseSocketConnection<T, P>* connection, In what) {

    using namespace patternmatching;
    using socket = typename BaseSocketConnection<T, P>::protocol::socket;

    // Fetch what channels must be shut down
    typename socket::shutdown_type whatValue;
    if (matches(vm, what, "receive")) {
      whatValue = socket::shutdown_receive;
    } else if (matches(vm, what, "send")) {
      whatValue = socket::shutdown_send;
    } else if (matches(vm, what, "both")) {
      whatValue = socket::shutdown_both;
    } else {
      raiseTypeError(vm, "'receive', 'send' or 'both'", what);
    }

    try {
      connection->socket().shutdown(whatValue);
    } catch (const boost::system::system_error& error) {
      raiseOSError(vm, "shutdown", error);
    }
  }

  template <typename T, typename P>
  static void baseSocketConnectionClose(
    VM vm, BaseSocketConnection<T, P>* connection) {

    using socket = typename BaseSocketConnection<T, P>::protocol::socket;

    try {
      connection->socket().shutdown(socket::shutdown_both);
      connection->socket().close();
    } catch (const boost::system::system_error& error) {
      raiseOSError(vm, "close", error);
    }
  }

public:
  class TCPConnectionRead: public Builtin<TCPConnectionRead> {
  public:
    TCPConnectionRead(): Builtin("tcpConnectionRead") {}

    static void call(VM vm, In connection, In count, In tail, Out status) {
      baseSocketConnectionRead(vm, getTCPConnectionArg(vm, connection),
                               count, tail, status);
    }
  };

  class TCPConnectionWrite: public Builtin<TCPConnectionWrite> {
  public:
    TCPConnectionWrite(): Builtin("tcpConnectionWrite") {}

    static void call(VM vm, In connection, In data, Out status) {
      baseSocketConnectionWrite(vm, getTCPConnectionArg(vm, connection),
                                data, status);
    }
  };

  class TCPConnectionShutdown: public Builtin<TCPConnectionShutdown> {
  public:
    TCPConnectionShutdown(): Builtin("tcpConnectionShutdown") {}

    static void call(VM vm, In connection, In what) {
      baseSocketConnectionShutdown(vm, getTCPConnectionArg(vm, connection),
                                   what);
    }
  };

  class TCPConnectionClose: public Builtin<TCPConnectionClose> {
  public:
    TCPConnectionClose(): Builtin("tcpConnectionClose") {}

    static void call(VM vm, In connection) {
      baseSocketConnectionClose(vm, getTCPConnectionArg(vm, connection));
    }
  };

  // Process management

  static
  void parseExecutableAndArgv(VM vm, RichNode inExecutable, RichNode inArgv,
                              mut::LString<char>& executable, size_t& argc,
                              StaticArray<mut::LString<char>>& argv) {
    size_t executableBufSize = ozVSLengthForBuffer(vm, inExecutable);
    argc = ozListLength(vm, inArgv);
    auto argvBufSizes = vm->newStaticArray<size_t>(argc);

    ozListForEach(vm, inArgv,
      [vm, &argvBufSizes] (RichNode inArg, size_t i) {
        argvBufSizes[i] = ozVSLengthForBuffer(vm, inArg);
      },
      "list(VirtualString)"
    );

    executable = ozVSGetNullTerminatedAsLString<char>(
      vm, inExecutable, executableBufSize);

    argv = vm->newStaticArray<mut::LString<char>>(argc);
    ozListForEach(vm, inArgv,
      [vm, &argvBufSizes, &argv] (RichNode inArg, size_t i) {
        argv[i] = ozVSGetNullTerminatedAsLString<char>(
          vm, inArg, argvBufSizes[i]);
      },
      "list(VirtualString)"
    );

    vm->deleteStaticArray(argvBufSizes, argc);
  }

  class Exec: public Builtin<Exec> {
  public:
    Exec(): Builtin("exec") {}

    static void call(VM vm, In inExecutable, In inArgv, In inDoKill,
                     Out outPid) {
      // TODO Unicode on Windows!!!

      // Extract arguments

      auto doKill = getArgument<bool>(vm, inDoKill);
      mut::LString<char> executable = nullptr;
      size_t argc;
      StaticArray<mut::LString<char>> argv;
      parseExecutableAndArgv(vm, inExecutable, inArgv, executable, argc, argv);

      // Now do the job

#ifdef MOZART_WINDOWS
      std::stringstream scmdline;
      for (size_t i = 0; i < argc; i++) {
        if (i != 0)
          scmdline << ' ';
        scmdline << '\"' << argv[i].string << '\"';
      }
      auto cmdline = scmdline.str();

      STARTUPINFOA si;
      memset(&si, 0, sizeof(si));
      si.cb = sizeof(si);
      if (doKill) {
        si.dwFlags = STARTF_USESTDHANDLES;
        SetHandleInformation(GetStdHandle(STD_INPUT_HANDLE),
                             HANDLE_FLAG_INHERIT,HANDLE_FLAG_INHERIT);
        SetHandleInformation(GetStdHandle(STD_OUTPUT_HANDLE),
                             HANDLE_FLAG_INHERIT,HANDLE_FLAG_INHERIT);
        SetHandleInformation(GetStdHandle(STD_ERROR_HANDLE),
                             HANDLE_FLAG_INHERIT,HANDLE_FLAG_INHERIT);
        si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
        si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
        si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
      }

      // If we don't want the child to be killed and we had OZPPID set,
      // then we save its value and unset it.  Otherwise, the buffer
      // contains an empty string.
      char ozppidbuf[100];
      if (!doKill) {
        if (!GetEnvironmentVariable("OZPPID", ozppidbuf, sizeof(ozppidbuf))) {
          ozppidbuf[0] = '\0';
        } else {
          SetEnvironmentVariable("OZPPID", nullptr);
          assert(ozppidbuf[0] != '\0');
        }
      } else {
        ozppidbuf[0] = '\0';
      }

      PROCESS_INFORMATION pinf;
      if (!CreateProcessA(executable.string, const_cast<char*>(cmdline.c_str()),
                          nullptr, nullptr, false,
                          doKill ? 0 : DETACHED_PROCESS,
                          nullptr, nullptr, &si, &pinf)) {
        if (ozppidbuf[0] != '\0')
          SetEnvironmentVariable("OZPPID", ozppidbuf);
        raiseOSError(vm, "exec", 0,
                     "Cannot exec process.");
      }
      CloseHandle(pinf.hThread);
      CloseHandle(pinf.hProcess); //--** unsafe! keep open while pid used

      if (ozppidbuf[0] != '\0')
        SetEnvironmentVariable("OZPPID", ozppidbuf);

      nativeint pid = pinf.dwProcessId;

#else  /* !MOZART_WINDOWS */

      auto pid = fork();
      switch (pid) {
        case 0: { // child

          // From here on, we don't care about memory leaks anymore ...

#ifdef DEBUG_FORK_GROUP
          /* create a new process group for child
           * this allows to press Control-C when debugging the emulator
           */
          if (setsid() < 0) {
            /* kost@ : raising an exception here makes no sense - that's
             * the child process...
             */
            fprintf(stderr, "setsid failed\n");
            exit(-1);
          }
#endif

          /* the child process should not produce a core file -- otherwise
           * we get a problem if all core files are just named 'core',
           * because the emulator's core file gets overwritten immediately
           * by wish's one...
           */
          rlimit rlim;
          rlim.rlim_cur = 0;
          rlim.rlim_max = 0;
          if (setrlimit(RLIMIT_CORE, &rlim) < 0) {
            std::cerr << "setrlimit failed\n";
            exit(-1);
          }

#ifdef DEBUG_CHECK
          /* kost@ : leave 'std???' in place in debug mode since otherwise
           * one cannot see what forked sites are trying to say us.
           * However, this makes e.g. the 'detach' functionality of remote
           * servers non-working (but who wants it in debug mode anyway?)
           */
          for (int i = 3; i < FD_SETSIZE; i++)
            close(i);
#else
          if (doKill) {
            for (int i = 3; i < FD_SETSIZE; i++)
              close(i);
          } else {
            for (int i = FD_SETSIZE; i--; )
              close(i);

            int dn;
            while ((dn = open("/dev/null", O_RDWR)) < 0) {
              if (errno != EINTR)
                raiseLastOSError(vm, "open");
            }

            dup2(dn, 1); // stdout
            dup2(dn, 2); // stderr
          }
#endif

          auto c_executable = executable.string;
          auto c_argv = new char*[argc+1];
          for (size_t i = 0; i < argc; ++i)
            c_argv[i] = const_cast<char*>(argv[i].string);
          c_argv[argc] = nullptr;

#ifdef NDEBUG
          execvp(c_executable, c_argv);
#else
          int execRet;
          execRet = execvp(c_executable, c_argv);
          assert(execRet < 0);
#endif
          std::cerr << "execvp failed\n";
          exit(-101);
        }

        case -1: {
          raiseLastOSError(vm, "fork"); // fork failed
        }

        default: { // parent
          break;
        }
      }

#endif

      vm->deleteStaticArray(argv, argc);

      if (doKill) {
        BoostVM::forVM(vm).addChildProcess(pid);
      }

      outPid = build(vm, pid);
    }
  };

  class Pipe: public Builtin<Pipe> {
  public:
    Pipe(): Builtin("pipe") {}

    static void call(VM vm, In inExecutable, In inArgv,
                     Out outPid, Out outStatus) {
      // TODO Windows

      // Extract arguments

      mut::LString<char> executable = nullptr;
      size_t argc;
      StaticArray<mut::LString<char>> argv;
      parseExecutableAndArgv(vm, inExecutable, inArgv, executable, argc, argv);

#ifdef MOZART_WINDOWS
      raiseError(vm, "notImplemented", "OS.pipe on Windows");
#if 0
      std::stringstream scmdline;
      for (size_t i = 0; i < argc; i++) {
        if (i != 0)
          scmdline << ' ';
        scmdline << '\"' << argv[i] << '\"';
      }
      auto cmdline = scmdline.str();

      int sv[2];
      int aux = ossocketpair(PF_UNIX, SOCK_STREAM, 0, sv);

      HANDLE rh0, wh0, rh1, wh1, wh2;
      {
        HANDLE wh0Tmp, rh1Tmp;

        SECURITY_ATTRIBUTES sa1;
        sa1.nLength = sizeof(sa1);
        sa1.lpSecurityDescriptor = nullptr;
        sa1.bInheritHandle = true;

        SECURITY_ATTRIBUTES sa2;
        sa2.nLength = sizeof(sa2);
        sa2.lpSecurityDescriptor = nullptr;
        sa2.bInheritHandle = true;

        if (!CreatePipe(&rh0, &wh0Tmp, &sa1, 0)  ||
            !CreatePipe(&rh1Tmp, &wh1, &sa2, 0)) {
          raiseOSError(vm, "CreatePipe", 0, "Cannot create pipe.");
        }

        /* The child must only inherit one side of each pipe.
         * Else the inherited handle will cause the pipe to remain open
         * even though we may have closed it, resulting in the child
         * never getting an EOF on it.
         */
        if (!DuplicateHandle(GetCurrentProcess(), wh0Tmp,
                             GetCurrentProcess(), &wh0, 0,
                             false, DUPLICATE_SAME_ACCESS) ||
            !DuplicateHandle(GetCurrentProcess(), rh1Tmp,
                             GetCurrentProcess(), &rh1, 0,
                             false, DUPLICATE_SAME_ACCESS)) {
          raiseOSError(vm, "DuplicateHandle", 0, "Cannot duplicate handle.");
        }
        CloseHandle(wh0Tmp);
        CloseHandle(rh1Tmp);
      }

      // We need to duplicate the handle in case the child closes
      // either its output or its error handle.
      if (!DuplicateHandle(GetCurrentProcess(), wh1,
                           GetCurrentProcess(), &wh2, 0,
                           true, DUPLICATE_SAME_ACCESS)) {
        raiseOSError(vm, "DuplicateHandle", 0, "Cannot duplicate handle.");
      }

      STARTUPINFO si;
      memset(&si, 0, sizeof(si));
      si.cb = sizeof(si);
      si.dwFlags = STARTF_FORCEOFFFEEDBACK | STARTF_USESTDHANDLES;
      si.hStdInput = rh0;
      si.hStdOutput = wh1;
      si.hStdError = wh2;

      PROCESS_INFORMATION pinf;
      if (!CreateProcess(nullptr, const_cast<char*>(cmdline.c_str()),
                         nullptr, nullptr, true, 0,
                         nullptr, nullptr, &si, &pinf)) {
        raiseOSError(vm, "CreateProcess", 0, "Cannot create process.");
      }

      nativeint pid = pinf.dwProcessId;

      CloseHandle(rh0);
      CloseHandle(wh1);
      CloseHandle(wh2);
      CloseHandle(pinf.hProcess); //--** this is unsafe! keep open while pid used
      CloseHandle(pinf.hThread);

      // forward the handles to sockets so that we can do select() on them:
      createWriter(sv[1], wh0);
      createReader(sv[1], rh1); //--** sv[1] will be closed twice

      int rsock = sv[0];
      /* we can use the same descriptor for both reading and writing: */
      int wsock = rsock;

      vm->deleteStaticArray(argv, argc);

      BoostVM::forVM(vm).addChildProcess(pid);

      outPid = build(vm, pid);
      outStatus = buildSharp(vm, rsock, wsock);
#endif

#else  /* !MOZART_WINDOWS */

      auto pipeConnection = PipeConnection::create(env(vm), ident(vm));

      // Build the Oz value now so that it is registered for GC
      auto ozPipe = build(vm, pipeConnection);

      boost::system::error_code ec;
      auto& mySocket = pipeConnection->socket();

      {
        boost::asio::local::stream_protocol::socket childSocket(
          BoostEnvironment::forVM(vm).io_context);
        boost::asio::local::connect_pair(mySocket, childSocket, ec);

        if (!ec) {
          auto pid = fork();
          switch (pid) {
            case 0: { // child
#ifdef DEBUG_FORK_GROUP
              /*
               * create a new process group for child
               *   this allows to press Control-C when debugging the emulator
               */
              if (setsid() < 0) {
                std::cerr << "setsid failed\n";
                std::exit(-1);
              }
#endif

              /* the child process should not produce a core file -- otherwise
               * we get a problem if all core files are just named 'core', because
               * the emulator's core file gets overwritten immediately by wish's
               * one...
               */
              rlimit rlim;
              rlim.rlim_cur = 0;
              rlim.rlim_max = 0;
              if (setrlimit(RLIMIT_CORE, &rlim) < 0) {
                std::cerr << "setrlimit failed\n";
                std::exit(-1);
              }

              int socketHandle = childSocket.native_handle();

              for (int i = 0; i < FD_SETSIZE; i++) {
                if (i != socketHandle) {
                  close(i);
                }
              }
              dup2(socketHandle, 0); // stdin
              dup2(socketHandle, 1); // stdout
              dup2(socketHandle, 2); // stderr

              auto c_executable = executable.string;
              auto c_argv = new char*[argc+1];
              for (size_t i = 0; i < argc; ++i)
                c_argv[i] = const_cast<char*>(argv[i].string);
              c_argv[argc] = nullptr;

              if (execvp(c_executable, c_argv) < 0) {
                std::cerr << "execvp failed\n";
                std::exit(-1);
              }
              std::cerr << "this should never happen\n";
              std::exit(-1);
            }

            case -1: {
              raiseLastOSError(vm, "fork"); // fork failed
            }

            default: { // parent
              break;
            }
          }

          childSocket.close();

          vm->deleteStaticArray(argv, argc);

          BoostVM::forVM(vm).addChildProcess(pid);

          outPid = build(vm, pid);
          outStatus = std::move(ozPipe);
        }
      }

      if (ec) {
        raiseOSError(vm, "socketpair", ec);
      }

#endif
    }
  };

#ifdef BOOST_ASIO_HAS_LOCAL_SOCKETS
private:
  static PipeConnection* getPipeConnectionArg(VM vm, In connection) {
    return getPointerArgument<PipeConnection>(vm, connection,
                                              "Pipe connection");
  }

public:
  class PipeConnectionRead: public Builtin<PipeConnectionRead> {
  public:
    PipeConnectionRead(): Builtin("pipeConnectionRead") {}

    static void call(VM vm, In connection, In count, In tail, Out status) {
      baseSocketConnectionRead(vm, getPipeConnectionArg(vm, connection),
                               count, tail, status);
    }
  };

  class PipeConnectionWrite: public Builtin<PipeConnectionWrite> {
  public:
    PipeConnectionWrite(): Builtin("pipeConnectionWrite") {}

    static void call(VM vm, In connection, In data, Out status) {
      baseSocketConnectionWrite(vm, getPipeConnectionArg(vm, connection),
                                data, status);
    }
  };

  class PipeConnectionShutdown: public Builtin<PipeConnectionShutdown> {
  public:
    PipeConnectionShutdown(): Builtin("pipeConnectionShutdown") {}

    static void call(VM vm, In connection, In what) {
      baseSocketConnectionShutdown(vm, getPipeConnectionArg(vm, connection),
                                   what);
    }
  };

  class PipeConnectionClose: public Builtin<PipeConnectionClose> {
  public:
    PipeConnectionClose(): Builtin("pipeConnectionClose") {}

    static void call(VM vm, In connection) {
      baseSocketConnectionClose(vm, getPipeConnectionArg(vm, connection));
    }
  };
#else // BOOST_ASIO_HAS_LOCAL_SOCKETS
public:
  class PipeConnectionRead: public Builtin<PipeConnectionRead> {
  public:
    PipeConnectionRead(): Builtin("pipeConnectionRead") {}

    static void call(VM vm, In connection, In count, In tail, Out status) {
      raiseError(vm, "notImplemented", "Pipes on Windows");
    }
  };

  class PipeConnectionWrite: public Builtin<PipeConnectionWrite> {
  public:
    PipeConnectionWrite(): Builtin("pipeConnectionWrite") {}

    static void call(VM vm, In connection, In data, Out status) {
      raiseError(vm, "notImplemented", "Pipes on Windows");
    }
  };

  class PipeConnectionShutdown: public Builtin<PipeConnectionShutdown> {
  public:
    PipeConnectionShutdown(): Builtin("pipeConnectionShutdown") {}

    static void call(VM vm, In connection, In what) {
      raiseError(vm, "notImplemented", "Pipes on Windows");
    }
  };

  class PipeConnectionClose: public Builtin<PipeConnectionClose> {
  public:
    PipeConnectionClose(): Builtin("pipeConnectionClose") {}

    static void call(VM vm, In connection) {
      raiseError(vm, "notImplemented", "Pipes on Windows");
    }
  };
#endif // BOOST_ASIO_HAS_LOCAL_SOCKETS

  class GetPID: public Builtin<GetPID> {
  public:
    GetPID(): Builtin("getPID") {}

    static void call(VM vm, Out pid) {
#ifdef MOZART_WINDOWS
      pid = SmallInt::build(vm, GetCurrentProcessId());
#else
      pid = build(vm, getpid());
#endif
    }
  };

  class GetHostByName: public Builtin<GetHostByName> {
  public:
    GetHostByName(): Builtin("getHostByName") {}

    static void call(VM vm, In name, Out res) {
      // gethostbyname(3) is deprecated. Emulate getaddrinfo(3) instead?
      typedef boost::asio::ip::tcp tcp;

      boost::system::error_code ec;

      {
        size_t nameBufLength = ozVSLengthForBuffer(vm, name);
        std::string nameString;
        ozVSGet(vm, name, nameBufLength, nameString);

        auto& environment = BoostEnvironment::forVM(vm);
        tcp::resolver resolver (environment.io_context);
        auto results = resolver.resolve(nameString, "0", ec);
        if (!ec) {
          OzListBuilder addrListBuilder (vm);

          for (const auto& entry : results) {
            auto addr = entry.endpoint().address().to_string();
            auto addrString = String::build(vm, newLString(vm, addr));
            addrListBuilder.push_back(vm, addrString);
          }

          auto arity = buildArity(vm, "hostent", "addrList", "aliases", "name");
          res = buildRecord(vm, std::move(arity), addrListBuilder.get(vm),
                                                  vm->coreatoms.nil,
                                                  name);
          return;
        }
      }

      raiseOSError(vm, "getHostByName", ec);
    }
  };

  class UName: public Builtin<UName> {
    static UnstableNode buildString(VM vm, const char* value) {
      return String::build(vm, newLString(vm, value));
    }

  public:
    UName(): Builtin("uName") {}

    static void call(VM vm, Out res) {
#ifdef MOZART_WINDOWS
      // TODO: Implement uname(2) on Windows. Perhaps we can take some ideas
      //       from http://hg.python.org/cpython/file/3.3/Lib/platform.py#l1043.
      raiseError(vm, "notImplemented", "OS.uName on Windows");
#else
      struct utsname result;
      if (uname(&result) != 0) {
        raiseLastOSError(vm, "uname");
      }

      auto arity = buildArity(vm, "utsname", "machine", "nodename", "release",
                                             "sysname", "version");
      res = buildRecord(vm, std::move(arity), buildString(vm, result.machine),
                                              buildString(vm, result.nodename),
                                              buildString(vm, result.release),
                                              buildString(vm, result.sysname),
                                              buildString(vm, result.version));
#endif
    }
  };
};

}

} }

#endif // MOZART_GENERATOR

#endif // MOZART_MODOSBOOST_H
