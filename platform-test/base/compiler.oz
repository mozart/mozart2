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
%%%   http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%   http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
export
   Return
define
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
                    keys:[compiler unnesting fixedBug])
             localEnvInThreads(proc {$}
                                  fun {X Y} Y end
                                  S
                               in
                                  {proc {$}
                                      thread
                                         case S of 1 then skip else skip end
                                      end
                                      {X {X S} _}
                                   end}
                               end
                               keys:[compiler codeGen fixedBug])
             clippedTestTree(proc {$}
                                {fun {$ X}
                                    case X of a(_ ...) then 1
                                    [] b then 2
                                    elseif {IsRecord X} then 3
                                    else unit
                                    end
                                 end x} = 3
                             end
                             keys: [compiler codeGen fixedBug])])
end
