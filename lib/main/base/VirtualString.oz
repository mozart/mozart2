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
   %% The awful ChangeSign function - kept for backward compatibility
   local
      proc {ChangeSignAll I V S NewV}
         if I>0 then
            NewV.I={ChangeSign V.I S}
            {ChangeSignAll I-1 V S NewV}
         end
      end

      fun {ChangeLast Is S Js Jr}
         case Is of nil then Jr=nil Js
         [] I|Ir then
            case I of &~ then Jr=nil Js#S#Ir
            else Jt in Jr=I|Jt {ChangeLast Ir S Js Jt}
            end
         end
      end

      fun {ChangeSignFloat Is S}
         case Is of &~|Ir then Js in S#{ChangeLast Ir S Js Js}
         else Js in {ChangeLast Is S Js Js}
         end
      end
   in
      fun {ChangeSign V S}
         case {Value.type V}
         of int then if V<0 then S#~V else V end
         [] float then {ChangeSignFloat {Float.toString V} S}
         [] atom then V
         [] byteString then V
         [] tuple then
            case {Label V}
            of '#' then W={Width V} NewV={MakeTuple '#' W} in
               {ChangeSignAll W V S NewV}
               NewV
            [] '|' then V
            end
         end
      end
   end
in

   VirtualString = virtualString(
      is: IsVirtualString
      toCompactString: Boot_VirtualString.toCompactString
      toString: fun {$ VS}
                  {Boot_VirtualString.toCharList VS nil}
               end
      toStringWithTail: Boot_VirtualString.toCharList
      toAtom: Boot_VirtualString.toAtom
      length: Boot_VirtualString.length

      % Compatibility - this should not exist in an ideal world
      toByteString: fun {$ V} {ByteString.make V} end
      changeSign: ChangeSign
   )

end
