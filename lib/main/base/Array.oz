%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
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


local
   proc {ArrayToRecord I A T}
      T.I={Get A I} case I>1 then {ArrayToRecord I-1 A T} else skip end
   end
   proc {ArrayToArray L H A1 A2}
      case L>H then skip else
         {Put A2 L {Get A1 L}}
         {ArrayToArray L+1 H A1 A2}
      end
   end
   fun {MakePairs L H A}
      case L>H then nil
      else L#{Get A L}|{MakePairs L+1 H A}
      end
   end
   GetLow  = Boot_Array.low
   GetHigh = Boot_Array.high
in

   Array = array(new:      NewArray
                 is:       IsArray
                 put:      Put
                 get:      Get
                 low:      GetLow
                 high:     GetHigh
                 clone:    fun {$ A1}
                              L={GetLow A1} H={GetHigh A1}
                              A2={NewArray L H unit}
                           in
                              {ArrayToArray L H A1 A2}
                              A2
                           end
                 toRecord: fun {$ L A}
                              Lo={GetLow A} Hi={GetHigh A}
                              R
                           in
                              case Lo==1 then
                                 R={MakeTuple L Hi}
                                 {ArrayToRecord Hi A R}
                              else
                                 R={List.toRecord L {MakePairs Lo Hi A}}
                              end
                              R
                           end)


end
