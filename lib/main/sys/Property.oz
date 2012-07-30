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

export
   Get
   CondGet
   Put

define

   Properties = {NewDictionary}

   fun {Get Prop}
      {Dictionary.get Properties Prop}
   end

   fun {CondGet Prop Default}
      {Dictionary.condGet Properties Prop Default}
   end

   proc {Put Prop Value}
      {Dictionary.put Properties Prop Value}
   end

   % Initial properties

   % Why these? Because they are used in the compiler and module manager

   {Put 'oz.version' '2.0.0'}
   {Put 'oz.date' '20120721124706'}

   {Put 'oz.configure.home' '.'}

   {Put 'platform.name' 'unknown'}
   {Put 'platform.os' 'linux'}

   {Put 'print' print(width:20 depth:10)}
   {Put 'errors' errors(width:20 depth:10)}
   {Put 'errors.thread' 40}

   {Put 'limits.bytecode.xregisters' 65535}

end
