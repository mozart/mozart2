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
   Boot_Property at 'x-oz://boot/Property'

export
   Register
   RegisterAggregate
   Get
   CondGet
   Put

define

   UserProperties = {NewDictionary}

   proc {Register Prop Getter Setter}
      if {Dictionary.member UserProperties Prop} then
         raise error(system(registerProperty Prop) debug:unit) end
      else
         {Dictionary.put UserProperties Prop accessors(Getter Setter)}
      end
   end

   proc {RegisterAggregate Prop Fields}
      Desc
      fun {Getter}
         {Record.map Desc Get}
      end
      proc {Setter V}
         {Record.forAllInd V
          proc {$ Feat Value}
             {Put Desc.Feat Value}
          end}
      end
   in
      Desc = {MakeRecord Lab Fs}
      for F in Fields do
         Desc.F = {VirtualString.toAtom Prop#'.'#F}
      end
      {Register Prop Getter Setter}
   end

   fun {Lookup Prop ?Value}
      SysValue
   in
      if {Boot_Property.get Prop ?SysValue} then
         Value = SysValue
         true
      elsecase {Dictionary.condGet UserProperties Prop undefined}
      of value(V) then
         Value = V
         true
      [] accessors(Getter _) then
         if Getter == unit then
            raise error(system(condGetProperty Prop) debug:unit) end
         else
            Value = {Getter}
            true
         end
      else
         false
      end
   end

   fun {Get Prop}
      Value
   in
      if {Lookup Prop ?Value} then
         Value
      else
         raise system(system(getProperty Prop) debug:unit) end
      end
   end

   fun {CondGet Prop Default}
      Value
   in
      if {Lookup Prop ?Value} then
         Value
      else
         Default
      end
   end

   proc {Put Prop Value}
      if {Boot_Property.put Prop Value} then
         skip
      elsecase {Dictionary.condGet UserProperties Prop undefined}
      of accessors(_ Setter) then
         if Setter == unit then
            raise error(system(putProperty Prop) debug:unit) end
         else
            {Setter Value}
         end
      else
         {Dictionary.put UserProperties Prop value(Value)}
      end
   end

   % Some aggregate properties

   {RegisterAggregate 'print' [width depth]}

   {RegisterAggregate 'errors' [handler debug 'thread' width depth]}

   {RegisterAggregate 'limits' ['int.min' 'int.max' 'bytecode.xregisters']}

   {RegisterAggregate 'application' [args url gui]}

   {RegisterAggregate 'platform' [name os arch]}

end
