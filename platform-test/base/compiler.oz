%%%
%%% Authors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%   $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
export
   Return
body
   Return =
   compiler([unnestEquationInRecord(equal(proc {$ B}
                                             Y
                                             fun {P}
                                                B = {IsDet Y} Y
                                             end
                                          in
                                             _ = f({P} Y=y)
                                          end true)
                                    keys: [compiler unnesting fixedBug])
             unnest(proc {$}
                       fun {F1 X} X = 1 1 end
                       fun {F2 X} {Wait X} 2 end
                       X
                    in
                       _ = [{F1 X} {F2 X}]
                    end
                    keys:[compiler unnesting fixedBug])])
end
