%%% Copyright © 2012, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% *  Redistributions of source code must retain the above copyright notice,
%%%    this list of conditions and the following disclaimer.
%%% *  Redistributions in binary form must reproduce the above copyright notice,
%%%    this list of conditions and the following disclaimer in the documentation
%%%    and/or other materials provided with the distribution.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%% POSSIBILITY OF SUCH DAMAGE.

local
   LockID = {NewUniqueName lockID}
in
   fun {IsLock X}
      {IsChunk X} andthen {HasFeature X LockID}
   end

   fun {NewLock}
      CurrentThread = {NewCell unit}
      Token = {NewCell unit}
      proc {Lock P}
         ThisThread = {Boot_Thread.this}
      in
         if ThisThread == @CurrentThread then
            {P}
         else
            NewToken
         in
            try
               {Wait Token := NewToken}
               CurrentThread := ThisThread
               {P}
            finally
               CurrentThread := unit
               NewToken = unit
            end
         end
      end
   in
      {NewChunk 'lock'(LockID:Lock)}
   end

   proc {LockIn Lock P}
      if {IsLock Lock} then
         {Lock.LockID P}
      else
         raise typeError('lock' Lock) end
      end
   end
end

Lock = 'lock'(is:  IsLock
              new: NewLock)
