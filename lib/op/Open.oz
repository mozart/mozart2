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
%%   Christian Schulte <schulte@ps.uni-sb.de>
%%

functor

import
   OS

export
   File

define

   ReadSize = 1024
   NoArg = {NewName}

   fun {FileFlagsToOSMode Flags}
      Write = {Member write Flags}
      Read = {Member read Flags}
      ModeExceptBinary =
         if Read andthen Write then
            if {Not {Member create Flags}} then "r+"
            elseif {Member append Flags} then "a+"
            else "w+"
            end
         elseif Write then
            if {Not {Member create Flags}} then false
            elseif {Member append Flags} then "a"
            else "w"
            end
         else
            "r"
         end
   in
      (ModeExceptBinary \= false) andthen
         if {Member text Flags} then ModeExceptBinary
         else {Append ModeExceptBinary "b"}
         end
   end

   proc {DoReadWholeFile FD ReadCountAcc ?Head Tail ?ReadCount}
      ChunkTail ChunkReadCount
   in
      {OS.fread FD ReadSize Head ChunkTail ChunkReadCount}
      if ChunkReadCount > 0 then
         {DoReadWholeFile FD ReadCountAcc+ChunkReadCount
                          ChunkTail Tail ReadCount}
      else
         ChunkTail = nil
         ReadCount = ReadCountAcc
      end
   end

   class File
      prop locking
      feat Underlying

      meth init(name:  Name  <= NoArg
                url:   Url   <= NoArg
                flags: Flags <= [read]
                mode:  Mode  <= mode(owner:[write] all:[read])) = M
         % Convert flags to OS mode
         Mode = {FileFlagsToOSMode Flags}
         if Mode == false then
            raise {Exception.system open(illegalFlags self M)} end
         end

         % Check that exactly one of Name or Url is present
         if
            (Name == NoArg andthen Url == NoArg) orelse
            (Name \= NoArg andthen Url \= NoArg)
         then
            raise {Exception.system open(nameOrUrl self M)} end
         end
      in
         case Name
         of 'stdin'  then self.Underlying = OS.stdin
         [] 'stdout' then self.Underlying = OS.stdout
         [] 'stderr' then self.Underlying = OS.stderr
         [] _ andthen Name == NoArg then
            if {Member write Flags} then
               raise {Exception.system open(urlIsReadOnly self M)} end
            end
            % TODO
            % self.Underlying = {Resolve.open Url}
            raise {Exception.system unsupported(openUrl self M)} end
         else
            self.Underlying = {OS.fopen Name Mode}
         end
      end

      meth read(size: Size <= ReadSize
                list: ?Head
                tail: Tail <= nil
                len:  ?ReadCount <= _)
         lock
            if Size == all then
               {DoReadWholeFile self.Underlying 0 ?Head Tail ?ReadCount}
            else
               {OS.fread self.Underlying Size ?Head Tail ?ReadCount}
            end
         end
      end

      meth write(vs: Data
                 len: WrittenCount <= _)
         lock
            {OS.fwrite self.Underlying Data ?WrittenCount}
         end
      end

      meth seek(whence: Whence <= 'set'
                offset: Offset <= 0
                where: Where <= _)
         WhenceMap = whence('set':'SEEK_SET'
                            'current':'SEEK_CUR'
                            'end':'SEEK_END')
      in
         lock
            {OS.fseek self.Underlying Offset WhenceMap.Whence ?Where}
         end
      end

      meth tell(offset: ?Offset)
         lock
            {OS.fseek self.Underlying 0 'SEEK_CUR' ?Offset}
         end
      end

      meth close
         lock
            {OS.fclose self.Underlying}
         end
      end
   end

end
