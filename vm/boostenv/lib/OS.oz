%% Copyright © 2011, Université catholique de Louvain
%% All rights reserved.
%%
%% Redistribution and use in source and binary forms, with or without
%% modification, are permitted provided that the following conditions are met:
%%
%% *  Redistributions of source code must retain the above copyright notice,
%%    this list of conditions and the following disclaimer.
%% *  Redistributions in binary form must reproduce the above copyright notice,
%%    this list of conditions and the following disclaimer in the documentation
%%    and/or other materials provided with the distribution.
%%
%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%% POSSIBILITY OF SUCH DAMAGE.

%%
%% Authors:
%%   Sébastien Doeraene <sjrdoeraene@gmail.com>
%%

functor

require
   Boot_OS at 'x-oz://boot/OS'

export
   % Random number generation
   Rand
   Srand
   RandLimits

   % Environment
   GetEnv
   PutEnv

   % File I/0
   GetCWD
   Tmpnam

   Fopen
   Fread
   Fwrite
   Fseek
   Fclose

   % Standard streams
   Stdin
   Stdout
   Stderr

   % Sockets
   tcpAcceptorCreate: TCPAcceptorCreate
   tcpAccept: TCPAccept
   tcpAcceptorClose: TCPAcceptorClose
   tcpConnect: TCPConnect
   tcpConnectionRead: TCPConnectionRead
   tcpConnectionWrite: TCPConnectionWrite
   tcpConnectionShutdown: TCPConnectionShutdown
   tcpConnectionClose: TCPConnectionClose

   % Process management
   SpawnProcess
   SpawnProcessAndPipe
   PipeConnectionRead
   PipeConnectionWrite
   PipeConnectionShutdown
   PipeConnectionClose

   % Compatibility
   open: CompatOpen
   fileDesc: CompatFileDesc
   read: CompatRead
   write: CompatWrite
   lSeek: CompatLSeek
   close: CompatClose

   acceptSelect: CompatAcceptSelect
   readSelect:   CompatReadSelect
   writeSelect:  CompatWriteSelect
   deSelect:     CompatDeSelect

   socket:      CompatSocket
   bind:        CompatBind
   listen:      CompatListen
   accept:      CompatAccept
   connect:     CompatConnect
   shutDown:    CompatShutDown
   getSockName: CompatGetSockName
   send:        CompatSend
   sendTo:      CompatSendTo
   receiveFrom: CompatReceiveFrom

   exec: CompatExec
   pipe: CompatPipe
   kill: CompatKill
   wait: CompatWait

