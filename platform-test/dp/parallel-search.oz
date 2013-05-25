%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
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

import
   Search

export
   Return

prepare

   AlphaSol = [[5 13 9 16 20 4 24 21 25 17 23 2 8 12 10 19 7 11 
		15 3 1 26 6 22 14 18]]

   NoWorkers = 4
   
define

   functor Alpha
   import FD
   export Script
   define
      proc {Script Sol}
	 [A B C _ E F G H I J K L M N O P Q R S T U V W X Y Z] = Sol
      in
	 Sol = {FD.dom 1#26}
	 {FD.distinct Sol}
	 
	 B+A+L+L+E+T       =: 45
	 C+E+L+L+O         =: 43
	 C+O+N+C+E+R+T     =: 74
	 F+L+U+T+E         =: 30
	 F+U+G+U+E         =: 50
	 G+L+E+E           =: 66
	 J+A+Z+Z           =: 58
	 L+Y+R+E           =: 47
	 O+B+O+E           =: 53
	 O+P+E+R+A         =: 65
	 P+O+L+K+A         =: 59
	 Q+U+A+R+T+E+T     =: 50
	 S+A+X+O+P+H+O+N+E =: 134
	 S+C+A+L+E         =: 51
	 S+O+L+O           =: 37
	 S+O+N+G           =: 61
	 S+O+P+R+A+N+O     =: 82
	 T+H+E+M+E         =: 72
	 V+I+O+L+I+N       =: 100
	 W+A+L+T+Z         =: 34
	 
	 {FD.distribute ff Sol}
      end

   end

   functor Photo
   import FD
   export Script Order
   define
      
      proc {Script Solution}
      
	 Pos = position(alain:_  beatrice:_  christian:_  daniel:_
			eliane:_  francois:_  gerard:_)
	 
	 fun {NextTo P Q}
	    (Pos.P+1 =: Pos.Q) + (Pos.P-1 =: Pos.Q) =: 1
	 end
	 
	 Pre Satisfaction={FD.decl}
      in
	 Pos = {FD.dom 1#7}
	 Pre = preference({NextTo beatrice gerard}
			  {NextTo beatrice eliane}
			  {NextTo beatrice christian}
			  {NextTo francois eliane}
			  {NextTo francois daniel}
			  {NextTo francois alain}
			  {NextTo alain daniel}
			  {NextTo gerard christian})
	 
	 Satisfaction = {FD.sum Pre '=:'}
	 {FD.distinct Pos}
	 Solution = Pos#Satisfaction
	 {FD.distribute ff Pos}
      end

      proc {Order Old New}
	 Old.2 <: New.2
      end
      
   end
   

   proc {ParOne F ?Ss}
      E={New Search.parallel init(localhost:NoWorkers)}
   in
      {E one(F ?Ss)}
      {E close}
   end
   
   proc {ParAll F ?Ss}
      E={New Search.parallel init(localhost:NoWorkers)}
   in
      {E all(F ?Ss)}
      {E close}
   end
   
   proc {ParBest F ?Ss}
      E={New Search.parallel init(localhost:NoWorkers)}
   in
      {E best(F ?Ss)}
      {E close}
   end
   

   
   Return =
   dp([parallel_search(
	  [alpha([one(equal(fun {$}
			       try {ParOne Alpha}
			       catch _ then nil
			       end
			    end
			    AlphaSol)
		      keys: [dp parallel_search fd])
		  all(equal(fun {$}
			       try {ParAll Alpha}
			       catch _ then nil
			       end
			    end
			    AlphaSol)
		      keys: [dp parallel_search fd])])
	   photo([one(fun {$}
			 try
			    {Length {ParOne Photo}}==1
			 catch _ then false
			 end
		      end
		      keys: [dp parallel_search fd])
		  best(fun {$}
			  try
			     Ss={List.last {ParBest Photo}}
			  in
			     Ss.2==6
			  catch _ then false
			  end
		       end
		      keys: [dp parallel_search fd])])])])

end
