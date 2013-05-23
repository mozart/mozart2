%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
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

import
   Compiler
export
   Return

define
   Return = compiler([
		      simple(proc {$}
				E = {New Compiler.engine init()}
			     in
				{For 1 100 1
				 proc {$ I}
				    {E enqueue(feedVirtualString('declare X='#I))}
				 end}
				{Wait {E enqueue(ping($))}}
			     end
			     keys:[bench compiler]
			     bench:1)
		     ])
end
