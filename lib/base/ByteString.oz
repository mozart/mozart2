%%%
%%% Authors:
%%%   Kenny Chan <kennytm@gmail.com>
%%%
%%% Copyright:
%%%   Kenny Chan, 2012
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%
%% Module
%%

local
   ByteStringLength = Boot_VirtualString.length

   fun {ByteStringToStringWithTail BS From To Tail}
      if From < To then
         {Boot_String.charAt BS From} |
            {ByteStringToStringWithTail BS From+1 To Tail}
      else
         Tail
      end
   end

   fun {IsVariant Opt}
      Opt == littleEndian orelse Opt == bigEndian orelse Opt == bom
   end

   fun {Coder OptList Fun Input}
      Variants
      Encoding
   in
      case {List.partition OptList IsVariant Variants}
      of H|_ then
         Encoding = H
      [] nil then
         Encoding = utf8
      end

      {Fun Input Encoding Variants}
   end
in

   ByteString = byteString(
      is: IsByteString
      make: fun {$ V} {Boot_ByteString.encode V latin1 nil} end
      get: Boot_String.charAt
      append: Boot_String.append
      slice: Boot_String.slice
      width: ByteStringLength
      length: ByteStringLength
      toString:
         fun {$ BS}
            {ByteStringToStringWithTail BS 0 {ByteStringLength BS} nil}
         end
      toStringWithTail:
         fun {$ BS Tail}
            {ByteStringToStringWithTail BS 0 {ByteStringLength BS} Tail}
         end

      strchr: fun {$ BS From Chr}
                 if {IsInt Chr} then
                    {Boot_String.search BS From Chr $ _}
                 else
                    raise typeError('char' Chr) end
                 end
              end

      encode: fun {$ OptList V}
                 {Coder OptList Boot_ByteString.encode V}
              end
      decode: fun {$ OptList BS}
                 {Coder OptList Boot_ByteString.decode BS}
              end
   )

end
