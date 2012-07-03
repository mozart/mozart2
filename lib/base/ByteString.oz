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
   fun {Coder OptList Fun Input}
      Variants
      Encoding
      fun {IsVariant Opt}
         Opt == littleEndian orelse Opt == bigEndian orelse Opt == bom
      end
   in
      case {List.partition OptList IsVariant Variants}
      of H|T then
         Encoding = H
      [] nil then
         Encoding = utf8
      end

      {Fun Input Encoding Variants}
   end
in

   IsByteString = Boot_ByteString.is
   ByteString = byteString(
      is: IsByteString
      make: fun {$ V} {Boot_ByteString.encode V latin1 nil} end
      get: Value.'.'
      append: UnicodeString.append
      slice: UnicodeString.slice
      width: UnicodeString.length
      length: UnicodeString.length
      toString: UnicodeString.toList
      toStringWithTail: UnicodeString.toListWithTail

      strchr: fun {$ BS From Chr}
         if {IsInt Chr} then
            {UnicodeString.search BS From Chr $ _}
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


