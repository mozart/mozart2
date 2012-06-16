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
   fun {Coder OptList Fun Input EncNum IsLE HasBOM}
      case OptList
      of nil then
         {Fun Input EncNum IsLE HasBOM}
      [] H|T then
         case H
         of iso8859_1 then
            {Coder T Fun Input 0 IsLE HasBOM}
         [] latin1 then
            {Coder T Fun Input 0 IsLE HasBOM}
         [] utf8 then
            {Coder T Fun Input 1 IsLE HasBOM}
         [] utf16 then
            {Coder T Fun Input 2 IsLE HasBOM}
         [] utf32 then
            {Coder T Fun Input 3 IsLE HasBOM}
         [] littleEndian then
            {Coder T Fun Input EncNum true HasBOM}
         [] bigEndian then
            {Coder T Fun Input EncNum false HasBOM}
         [] bom then
            {Coder T Fun Input EncNum IsLE true}
         end
      end
   end
in

   IsByteString = Boot_ByteString.is
   ByteString = byteString(
      is: IsByteString
      make: fun {$ V} {Boot_ByteString.encode V 0 true false} end
      get: Boot_ByteString.get
      append: Boot_ByteString.append
      slice: Boot_ByteString.slice
      width: Boot_ByteString.length
      length: Boot_ByteString.length
      toString: fun {$ BS} {Boot_ByteString.decode BS 0 true false} end
      %toStringWithTail: ---
      strchr: Boot_ByteString.strchr

      encode: fun {$ OptList V}
         {Coder OptList Boot_ByteString.encode V 1 true false}
      end
      decode: fun {$ OptList BS}
         {Coder OptList Boot_ByteString.decode BS 1 true false}
      end
   )

end


