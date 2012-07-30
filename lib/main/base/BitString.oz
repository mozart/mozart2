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
   BitStringID = {NewUniqueName bitStringID}

   fun {NewBitString Underlying}
      {NewChunk bitString(BitStringID:Underlying)}
   end

   fun {GetUnderlying BS}
      if {IsBitString BS} then
         BS.BitStringID
      else
         raise typeError('BitString' BS) end
      end
   end

   fun {BitStringMake W Is}
      Underlying = {BitArray.new 0 W-1}
   in
      {ForAll Is
       proc {$ I}
          {BitArray.set Underlying I}
       end}
      {NewBitString Underlying}
   end

   fun {BitStringConj L R}
      LU = {GetUnderlying L}
      RU = {GetUnderlying R}
      ResU = {BitArray.clone LU}
   in
      {BitArray.conj ResU RU}
      {NewBitString ResU}
   end

   fun {BitStringDisj L R}
      LU = {GetUnderlying L}
      RU = {GetUnderlying R}
      ResU = {BitArray.clone LU}
   in
      {BitArray.disj ResU RU}
      {NewBitString ResU}
   end

   fun {BitStringNega BS}
      U = {GetUnderlying BS}
      ResU = {BitArray.clone U}
   in
      {For {BitArray.low ResU} {BitArray.high ResU} 1
       proc {$ I}
          if {BitArray.test ResU I} then
             {BitArray.clear ResU I}
          else
             {BitArray.set ResU I}
          end
       end}
      {NewBitString ResU}
   end

   fun {BitStringGet BS I}
      {BitArray.test {GetUnderlying BS} I}
   end

   fun {BitStringPut BS I B}
      U = {GetUnderlying BS}
   in
      if {BitArray.test U I} == B then
         BS
      else
         ResU = {BitArray.clone U}
      in
         if B then
            {BitArray.set ResU I}
         else
            {BitArray.clear ResU I}
         end
         {NewBitString ResU}
      end
   end

   fun {BitStringWidth BS}
      {BitArray.high {GetUnderlying BS}} + 1
   end

   fun {BitStringToList BS}
      {BitArray.toList {GetUnderlying BS}}
   end
in
   fun {IsBitString X}
      {IsChunk X} andthen {HasFeature X BitStringID}
   end

   BitString = bitString(
      is:     IsBitString
      make:   BitStringMake
      conj:   BitStringConj
      disj:   BitStringDisj
      nega:   BitStringNega
      'and':  BitStringConj
      'or':   BitStringDisj
      'not':  BitStringNega
      get:    BitStringGet
      put:    BitStringPut
      width:  BitStringWidth
      toList: BitStringToList
   )
end
