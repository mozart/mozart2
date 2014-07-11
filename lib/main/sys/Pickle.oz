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
%%   Benoit Daloze
%%

functor

require
   BootPickle at 'x-oz://boot/Pickle'

export
   Save
   SaveCompressed
   SaveWithHeader
   SaveWithCells

   Load
   LoadWithHeader

   Pack
   PackWithCells
   PackWithReplacements
   Unpack

define

   % HeaderMagic = [0x56 0xb4 0x8c 0x48]

   %%
   %% Save and its variants
   %%

   fun {Save URL}
      {BootPickle.save URL nil}
   end

   proc {SaveCompressed Value FileName Level}
      {Save Value FileName}
   end

   proc {SaveWithHeader Value FileName Header Level}
      % TODO Actually write the header
      %{Sink write(Header)}
      %{Sink write(HeaderMagic)}
      {Save Value FileName}
   end

   proc {SaveWithCells Value FileName Header Level}
      {SaveWithHeader Value FileName Header Level}
   end

   %%
   %% Load and its variants
   %%

   Load = BootPickle.load

   fun {LoadWithHeader URL}
      % TODO Read the header
      Header = nil
      Value = {Load URL}
   in
      Header#Value
   end

   %%
   %% Pack and its variants
   %%

   %%% {Pack Object} = BS
   %%%
   %%% Serialize an object into a ByteString. May throw an exception if the
   %%% object contains non-serializable components (e.g. cells, unbound variables)
   fun {Pack Value}
      {BootPickle.pack Value nil}
   end

   %%% {PackWithReplacements Object [From1#To1 From2#To2 ...]} = BS
   %%%
   %%% Serialize an object into a ByteString with some components temporarily
   %%% replaced. If the object contains any of FromN, they will all be replaced
   %%% by ToN before the serialization starts. Deserializing the byte string
   %%% will only give back ToN, not FromN. The Object itself will stay the same
   %%% after calling PackWithReplacements.
   PackWithReplacements = BootPickle.pack

   fun {PackWithCells Value}
      {Pack Value}
   end

   %%
   %% Unpack and its variants
   %%

   Unpack = BootPickle.unpack

end
