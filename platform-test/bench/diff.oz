%%%
%%% Authors:
%%%   Christian Schulte, <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 2000
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

   fun {Diff A X}
      case A
      of '-'(A B) then '-'({Diff A X} {Diff B X})
      [] '+'(A B) then '+'({Diff A X} {Diff B X})
      [] '*'(A B) then '+'('*'({Diff A X} B) '*'(A {Diff B X}))
      [] '/'(A B) then '/'('-'('*'({Diff A X} B) '*'(A {Diff B X})) '*'(B B))
      [] ln(A)    then '/'({Diff A X} A)
      [] sin(A)   then '*'(cos(A) {Diff A X})
      [] cos(A)   then '*'('*'(~1 sin(A)) {Diff A X})
      [] exp(A)   then '*'(exp(A) {Diff A X})
      [] '^'(A N) then '*'('*'(N '^'(A '-'(N 1))) {Diff A X})
      [] !X       then 1
      else 0
      end
   end

   fun {Size A}
      case A
      of '-'(A B) then {Size A}+{Size B}+1
      [] '+'(A B) then {Size A}+{Size B}+1
      [] '*'(A B) then {Size A}+{Size B}+1
      [] '/'(A B) then {Size A}+{Size B}+1
      [] ln(A)    then {Size A}+1
      [] sin(A)   then {Size A}+1
      [] cos(A)   then {Size A}+1
      [] exp(A)   then {Size A}+1
      [] '^'(A _) then {Size A}+2
      else 1
      end
   end
   
   T = '/'(ln(cos('*'(x x)))
	   exp(exp('*'('^'(x 3) sin('*'(x ln(x)))))))

   Return = differentiate(proc {$}
			     {ForThread 1 5 1 fun {$ T I}
						 T1={Diff T x}
					      in
						 {Size T _} {Size T1 _}
						 {Size T _} {Size T1 _}
						 T1
					      end T}=_
			  end
			  keys:[bench differentiate]
			  bench:1)

end
