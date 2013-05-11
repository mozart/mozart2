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

%%
%% This defines a function `GetBuiltinInfo' that returns information
%% about a given builtin A.  Raises an exception if no A is not a builtin
%% value, else returns a record as follows:
%%
%%    builtin(types: [...] det: [...] imods: [bool] ...)
%%
%% meaning: A denotes a known builtin with argument types and determinancy
%% as given.  The following features may or may not be contained in the
%% record, as appropriate:
%%
%%    imods: [bool]
%%       for each input argument for which this list has a `true',
%%       no assumptions may be made about the contents of the
%%       corresponding register after the builtin application.
%%    test: B
%%       if this feature is present and B is true, then this
%%       builtin may be used as argument to the testBI instruction.
%%    negated: A
%%       if this feature is present then A is the name of a builtin
%%       that returns the negated result from this builtin.
%%    doesNotReturn: B
%%       if this feature is present and B is true, then the
%%       instructions following the call to A are never executed
%%       unless branched to from elsewhere.
%%

functor

export
   getInfo: GetBuiltinInfo

import
   CompilerSupport(getBuiltinInfo:BootGetBuiltinInfo)

define

   fun {NewInfoToOldInfo Info}
      case Info
      of builtin(arity:Arity params:Params ...) then
         InParams OutParams
         {List.takeDropWhile Params
          fun {$ param(kind:K ...)} K == 'in' end
          ?InParams ?OutParams}

         IArity = {Length InParams}
         OArity = {Length OutParams}
         IArity + OArity = Arity

         Types = {Map Params fun {$ X} value end}
         Det = {Map Params fun {$ X} any end}
         IMods = {Map InParams fun {$ X} false end}
      in
         builtin(iarity:IArity oarity:OArity types:Types det:Det imods:IMods)
      end
   end

   fun {GetBuiltinInfo Builtin}
      {NewInfoToOldInfo {BootGetBuiltinInfo Builtin}}
   end

end
