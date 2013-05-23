%%%
%%% Authors:
%%%  Christian Schulte <schulte@ps.uni-sb.de> 
%%%
%%% Copyright:
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

import
   Property(get)
   
export
   Return

prepare
   SHIFT = {Pow 2 64}
   
   fun {INT N}
      N * SHIFT
   end

   fun {TNI N}
      N div SHIFT
   end
   
   fun {ADD N M}
      N + M 
   end

   fun {SUB N M}
      N - M
   end

   fun {ID N}
      N
   end

define

   MAXSMALL = {Property.get limits}.'int.max'
   MINSMALL = {Property.get limits}.'int.min'

   Return=
   int([unary(proc {$}
		 MAXSMALL+1={TNI {ADD {INT MAXSMALL} {INT 1}}}
		 MAXSMALL+0={TNI {ADD {INT MAXSMALL} {INT 0}}}
		 MAXSMALL-1={TNI {SUB {INT MAXSMALL} {INT 1}}}
		 MAXSMALL+2={TNI {ADD {INT MAXSMALL} {INT 2}}}
		 MAXSMALL-2={TNI {SUB {INT MAXSMALL} {INT 2}}}
		 
		 MINSMALL+1={TNI {ADD {INT MINSMALL} {INT 1}}}
		 MINSMALL+0={TNI {ADD {INT MINSMALL} {INT 0}}}
		 MINSMALL-1={TNI {SUB {INT MINSMALL} {INT 1}}}
		 MINSMALL+2={TNI {ADD {INT MINSMALL} {INT 2}}}
		 MINSMALL-2={TNI {SUB {INT MINSMALL} {INT 2}}}
		 
		 1+MAXSMALL={TNI {ADD {INT MAXSMALL} {INT 1}}}
		 0+MAXSMALL={TNI {ADD {INT MAXSMALL} {INT 0}}}
		 ~1+MAXSMALL={TNI {SUB {INT MAXSMALL} {INT 1}}}
		 
		 1+MINSMALL={TNI {ADD {INT MINSMALL} {INT 1}}}
		 0+MINSMALL={TNI {ADD {INT MINSMALL} {INT 0}}}
		 ~1+MINSMALL={TNI {SUB {INT MINSMALL} {INT 1}}}

	      end
	      keys: [int])
	binary(proc {$}
		  (MAXSMALL-10)+10=MAXSMALL
		  (MAXSMALL+10)-10=MAXSMALL
		  
		  (MINSMALL-10)+10=MINSMALL
		  (MINSMALL+10)-10=MINSMALL
		  
		  MAXSMALL+{ID 0}={TNI {ADD {INT MAXSMALL} {INT 0}}}
		  MAXSMALL+{ID 1}={TNI {ADD {INT MAXSMALL} {INT 1}}}
		  MAXSMALL+{ID 2}={TNI {ADD {INT MAXSMALL} {INT 2}}}
		  MAXSMALL+{ID ~1}={TNI {ADD {INT MAXSMALL} {INT ~1}}}
		  MAXSMALL+{ID ~2}={TNI {ADD {INT MAXSMALL} {INT ~2}}}
		  MAXSMALL+MAXSMALL={TNI {ADD {INT MAXSMALL} {INT MAXSMALL}}}
		  
		  {ID 0}+MAXSMALL={TNI {ADD {INT MAXSMALL} {INT 0}}}
		  {ID 1}+MAXSMALL={TNI {ADD {INT MAXSMALL} {INT 1}}}
		  {ID 2}+MAXSMALL={TNI {ADD {INT MAXSMALL} {INT 2}}}
		  {ID ~1}+MAXSMALL={TNI {ADD {INT MAXSMALL} {INT ~1}}}
		  {ID ~2}+MAXSMALL={TNI {ADD {INT MAXSMALL} {INT ~2}}}
		  MAXSMALL+MAXSMALL={TNI {ADD {INT MAXSMALL} {INT MAXSMALL}}}
		  
		  MINSMALL+{ID 0}={TNI {ADD {INT MINSMALL} {INT 0}}}
		  MINSMALL+{ID 1}={TNI {ADD {INT MINSMALL} {INT 1}}}
		  MINSMALL+{ID 2}={TNI {ADD {INT MINSMALL} {INT 2}}}
		  MINSMALL+{ID ~1}={TNI {ADD {INT MINSMALL} {INT ~1}}}
		  MINSMALL+{ID ~2}={TNI {ADD {INT MINSMALL} {INT ~2}}}
		  MINSMALL+MINSMALL={TNI {ADD {INT MINSMALL} {INT MINSMALL}}}
		  
		  {ID 0}+MINSMALL={TNI {ADD {INT MINSMALL} {INT 0}}}
		  {ID 1}+MINSMALL={TNI {ADD {INT MINSMALL} {INT 1}}}
		  {ID 2}+MINSMALL={TNI {ADD {INT MINSMALL} {INT 2}}}
		  {ID ~1}+MINSMALL={TNI {ADD {INT MINSMALL} {INT ~1}}}
		  {ID ~2}+MINSMALL={TNI {ADD {INT MINSMALL} {INT ~2}}}
		  MINSMALL+MINSMALL={TNI {ADD {INT MINSMALL} {INT MINSMALL}}}

		  MAXSMALL-{ID 0}={TNI {SUB {INT MAXSMALL} {INT 0}}}
		  MAXSMALL-{ID 1}={TNI {SUB {INT MAXSMALL} {INT 1}}}
		  MAXSMALL-{ID 2}={TNI {SUB {INT MAXSMALL} {INT 2}}}
		  MAXSMALL-{ID ~1}={TNI {SUB {INT MAXSMALL} {INT ~1}}}
		  MAXSMALL-{ID ~2}={TNI {SUB {INT MAXSMALL} {INT ~2}}}
		  MAXSMALL-MAXSMALL={TNI {SUB {INT MAXSMALL} {INT MAXSMALL}}}
		  
		  MINSMALL-{ID 0}={TNI {SUB {INT MINSMALL} {INT 0}}}
		  MINSMALL-{ID 1}={TNI {SUB {INT MINSMALL} {INT 1}}}
		  MINSMALL-{ID 2}={TNI {SUB {INT MINSMALL} {INT 2}}}
		  MINSMALL-{ID ~1}={TNI {SUB {INT MINSMALL} {INT ~1}}}
		  MINSMALL-{ID ~2}={TNI {SUB {INT MINSMALL} {INT ~2}}}
		  MINSMALL-MINSMALL={TNI {SUB {INT MINSMALL} {INT MINSMALL}}}
		  
		  {ID 0}-MINSMALL={TNI {SUB {INT 0} {INT MINSMALL}}}
		  {ID 1}-MINSMALL={TNI {SUB {INT 1} {INT MINSMALL}}}
		  {ID 2}-MINSMALL={TNI {SUB {INT 2} {INT MINSMALL}}}
		  {ID ~1}-MINSMALL={TNI {SUB {INT ~1} {INT MINSMALL}}}
		  {ID ~2}-MINSMALL={TNI {SUB {INT ~2} {INT MINSMALL}}}
		  MINSMALL-MINSMALL={TNI {SUB {INT MINSMALL} {INT MINSMALL}}}

		  {ID 0}-MAXSMALL={TNI {SUB {INT 0} {INT MAXSMALL}}}
		  {ID 1}-MAXSMALL={TNI {SUB {INT 1} {INT MAXSMALL}}}
		  {ID 2}-MAXSMALL={TNI {SUB {INT 2} {INT MAXSMALL}}}
		  {ID ~1}-MAXSMALL={TNI {SUB {INT ~1} {INT MAXSMALL}}}
		  {ID ~2}-MAXSMALL={TNI {SUB {INT ~2} {INT MAXSMALL}}}
		  MAXSMALL-MAXSMALL={TNI {SUB {INT MAXSMALL} {INT MAXSMALL}}}

	       end
	       keys: [int])])
end



