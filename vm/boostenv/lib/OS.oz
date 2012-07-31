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

   % File I/0
   GetCWD
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

   % Compatibility
   open: CompatOpen
   fileDesc: CompatFileDesc
   read: CompatRead
   write: CompatWrite
   lSeek: CompatLSeek
   close: CompatClose

define

   % Random number generation

   Rand = Boot_OS.rand
   Srand = Boot_OS.srand
   RandLimits = Boot_OS.randLimits

   % Environment

   GetEnv = Boot_OS.getEnv

   % File I/0

   GetCWD = Boot_OS.getCWD

   Fopen = Boot_OS.fopen

   proc {Fread FD Max ?Head Tail ?Count}
      {Boot_OS.fread FD Max Tail Count Head}
   end

   Fwrite = Boot_OS.fwrite
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

   fun {TCPConnectionWrite Connection Data}
      {WaitResult {Boot_OS.tcpConnectionWrite Connection Data}}
   end

   TCPConnectionShutdown = Boot_OS.tcpConnectionShutdown
   TCPConnectionClose = Boot_OS.tcpConnectionClose

   %% POSIX-like file I/O compatibility

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
      {Boot_OS.fopen FileName {FlagsToMode Flags}}
   end

   fun {CompatFileDesc DescName}
      case DescName
      of 'STDIN_FILENO'  then Stdin
      [] 'STDOUT_FILENO' then Stdout
      [] 'STDERR_FILENO' then Stderr
      end
   end

   proc {CompatRead FD Max ?Head Tail ?Count}
      {Boot_OS.fread FD Max Tail Count Head}
   end

   fun {CompatWrite FD Data}
      {Boot_OS.fwrite FD Data}
   end

   proc {CompatLSeek FD Whence Offset ?Where}
      {Boot_OS.fseek FD Offset Whence Where}
   end

   proc {CompatClose FD}
      {Boot_OS.fclose FD}
   end

end
