%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 2000
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
export
   Return
define
   proc {Loop N}
      if N==0 then skip else
	 {Loop N-1}
      end
   end
   proc {BigLoop N1 N2}
      if N1==0 then skip else
	 {Loop N2}
	 {BigLoop N1-1 N2}
      end
   end
   Return = rec([normal(proc {$}
			   {BigLoop 10 1000000}
			end
			keys:[bench rec]
			bench:1)])
end
