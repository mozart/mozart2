%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1999
%%%   Christian Schulte, 1999
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

functor
import Search FS
export Return
define
   N=20

   proc {BugSolution L}
      {List.make N L}
      {List.forAllInd L proc {$ I Var}
                           Var={FS.var.upperBound 1#N}
                           {FS.include I Var}
                        end}
      {List.foldL L
       fun {$ Vars Var}
          thread
             if Vars==nil then skip else
                or {ForAll Vars proc {$ V} V=Var end}
                [] {ForAll Vars proc {$ V} {FS.disjoint V Var} end}
                end
             end
          end
          Var|Vars
       end nil _}
      {FS.distribute naive L}
   end
   Return = fs([denys(entailed(proc {$}
                                  Ss={Search.base.all BugSolution}
                               in
                                  {Length Ss}=20
                               end)
                      keys: [space fs])])
end