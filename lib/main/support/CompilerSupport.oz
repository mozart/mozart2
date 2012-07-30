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
   Boot_CompilerSupport at 'x-oz://boot/CompilerSupport'
   Boot_Name(newNamed:NewNamedName) at 'x-oz://boot/Name'

export
   ChunkArity
   FeatureLess
   ConcatenateAtomAndInt
   IsBuiltin
   GetBuiltinInfo
   NameVariable
   NewCopyableName
   IsCopyableName
   IsUniqueName
   NewProcedureRef
   NewCopyableProcedureRef
   IsCopyableProcedureRef
   IsLocalDet
   NewCodeArea
   NewAbstraction
   MakeArity
   NewPatMatWildcard
   NewPatMatCapture

define

   proc {ChunkArity Chunk ?ArityList}
      % TODO
      raise notImplemented('ChunkArity') end
   end

   FeatureLess = Boot_CompilerSupport.featureLess

   fun {ConcatenateAtomAndInt A I}
      case A
      of nil then
         {VirtualString.toAtom "nil"#I}
      [] '#' then
         {VirtualString.toAtom "#"#I}
      else
         {VirtualString.toAtom A#I}
      end
   end

   IsBuiltin = Boot_CompilerSupport.isBuiltin
   GetBuiltinInfo = Boot_CompilerSupport.getBuiltinInfo

   proc {NameVariable V A}
      % TODO
      skip
   end

   fun {NewCopyableName A}
      % Apparently, can be replaced by a NamedName
      {NewNamedName A}
   end

   fun {IsCopyableName Value}
      {Wait Value}
      false
   end

   IsUniqueName = Boot_CompilerSupport.isUniqueName

   fun {NewProcedureRef}
      unit
   end

   NewCopyableProcedureRef = NewProcedureRef

   fun {IsCopyableProcedureRef Value}
      {Wait Value}
      false
   end

   % This should never stop, i.e., not start a network request
   % But since we have not network yet ... it is equivalent to IsDet
   IsLocalDet = IsDet

   NewCodeArea = Boot_CompilerSupport.newCodeArea
   NewAbstraction = Boot_CompilerSupport.newAbstraction

   fun {MakeArity L Fs}
      {Boot_CompilerSupport.makeArityDynamic L {List.toTuple '#' Fs}}
   end

   NewPatMatWildcard = Boot_CompilerSupport.newPatMatWildcard
   NewPatMatCapture = Boot_CompilerSupport.newPatMatCapture

end
