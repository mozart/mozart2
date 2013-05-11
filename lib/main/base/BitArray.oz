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
   BitArrayID = {NewUniqueName bitArrayID}

   ArrayGetLow = Boot_Array.low
   ArrayGetHigh = Boot_Array.high

   fun {NewBitArrayInternal Underlying}
      {NewChunk bitArray(BitArrayID:Underlying)}
   end

   fun {NewBitArray Low High}
      {NewBitArrayInternal {NewArray Low High false}}
   end

   fun {GetUnderlying BA}
      if {IsBitArray BA} then
         BA.BitArrayID
      else
         raise typeError('BitArray' BA) end
      end
   end

   proc {BitArraySet BA I}
      {Put {GetUnderlying BA} I true}
   end

   proc {BitArrayClear BA I}
      {Put {GetUnderlying BA} I false}
   end

   fun {BitArrayTest BA I}
      {Get {GetUnderlying BA} I}
   end

   fun {BitArrayLow BA}
      {ArrayGetLow {GetUnderlying BA}}
   end

   fun {BitArrayHigh BA}
      {ArrayGetHigh {GetUnderlying BA}}
   end

   fun {BitArrayClone BA}
      {NewBitArrayInternal {Array.clone {GetUnderlying BA}}}
   end

   proc {PrepareBinOp L R ?LU ?RU ?Low ?High}
      LU = {GetUnderlying L}
      RU = {GetUnderlying R}
      Low = {ArrayGetLow LU}
      High = {ArrayGetHigh LU}

      if {ArrayGetLow RU} \= Low orelse {ArrayGetHigh RU} \= High then
         raise bitArrayBoundsMismatch(L R) end
      end
   end

   fun {BitwiseBinOp P}
      proc {$ L R}
         LU RU Low High
      in
         {PrepareBinOp L R ?LU ?RU ?Low ?High}
         {For Low High 1 proc {$ I} {P LU RU I} end}
      end
   end

   BitArrayDisj = {BitwiseBinOp
                   proc {$ LU RU I}
                      if {Get RU I} then
                         {Put LU I true}
                      end
                   end}

   BitArrayConj = {BitwiseBinOp
                   proc {$ LU RU I}
                      if {Get RU I} then skip else
                         {Put LU I false}
                      end
                   end}

   BitArrayNimpl = {BitwiseBinOp
                    proc {$ LU RU I}
                       if {Get RU I} then
                          {Put LU I false}
                       end
                    end}

   fun {BitArrayDisjoint L R}
      LU RU Low High
      fun {Loop I}
         if I > High then
            true
         elseif {Get LU I} andthen {Get RU I} then
            false
         else
            {Loop I+1}
         end
      end
   in
      {PrepareBinOp L R ?LU ?RU ?Low ?High}
      {Loop Low}
   end

   fun {BitArraySubsumes L R}
      LU = {GetUnderlying L}
      RU = {GetUnderlying R}
      LLow = {ArrayGetLow LU}
      LHigh = {ArrayGetHigh LU}
      RLow = {ArrayGetLow RU}
      RHigh = {ArrayGetHigh RU}
   in
      if LLow > RLow orelse LHigh < RHigh then
         false
      else
         fun {Loop I}
            if I > RHigh then
               true
            elseif {Get RU I} andthen {Not {Get LU I}} then
               false
            else
               {Loop I+1}
            end
         end
      in
         {Loop RLow}
      end
   end

   fun {BitArrayCard BA}
      U = {GetUnderlying BA}
      Low = {ArrayGetLow U}
      High = {ArrayGetHigh U}

      fun {Loop I Acc}
         if I > High then
            Acc
         elseif {Get U I} then
            {Loop I+1 Acc+1}
         else
            {Loop I+1 Acc}
         end
      end
   in
      {Loop Low 0}
   end

   fun {BitArrayToList BA}
      U = {GetUnderlying BA}
      Low = {ArrayGetLow U}
      High = {ArrayGetHigh U}

      fun {Loop I}
         if I > High then
            nil
         elseif {Get U I} then
            I|{Loop I+1}
         else
            {Loop I+1}
         end
      end
   in
      {Loop Low}
   end

   fun {BitArrayComplementToList BA}
      U = {GetUnderlying BA}
      Low = {ArrayGetLow U}
      High = {ArrayGetHigh U}

      fun {Loop I}
         if I > High then
            nil
         elseif {Get U I} then
            {Loop I+1}
         else
            I|{Loop I+1}
         end
      end
   in
      {Loop Low}
   end

   local
      fun {MinMaxProc Prev X}
         {Min Prev.1 X}#{Max Prev.2 X}
      end

      fun {MinMax Xs}
         {List.foldL Xs.2 MinMaxProc Xs.1#Xs.1}
      end
   in
      fun {BitArrayFromList Is}
         Low#High = {MinMax Is}
         Res = {NewBitArray Low High}
      in
         {ForAll Is
          proc {$ I}
             {BitArraySet Res I}
          end}
         Res
      end
   end
in
   fun {IsBitArray X}
      {IsChunk X} andthen {HasFeature X BitArrayID}
   end

   BitArray = bitArray(
      new:              NewBitArray
      is:               IsBitArray
      set:              BitArraySet
      clear:            BitArrayClear
      test:             BitArrayTest
      low:              BitArrayLow
      high:             BitArrayHigh
      clone:            BitArrayClone
      disj:             BitArrayDisj
      conj:             BitArrayConj
      nimpl:            BitArrayNimpl
      disjoint:         BitArrayDisjoint
      subsumes:         BitArraySubsumes
      card:             BitArrayCard
      toList:           BitArrayToList
      fromList:         BitArrayFromList
      complementToList: BitArrayComplementToList
   )
end
