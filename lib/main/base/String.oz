%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%
%% Module
%%

local
   proc {Token Is J ?T ?R}
      case Is of nil then T=nil R=nil
      [] I|Ir then
         if I==J then T=nil R=Ir
         else Tr in T=I|Tr {Token Ir J Tr R}
         end
      end
   end

   fun {Tokens Is C Js Jr}
      case Is of nil then Jr=nil
         case Js of nil then nil else [Js] end
      [] I|Ir then
         if I==C then NewJs in
            Jr=nil Js|{Tokens Ir C NewJs NewJs}
         else NewJr in
            Jr=I|NewJr {Tokens Ir C Js NewJr}
         end
      end
   end

   fun {StringIsAtom Is}
      case Is of nil then true
      [] I|Ir then I\=0 andthen {StringIsAtom Ir}
      end
   end

in
   String = string(is:      IsString
                   isAtom:  StringIsAtom
                   toAtom:  StringToAtom
                   isInt:   fun {$ S}
                               try {StringToInt S _} true
                               catch _ then false
                               end
                            end
                   toInt:   StringToInt
                   isFloat: fun {$ S}
                               try {StringToFloat S _} true
                               catch _ then false
                               end
                            end
                   toFloat: StringToFloat
                   token:   Token
                   tokens:  fun {$ S C}
                               Ss in {Tokens S C Ss Ss}
                            end)
end
