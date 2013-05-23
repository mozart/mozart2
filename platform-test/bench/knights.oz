%%%
%%% Authors:
%%%   Gert Smolka, <schulte@ps.uni-sb.de>
%%%   Christian Schulte, <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Gert Smolka, 1997-2000
%%%   Christian Schulte, 1997-2000
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
   FD Search

export
   Return

define

   fun {Knights N}
      NN = N*N
      %% The fields of the board are numbered from 1..NN
      %% according to their lexicographic order, that is,
      %% (1,1), (1,2), ..., (2,1), (2,2), ..., (N,N)
      %%
      %% Field: X x Y --> Field
      fun {Field X Y}
	 X*N + Y
      end
      %% Neighbours: Field --> List of fields
      fun {Neighbours F}
	 X  = F mod N 
	 Y  = F div N 
      in
	 {FoldR [~2#~1 ~2#1 ~1#~2 ~1#2  1#~2 1#2 2#~1 2#1]
	  fun {$ U#V In}
	     A = X+U
	     B = Y+V
	  in
	     if A>=0 andthen A<N andthen B>=0 andthen B<N
	     then A + B*N | In
	     else In
	     end
	  end
	  nil}
      end
   in
      proc {$ Solution}
	 Pred  = {FD.tuple pred NN 0#NN-1}
	 Succ  = {FD.tuple succ NN 0#NN-1}
	 Jump  = {FD.tuple jump NN 0#NN-1}   % field --> jump
      in
	 {FD.distinct Jump}
	 Solution = Jump
      % there are no solutions for odd N
	 N mod 2 = 0
      % tour starts as follows: (1,1), (2,3), ...
	 Jump.({Field 0 0}+1) = 0            
	 Jump.({Field 1 2}+1) = 1
      % for every field F
	 {For 0 NN-1 1
	  proc {$ F}
	     F1=F+1
	     Nbs = {Neighbours F}
	     PF = Pred.F1
	     SF = Succ.F1
	     JF = Jump.F1
	  in
	     PF :: Nbs
	     SF :: Nbs
	     %% redundant constraint: avoid trivial cycles
	     SF \=: PF
	     %% for every neighbour G of F
	     {ForAll Nbs
	      proc {$ G}
		 G1=G+1 JG=Jump.G1
	      in
		 JF\=:JG
		 (SF=:G)
		 = (F=:Pred.G1)
		 = ((JG =: JF + 1) +
		    (JG =: JF - NN + 1) =: 1)
		 %%= (Jump.G =: {FD.modI Jump.F NN}+1)
	      end}
	  end}
	 {FD.distribute naive Succ}
      end
   end

   Return = knights(proc {$}
		       {Search.base.one {Knights 12} _}
		    end
		    keys:[bench knights]
		    bench:1)

end