define

   % Random number generation

   Rand = Boot_OS.rand
   Srand = Boot_OS.srand
   RandLimits = Boot_OS.randLimits

   % Environment

   GetEnv = Boot_OS.getEnv
   PutEnv = Boot_OS.putEnv

   % File I/0

   GetCWD = Boot_OS.getCWD
   Tmpnam = Boot_OS.tmpnam

   fun {Fopen FileName Mode}
      {Boot_OS.fopen FileName Mode}
   end

   proc {Fread File Max ?Head Tail ?Count}
      {Boot_OS.fread File Max Tail Count Head}
   end

   proc {Fwrite File DataV ?Count}
      {Boot_OS.fwrite File DataV ?Count}
   end

   Fclose = Boot_OS.fclose
   Fseek = Boot_OS.fseek
   Fclose = Boot_OS.fclose

   % Standard streams

   Stdin = {Boot_OS.stdin}
   Stdout = {Boot_OS.stdout}
   Stderr = {Boot_OS.stderr}

   % Sockets

   fun {WaitResult Result}
      {Wait Result}
      Result
   end

   TCPAcceptorCreate = Boot_OS.tcpAcceptorCreate

   fun {TCPAccept Acceptor}
      {WaitResult {Boot_OS.tcpAccept Acceptor}}
   end

   TCPCancelAccept = Boot_OS.tcpCancelAccept
   TCPAcceptorClose = Boot_OS.tcpAcceptorClose

   fun {TCPConnect Host Service}
      {WaitResult {Boot_OS.tcpConnect Host Service}}
   end

   proc {TCPConnectionRead Connection Count ?Head Tail ?ReadCount}
      case {Boot_OS.tcpConnectionRead Connection Count Tail}
      of succeeded(C H) then
         Head = H
         ReadCount = C
      end
   end

   fun {TCPConnectionWrite Connection DataV}
      {WaitResult {Boot_OS.tcpConnectionWrite Connection DataV}}
   end

   TCPConnectionShutdown = Boot_OS.tcpConnectionShutdown
   TCPConnectionClose = Boot_OS.tcpConnectionClose

   %% Process management

   SpawnProcess = Boot_OS.exec
   SpawnProcessAndPipe = Boot_OS.pipe

   proc {PipeConnectionRead Connection Count ?Head Tail ?ReadCount}
      case {Boot_OS.pipeConnectionRead Connection Count Tail}
      of succeeded(C H) then
         Head = H
         ReadCount = C
      end
   end

   fun {PipeConnectionWrite Connection DataV}
      {WaitResult {Boot_OS.pipeConnectionWrite Connection DataV}}
   end

   PipeConnectionShutdown = Boot_OS.pipeConnectionShutdown
   PipeConnectionClose = Boot_OS.pipeConnectionClose

   %% POSIX-like file descriptor management

   local
      DescDictLock = {NewLock}
      DescDict = {NewDictionary}
   in
      local
         fun {AllocDescEx Underlying I}
            if {Dictionary.member DescDict I} then
               {AllocDescEx Underlying I+1}
            else
               {Dictionary.put DescDict I Underlying}
               I
            end
         end
      in
         fun {AllocDesc Underlying}
            lock DescDictLock then
               {AllocDescEx Underlying 0}
            end
         end
      end

      fun {DescGet I}
         lock DescDictLock then
            case {Dictionary.condGet DescDict I false}
            of false then
               raise
                  system(os(os "unknown" 9 "Bad filedescriptor") debug:unit)
               end
            [] Underlying then
               Underlying
            end
         end
      end

      proc {FreeDesc I}
         lock DescDictLock then
            {Dictionary.remove DescDict I}
         end
      end

      DescStdin = {AllocDesc Stdin}
      DescStdout = {AllocDesc Stdout}
      DescStderr = {AllocDesc Stderr}
   end

   %% POSIX-like generic compatibility layer

   class CompatIOClass
      feat desc

      meth init(desc:Desc <= _)
         Desc = self.desc = {AllocDesc self}
      end

      meth close()
         {FreeDesc self.desc}
      end
   end

   fun {PatchVS Data}
      if {Not {IsVirtualByteString Data}} andthen {IsVirtualString Data} then
         {Coders.encode Data [latin1]}
      else
         Data
      end
   end

   proc {CompatRead FD Max ?Head Tail ?Count}
      {{DescGet FD} read(Max ?Head Tail ?Count)}
   end

   proc {CompatWrite FD Data ?Count}
      {{DescGet FD} write({PatchVS Data} ?Count)}
   end

   proc {CompatLSeek FD Whence Offset ?Where}
      {{DescGet FD} lSeek(Whence Offset ?Where)}
   end

   proc {CompatClose FD}
      {{DescGet FD} close()}
   end

   proc {CompatAcceptSelect FD}
      skip
   end

   proc {CompatReadSelect FD}
      skip
   end

   proc {CompatWriteSelect FD}
      skip
   end

   proc {CompatDeSelect FD}
      skip
   end

   %% POSIX-like file I/O compatibility

   class CompatFileClass from CompatIOClass
      feat file

      meth init(File desc:Desc <= _)
         CompatIOClass, init(desc:Desc)
         self.file = File
      end

      meth read(Max ?Head Tail ?Count)
         {Fread self.file Max ?Head Tail ?Count}
      end

      meth write(Data ?Count)
         {Fwrite self.file Data ?Count}
      end

      meth lSeek(Whence Offset ?Where)
         {Fseek self.file Offset Whence ?Where}
      end

      meth close()
         CompatIOClass, close()
         {Fclose self.file}
      end
   end

   fun {FlagsToMode Flags}
      if {Member 'O_WRONLY' Flags} then
         if {Member 'O_APPEND' Flags} then
            "ab"
         else
            "wb"
         end
      elseif {Member 'O_RDWR' Flags} then
         if {Not {Member 'O_CREAT' Flags}} then
            "r+b"
         elseif {Member 'O_APPEND' Flags} then
            "a+b"
         else
            "w+b"
         end
      else
         "rb"
      end
   end

   fun {CompatOpen FileName Flags CreateMode}
      File = {Fopen FileName {FlagsToMode Flags}}
   in
      {New CompatFileClass init(File desc:$) _}
   end

   fun {CompatFileDesc DescName}
      case DescName
      of 'STDIN_FILENO'  then DescStdin
      [] 'STDOUT_FILENO' then DescStdout
      [] 'STDERR_FILENO' then DescStderr
      end
   end

   % POSIX-like socket I/O compatibility

   class CompatSocketClass from CompatIOClass
   end

   class CompatTCPSocketClass from CompatSocketClass
      attr
         mode: unit
         bindPort: unit
         backLog: unit

         acceptor: unit

      meth init(desc:Desc <= _)
         true = @mode == unit

         CompatSocketClass, init(desc:Desc)
         mode := init
      end

      meth bind(Port)
         true = @mode == init
         if Port \= 0 then
            bindPort := Port
         else
            % Generate a random port - let's do something stupid for now
            bindPort := {Rand} mod 100 + 1234
         end
         mode := bound
      end

      meth listen(BackLog)
         true = @mode == bound
         backLog := BackLog

         acceptor := {TCPAcceptorCreate 4 @bindPort}
         mode := acceptor
      end

      meth accept(?Host ?Port ?Desc)
         true = @mode == acceptor
         Connection = {TCPAccept @acceptor}
      in
         {New CompatTCPConnectionClass init(Connection desc:?Desc) _}
      end

      meth connect(Host Port ?Desc)
         true = @mode == init
         Connection = {TCPConnect Host Port}
      in
         {New CompatTCPConnectionClass init(Connection desc:?Desc) _}
      end

      meth getSockName(?Port)
         Port = @bindPort
      end

      meth close()
         CompatSocketClass, close()

         if @mode == acceptor then
            {TCPAcceptorClose @acceptor}
         end

         mode := closed
      end
   end

   class CompatTCPConnectionClass from CompatSocketClass
      attr
         connection

      meth init(Connection desc:Desc <= _)
         CompatSocketClass, init(desc:Desc)

         connection := Connection
      end

      meth read(Max ?Head Tail ?Count)
         {TCPConnectionRead @connection Max ?Head Tail ?Count}
      end

      meth write(Data ?Count)
         {TCPConnectionWrite @connection Data ?Count}
      end

      meth shutDown(How)
         What = case How
                of 0 then receive
                [] 1 then send
                else both
                end
      in
         {TCPConnectionShutdown @connection What}
      end

      meth close()
         CompatSocketClass, close()
         {TCPConnectionClose @connection}
      end
   end

   fun {CompatSocket Domain Type Proto}
      case Domain of 'PF_INET' then
         case Type
         of 'SOCK_STREAM' then
            {New CompatTCPSocketClass init(desc:$) _}
         end
      end
   end

   proc {CompatBind Sock Port}
      {{DescGet Sock} bind(Port)}
   end

   proc {CompatListen Sock BackLog}
      {{DescGet Sock} listen(BackLog)}
   end

   proc {CompatAccept Sock ?Host ?Port ?Desc}
      {{DescGet Sock} accept(?Host ?Port ?Desc)}
   end

   proc {CompatConnect Sock Host Port}
      {{DescGet Sock} connect(Host Port)}
   end

   proc {CompatShutDown Sock How}
      {{DescGet Sock} shutDown(How)}
   end

   proc {CompatGetSockName Sock ?Port}
      {{DescGet Sock} getSockName(?Port)}
   end

   proc {CompatSend Sock Msg Flags ?Len}
      {{DescGet Sock} send({PatchVS Msg} Flags ?Len)}
   end

   proc {CompatSendTo Sock Msg Flags Host Port ?Len}
      {{DescGet Sock} sendTo({PatchVS Msg} Flags Host Port ?Len)}
   end

   proc {CompatReceiveFrom Sock Max Flags ?Head Tail ?Host ?Port ?Len}
      {{DescGet Sock} receiveFrom(Max Flags ?Head Tail ?Host ?Port ?Len)}
   end

   %% POSIX-like process management

   class CompatPipeConnectionClass from CompatIOClass
      attr
         connection

      meth init(Connection desc:Desc <= _)
         CompatIOClass, init(desc:Desc)

         connection := Connection
      end

      meth read(Max ?Head Tail ?Count)
         {PipeConnectionRead @connection Max ?Head Tail ?Count}
      end

      meth write(Data ?Count)
         {PipeConnectionWrite @connection Data ?Count}
      end

      meth shutDown(How)
         What = case How
                of 0 then receive
                [] 1 then send
                else both
                end
      in
         {TCPConnectionShutdown @connection What}
      end

      meth close()
         CompatIOClass, close()
         {PipeConnectionClose @connection}
      end
   end

   proc {CompatExec Executable Args DoKill ?Pid}
      {SpawnProcess Executable Executable|Args DoKill ?Pid}
   end

   proc {CompatPipe Executable Args ?Pid ?Status}
      Connection = {SpawnProcessAndPipe Executable Executable|Args ?Pid}
      Desc = {New CompatPipeConnectionClass init(Connection desc:$) _}
   in
      Status = Desc#Desc
   end

   proc {CompatKill Pid Signal ?Status}
      % TODO
      Status = 0
   end

   proc {CompatWait ?Pid ?Status}
      % TODO
      Status = 0
   end

end
