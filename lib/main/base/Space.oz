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
   Inject       = Boot_Space.inject

   proc {Fail _} fail end

\ifdef NEW_REGISTER
   BootRegister = Boot_Space.register
\else
   fun {BootRegister N}
      case N
      of 1 then choice 1 end
      [] 2 then choice 1 [] 2 end
      [] 3 then choice 1 [] 2 [] 3 end
      [] 4 then choice 1 [] 2 [] 3 [] 4 end
      end
   end
\endif

   fun {Register X}
      if {IsInt X} then {BootRegister X}
      else X.{BootRegister {Width X}}
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
                                {Wait {Register 1}}
                             end
                 register:   Register)

end
