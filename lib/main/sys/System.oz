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
   Boot_System at 'x-oz://boot/System'

export
   Print
   Show
   PrintName
   PrintInfo
   ShowInfo
   PrintError
   ShowError
   gcDo: GCDo
   % Postmortem
   Eq
   % NbSusps
   OnToplevel

define

   proc {Print Value}
      {Boot_System.printRepr Value false false}
   end

   proc {Show Value}
      {Boot_System.printRepr Value false true}
   end

   fun {PrintName Value}
      {Boot_System.printName Value}
   end

   proc {PrintInfo VS}
      {Boot_System.printVS VS false false}
   end

   proc {ShowInfo VS}
      {Boot_System.printVS VS false true}
   end

   proc {PrintError VS}
      {Boot_System.printVS VS true false}
   end

   proc {ShowError VS}
      {Boot_System.printVS VS true true}
   end

   GCDo = Boot_System.gcDo

   Eq = Boot_System.eq

   OnToplevel = Boot_System.onToplevel

end
