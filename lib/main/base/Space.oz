%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
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

local
   Inject = Boot_Space.inject

   proc {Fail _} fail end

   fun {RegisterBase N}
      case N
      of 1 then choice 1 end
      [] 2 then choice 1 [] 2 end
      [] 3 then choice 1 [] 2 [] 3 end
      [] 4 then choice 1 [] 2 [] 3 [] 4 end
      [] 5 then choice 1 [] 2 [] 3 [] 4 [] 5 end
      [] 6 then choice 1 [] 2 [] 3 [] 4 [] 5 [] 6 end
      [] 7 then choice 1 [] 2 [] 3 [] 4 [] 5 [] 6 [] 7 end
      [] 8 then choice 1 [] 2 [] 3 [] 4 [] 5 [] 6 [] 7 [] 8 end
      end
   end

   fun {Register X}
      if {IsInt X} then {RegisterBase X}
      else X.{RegisterBase {Width X}}
      end
   end

in

   Space = space(is:         IsSpace
                 new:        Boot_Space.new
                 ask:        Boot_Space.ask
                 askVerbose: Boot_Space.askVerbose
                 clone:      Boot_Space.clone
                 merge:      Boot_Space.merge
                 inject:     Inject
                 commit:     Boot_Space.commit
                 discard:    proc {$ S}
                                {Inject S Fail}
                             end
                 waitStable: proc {$}
                                choice skip end
                             end
                 register:   Register)

end
