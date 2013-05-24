%%%
%%% Authors:
%%%   Christian Schulte
%%%
%%% Copyright:
%%%   Christian Schulte, 2001
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
   FD
   Search
   Space
   System

export
   Return

define
   
   %% The following test-case is taken from
   %%   Jean-François Puget, A fast algorithm for the bound consistency 
   %%   of alldiff constraints, Proceedings of the 15th National Conference 
   %%   on Artificial Intelligence (AAAI-98), pages 359--366, 1998.
   proc {PugetExample Xs}
      [X1 X2 X3 X4 X5 X6] = Xs
   in
      X1 :: 3#6
      X2 :: 3#4
      X3 :: 2#5
      X4 :: 2#4
      X5 :: 3#4
      X6 :: 1#6
      {FD.distinctB Xs}
   end

   PugetSolution = [[6] [3 4] [5] [2] [3 4] [1]]

   local
      fun {MakeGolomb Prop}
	 N  = 6
	 NN = N * N
	 N2 = 2 * N
      in
	 proc {$ D}
	    K = {FD.tuple k N 0#FD.sup}
	    !D = {FD.tuple d (NN - N) div 2 0#NN}
	    fun {DIJ I J}
	       D.(((I - 1) * (N2 - I)) div 2 + J - I)
	    end
	 in
	    K.1 = 0
	    K.2 :: 0#NN
	    {DIJ 1 N} = 17
	    for I in 1..N-1 do
	       K.(I+1) >: K.I
	       for J in I+1..N do
		  K.J - K.I =: {DIJ I J}
	       end
	    end
	    {FD.Prop D}
	    {FD.distribute naive K}
	 end
      end
      fun {Check S1 S2}
	 X1={Space.merge {Space.clone S1}}
	 X2={Space.merge {Space.clone S2}}
      in
	 {Record.map X1 FD.reflect.min}==
	 {Record.map X2 FD.reflect.min}
	 andthen
	 {Record.map X1 FD.reflect.max}==
	 {Record.map X2 FD.reflect.max}
      end
      fun {ExpCmp S1 S2}
	 case {Space.ask S1}#{Space.ask S2}
	 of failed#failed then 
	    true
	 [] succeeded#succeeded then
	    {Space.merge S1}=={Space.merge S2}
	 [] alternatives(2)#alternatives(2) then

	    {Check S1 S2} andthen
	    local
	       C1={Space.clone S1} C2={Space.clone S2}
	    in
	       {Space.commit S1 1} {Space.commit S2 1}
	       {Space.commit C1 2} {Space.commit C2 2}
	       {ExpCmp S1 S2} andthen {ExpCmp C1 C2}
	    end
	 [] X then
	    {System.show X}
	    false
	 end
      end
   in
      fun {CheckGolomb}
	 {ExpCmp
	  {Space.new {MakeGolomb distinctD}}
	  {Space.new {MakeGolomb distinctB}}}
      end
   end
   
   Return =
   fd([boundsdistinct([puget(equal(
				fun {$}
				   [S]={Search.base.one PugetExample}
				in
				   {Map S FD.reflect.domList}
				end
				PugetSolution)
			     keys: [fd])
		       golomb(equal(CheckGolomb true)
			      keys: [fd])
		      ])
      ])

end
