%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
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


declare
   Tuple MakeTuple IsTuple
in


%%
%% Global
%%
IsTuple   = {`Builtin` 'Tuple.is'   2}
MakeTuple = {`Builtin` 'Tuple.make' 3}


%%
%% Module
%%
local
   proc {Copy N O T1 T2}
      case N==0 then skip else T2.(N+O)=T1.N {Copy N-1 O T1 T2} end
   end
   proc {Append T1 T2 ?T3}
      W1={Width T1} W2={Width T2}
   in
      case W1==0 then T3=T2
      elsecase W2==0 then T3={Adjoin T1 T2}
      else
         T3={MakeTuple {Label T2} W1+W2}
         {Copy W1 0 T1 T3} {Copy W2 W1 T2 T3}
      end
   end
   proc {TupleToArray I T A}
      case I>0 then {Array.put A I T.I} {TupleToArray I-1 T A}
      else skip
      end
   end
in
   Tuple = tuple(make:    MakeTuple
                 append:  Append
                 is:      IsTuple
                 toArray: fun {$ T}
                             W={Width T}
                             A={Array.new 1 W unit}
                          in
                             {TupleToArray W T A}
                             A
                          end)
end


%%
%% Run time library
%%
local
   proc {Match Xs I T}
      case Xs of nil then skip
      [] X|Xr then T.I=X {Match Xr I+1 T}
      end
   end

   proc {DoTuple L Xs I T}
      T={MakeTuple L I} {Match Xs 1 T}
   end
in
   {`runTimePut` 'tuple' DoTuple}
end
