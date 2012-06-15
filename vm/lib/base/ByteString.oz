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
   fun {Coder OptList Fun Input Encoding IsLE HasBOM}
      case OptList
      of nil then
         {Fun Input Encoding IsLE HasBOM}
      [] H|T then
         case H
         of littleEndian then
            {Coder T Fun Input Encoding true HasBOM}
         [] bigEndian then
            {Coder T Fun Input Encoding false HasBOM}
         [] bom then
            {Coder T Fun Input Encoding IsLE true}
         else
            {Coder T Fun Input H IsLE HasBOM}
         end
      end
   end
in

   ByteString = byteString(
      is: IsByteString
      make: fun {$ V} {Boot_ByteString.encode V latin1 true false} end
      get: Boot_ByteString.get
      append: Boot_ByteString.append
      slice: Boot_ByteString.slice
      width: Boot_ByteString.length
      length: Boot_ByteString.length
      toString: fun {$ BS} {Boot_ByteString.decode BS latin1 true false} end
      %toStringWithTail: ---
      strchr: Boot_ByteString.strchr

      encode: fun {$ OptList V}
                 {Coder OptList Boot_ByteString.encode V utf8 true false}
              end
      decode: fun {$ OptList BS}
                 {Coder OptList Boot_ByteString.decode BS utf8 true false}
              end
   )

end
