
namespace biref {
using namespace ::mozart;

class ModOS: public BuiltinModule {
public:
  ModOS(VM vm): BuiltinModule(vm, "OS") {
    instanceBootURLLoad.setModuleName("OS");
    instanceRand.setModuleName("OS");
    instanceSrand.setModuleName("OS");
    instanceRandLimits.setModuleName("OS");
    instanceGetEnv.setModuleName("OS");
    instancePutEnv.setModuleName("OS");
    instanceGetDir.setModuleName("OS");
    instanceGetCWD.setModuleName("OS");
    instanceChDir.setModuleName("OS");
    instanceTmpnam.setModuleName("OS");
    instanceFopen.setModuleName("OS");
    instanceFread.setModuleName("OS");
    instanceFwrite.setModuleName("OS");
    instanceFseek.setModuleName("OS");
    instanceFclose.setModuleName("OS");
    instanceStdin.setModuleName("OS");
    instanceStdout.setModuleName("OS");
    instanceStderr.setModuleName("OS");
    instanceSystem.setModuleName("OS");
    instanceTCPAcceptorCreate.setModuleName("OS");
    instanceTCPAccept.setModuleName("OS");
    instanceTCPCancelAccept.setModuleName("OS");
    instanceTCPAcceptorClose.setModuleName("OS");
    instanceTCPConnect.setModuleName("OS");
    instanceTCPConnectionRead.setModuleName("OS");
    instanceTCPConnectionWrite.setModuleName("OS");
    instanceTCPConnectionShutdown.setModuleName("OS");
    instanceTCPConnectionClose.setModuleName("OS");
    instanceExec.setModuleName("OS");
    instancePipe.setModuleName("OS");
    instancePipeConnectionRead.setModuleName("OS");
    instancePipeConnectionWrite.setModuleName("OS");
    instancePipeConnectionShutdown.setModuleName("OS");
    instancePipeConnectionClose.setModuleName("OS");
    instanceGetPID.setModuleName("OS");
    instanceGetHostByName.setModuleName("OS");
    instanceUName.setModuleName("OS");

    UnstableField fields[37];
    fields[0].feature = build(vm, "bootURLLoad");
    fields[0].value = build(vm, instanceBootURLLoad);
    fields[1].feature = build(vm, "rand");
    fields[1].value = build(vm, instanceRand);
    fields[2].feature = build(vm, "srand");
    fields[2].value = build(vm, instanceSrand);
    fields[3].feature = build(vm, "randLimits");
    fields[3].value = build(vm, instanceRandLimits);
    fields[4].feature = build(vm, "getEnv");
    fields[4].value = build(vm, instanceGetEnv);
    fields[5].feature = build(vm, "putEnv");
    fields[5].value = build(vm, instancePutEnv);
    fields[6].feature = build(vm, "getDir");
    fields[6].value = build(vm, instanceGetDir);
    fields[7].feature = build(vm, "getCWD");
    fields[7].value = build(vm, instanceGetCWD);
    fields[8].feature = build(vm, "chDir");
    fields[8].value = build(vm, instanceChDir);
    fields[9].feature = build(vm, "tmpnam");
    fields[9].value = build(vm, instanceTmpnam);
    fields[10].feature = build(vm, "fopen");
    fields[10].value = build(vm, instanceFopen);
    fields[11].feature = build(vm, "fread");
    fields[11].value = build(vm, instanceFread);
    fields[12].feature = build(vm, "fwrite");
    fields[12].value = build(vm, instanceFwrite);
    fields[13].feature = build(vm, "fseek");
    fields[13].value = build(vm, instanceFseek);
    fields[14].feature = build(vm, "fclose");
    fields[14].value = build(vm, instanceFclose);
    fields[15].feature = build(vm, "stdin");
    fields[15].value = build(vm, instanceStdin);
    fields[16].feature = build(vm, "stdout");
    fields[16].value = build(vm, instanceStdout);
    fields[17].feature = build(vm, "stderr");
    fields[17].value = build(vm, instanceStderr);
    fields[18].feature = build(vm, "system");
    fields[18].value = build(vm, instanceSystem);
    fields[19].feature = build(vm, "tcpAcceptorCreate");
    fields[19].value = build(vm, instanceTCPAcceptorCreate);
    fields[20].feature = build(vm, "tcpAccept");
    fields[20].value = build(vm, instanceTCPAccept);
    fields[21].feature = build(vm, "tcpCancelAccept");
    fields[21].value = build(vm, instanceTCPCancelAccept);
    fields[22].feature = build(vm, "tcpAcceptorClose");
    fields[22].value = build(vm, instanceTCPAcceptorClose);
    fields[23].feature = build(vm, "tcpConnect");
    fields[23].value = build(vm, instanceTCPConnect);
    fields[24].feature = build(vm, "tcpConnectionRead");
    fields[24].value = build(vm, instanceTCPConnectionRead);
    fields[25].feature = build(vm, "tcpConnectionWrite");
    fields[25].value = build(vm, instanceTCPConnectionWrite);
    fields[26].feature = build(vm, "tcpConnectionShutdown");
    fields[26].value = build(vm, instanceTCPConnectionShutdown);
    fields[27].feature = build(vm, "tcpConnectionClose");
    fields[27].value = build(vm, instanceTCPConnectionClose);
    fields[28].feature = build(vm, "exec");
    fields[28].value = build(vm, instanceExec);
    fields[29].feature = build(vm, "pipe");
    fields[29].value = build(vm, instancePipe);
    fields[30].feature = build(vm, "pipeConnectionRead");
    fields[30].value = build(vm, instancePipeConnectionRead);
    fields[31].feature = build(vm, "pipeConnectionWrite");
    fields[31].value = build(vm, instancePipeConnectionWrite);
    fields[32].feature = build(vm, "pipeConnectionShutdown");
    fields[32].value = build(vm, instancePipeConnectionShutdown);
    fields[33].feature = build(vm, "pipeConnectionClose");
    fields[33].value = build(vm, instancePipeConnectionClose);
    fields[34].feature = build(vm, "getPID");
    fields[34].value = build(vm, instanceGetPID);
    fields[35].feature = build(vm, "getHostByName");
    fields[35].value = build(vm, instanceGetHostByName);
    fields[36].feature = build(vm, "uName");
    fields[36].value = build(vm, instanceUName);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 37, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::boostenv::builtins::ModOS::BootURLLoad instanceBootURLLoad;
  mozart::boostenv::builtins::ModOS::Rand instanceRand;
  mozart::boostenv::builtins::ModOS::Srand instanceSrand;
  mozart::boostenv::builtins::ModOS::RandLimits instanceRandLimits;
  mozart::boostenv::builtins::ModOS::GetEnv instanceGetEnv;
  mozart::boostenv::builtins::ModOS::PutEnv instancePutEnv;
  mozart::boostenv::builtins::ModOS::GetDir instanceGetDir;
  mozart::boostenv::builtins::ModOS::GetCWD instanceGetCWD;
  mozart::boostenv::builtins::ModOS::ChDir instanceChDir;
  mozart::boostenv::builtins::ModOS::Tmpnam instanceTmpnam;
  mozart::boostenv::builtins::ModOS::Fopen instanceFopen;
  mozart::boostenv::builtins::ModOS::Fread instanceFread;
  mozart::boostenv::builtins::ModOS::Fwrite instanceFwrite;
  mozart::boostenv::builtins::ModOS::Fseek instanceFseek;
  mozart::boostenv::builtins::ModOS::Fclose instanceFclose;
  mozart::boostenv::builtins::ModOS::Stdin instanceStdin;
  mozart::boostenv::builtins::ModOS::Stdout instanceStdout;
  mozart::boostenv::builtins::ModOS::Stderr instanceStderr;
  mozart::boostenv::builtins::ModOS::System instanceSystem;
  mozart::boostenv::builtins::ModOS::TCPAcceptorCreate instanceTCPAcceptorCreate;
  mozart::boostenv::builtins::ModOS::TCPAccept instanceTCPAccept;
  mozart::boostenv::builtins::ModOS::TCPCancelAccept instanceTCPCancelAccept;
  mozart::boostenv::builtins::ModOS::TCPAcceptorClose instanceTCPAcceptorClose;
  mozart::boostenv::builtins::ModOS::TCPConnect instanceTCPConnect;
  mozart::boostenv::builtins::ModOS::TCPConnectionRead instanceTCPConnectionRead;
  mozart::boostenv::builtins::ModOS::TCPConnectionWrite instanceTCPConnectionWrite;
  mozart::boostenv::builtins::ModOS::TCPConnectionShutdown instanceTCPConnectionShutdown;
  mozart::boostenv::builtins::ModOS::TCPConnectionClose instanceTCPConnectionClose;
  mozart::boostenv::builtins::ModOS::Exec instanceExec;
  mozart::boostenv::builtins::ModOS::Pipe instancePipe;
  mozart::boostenv::builtins::ModOS::PipeConnectionRead instancePipeConnectionRead;
  mozart::boostenv::builtins::ModOS::PipeConnectionWrite instancePipeConnectionWrite;
  mozart::boostenv::builtins::ModOS::PipeConnectionShutdown instancePipeConnectionShutdown;
  mozart::boostenv::builtins::ModOS::PipeConnectionClose instancePipeConnectionClose;
  mozart::boostenv::builtins::ModOS::GetPID instanceGetPID;
  mozart::boostenv::builtins::ModOS::GetHostByName instanceGetHostByName;
  mozart::boostenv::builtins::ModOS::UName instanceUName;
};
void registerBuiltinModOS(VM vm) {
  auto module = std::make_shared<ModOS>(vm);
  vm->registerBuiltinModule(module);
}

}

namespace biref {
using namespace ::mozart;

class ModVM: public BuiltinModule {
public:
  ModVM(VM vm): BuiltinModule(vm, "VM") {
    instanceNcores.setModuleName("VM");
    instanceCurrent.setModuleName("VM");
    instanceNew.setModuleName("VM");
    instanceGetPort.setModuleName("VM");
    instanceIdentForPort.setModuleName("VM");
    instanceGetStream.setModuleName("VM");
    instanceCloseStream.setModuleName("VM");
    instanceList.setModuleName("VM");
    instanceKill.setModuleName("VM");
    instanceMonitor.setModuleName("VM");

    UnstableField fields[10];
    fields[0].feature = build(vm, "ncores");
    fields[0].value = build(vm, instanceNcores);
    fields[1].feature = build(vm, "current");
    fields[1].value = build(vm, instanceCurrent);
    fields[2].feature = build(vm, "new");
    fields[2].value = build(vm, instanceNew);
    fields[3].feature = build(vm, "getPort");
    fields[3].value = build(vm, instanceGetPort);
    fields[4].feature = build(vm, "identForPort");
    fields[4].value = build(vm, instanceIdentForPort);
    fields[5].feature = build(vm, "getStream");
    fields[5].value = build(vm, instanceGetStream);
    fields[6].feature = build(vm, "closeStream");
    fields[6].value = build(vm, instanceCloseStream);
    fields[7].feature = build(vm, "list");
    fields[7].value = build(vm, instanceList);
    fields[8].feature = build(vm, "kill");
    fields[8].value = build(vm, instanceKill);
    fields[9].feature = build(vm, "monitor");
    fields[9].value = build(vm, instanceMonitor);
    UnstableNode label = build(vm, "export");
    UnstableNode module = buildRecordDynamic(vm, label, 10, fields);
    initModule(vm, std::move(module));
  }
private:
  mozart::boostenv::builtins::ModVM::Ncores instanceNcores;
  mozart::boostenv::builtins::ModVM::Current instanceCurrent;
  mozart::boostenv::builtins::ModVM::New instanceNew;
  mozart::boostenv::builtins::ModVM::GetPort instanceGetPort;
  mozart::boostenv::builtins::ModVM::IdentForPort instanceIdentForPort;
  mozart::boostenv::builtins::ModVM::GetStream instanceGetStream;
  mozart::boostenv::builtins::ModVM::CloseStream instanceCloseStream;
  mozart::boostenv::builtins::ModVM::List instanceList;
  mozart::boostenv::builtins::ModVM::Kill instanceKill;
  mozart::boostenv::builtins::ModVM::Monitor instanceMonitor;
};
void registerBuiltinModVM(VM vm) {
  auto module = std::make_shared<ModVM>(vm);
  vm->registerBuiltinModule(module);
}

}
