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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


declare
   Tuple MakeTuple IsTuple
   `tuple`
in


%%
%% Global
%%
IsTuple   = {`Builtin` 'IsTuple'   2}
MakeTuple = {`Builtin` 'MakeTuple' 3}


%%
%% Module
%%
Tuple = tuple(make: MakeTuple
              is:   IsTuple)


%%
%% Compiler Expansions
%%
local
   proc {Match Xs I T}
      case Xs of nil then skip
      [] X|Xr then T.I=X {Match Xr I+1 T}
      end
   end
in
   proc {`tuple` L Xs I T}
      T={MakeTuple L I} {Match Xs 1 T}
   end
end
