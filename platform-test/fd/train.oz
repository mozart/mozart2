%%%
%%% Authors:
%%%   Gert Smolka <smolka@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Gert Smolka, 1998
%%%   Christian Schulte, 1998
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
import FD Search Space
export Return
prepare
   TrainSol = [r(a:1895 b:1904 n:1918 x:1) 
	       r(a:1896 b:1905 n:1920 x:1)]
define

   fun {Year}
      {FD.int 1700#1999}
   end

   fun {Day}
      {FD.int 1#365}
   end

   fun {DS Y}
      [A B C D] = {FD.list 4 0#9}
      Q         = {FD.int 0#36}
   in
      1000*A + 100*B +10*C + D =: Y
      Q =: A+B+C+D
      Q
   end
   
   fun {MakeTrain Mode}

      Third = case Mode
	      of reified then
		 fun {$ X N}
		    proc {$ _}
		       C  = {Year}  % C's year of birth
		       Y  = {Day}   % C's day of birth
		       Q  = {DS C}
		    in
		       {FD.disj
			{FD.conj Y<:X  Q=:N-C}
			{FD.conj Y>:X  Q=:N-C-1}
			1}
		       {FD.distribute split [Y C]}
		    end
		 end
	      [] combinator then
		 fun {$ X N}
		    proc {$ _}
		       C  = {Year}  % C's year of birth
		       Y  = {Day}   % C's day of birth
		       Q  = {DS C}
		    in
		       thread
			  or Y<:X  Q=:N-C  []  Y>:X  Q=:N-C-1 end
		       end
		       {FD.distribute split [Y C]}
		    end
		 end
	      end

      proc {NoThird X N}
	 thread
	    {Search.base.one {Third X N} nil}
	 end
      end

   in
      proc {$ S}
	 N = {Year}  % year of train ride
	 X = {Day}   % day of train ride
	 A = {Year}  % A's year of birth
	 B = {Year}  % B's year of birth
      in
	 S=r(a:A b:B n:N x:X)
	 N >=: 1825   % no trains before that year
	 {DS A} =: N-A
	 {DS B} =: N-B
	 A <: B       % wlog
	 {NoThird X N}
	 {FD.distribute split [A B X]}
      end
   end

   fun {Trace P}
      S={Space.new P}
      D={Dictionary.new}
      proc {Inc F}
	 {Dictionary.put D F {Dictionary.condGet D F 0}+1}
      end
      proc {Explore S}
	 case {Space.ask S}
	 of failed          then {Inc failed}
	 [] succeeded       then {Inc succeeded}
	 [] alternatives(N) then C={Space.clone S} in
	    {Inc alternatives}
	    {Space.commit S 1} {Space.commit C 2#N}
	    {Explore S} {Explore C}
	 end
      end
   in
      {Explore S}
      {Dictionary.toRecord stat D}
   end
   
   Return =
   fd([train([reified(equal(fun {$}
			       {Search.base.all {MakeTrain reified}}
			    end
			    TrainSol)
		      keys: [fd space])
	      combinator(equal(fun {$}
				  {Search.base.all {MakeTrain combinator}}
			       end
			       TrainSol)
			 keys: [fd space])
	      compare(entailed(proc {$}
				  S1={Trace {MakeTrain reified}}
				  S2={Trace {MakeTrain combinator}}
			       in
				  S1=S2
				  S1=stat(alternatives:3884
					  failed:3883
					  succeeded:2)
			       end)
		      keys: [fd space])])])
   
end
