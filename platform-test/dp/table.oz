%%%
%%% Authors:
%%%   Erik Klintskog (erik@sics.se)
%%%
%%% Copyright:
%%%   Erik Klintskog, 1998
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
   Remote(manager)
   System
   TestMisc(localHost)
export
   Return

define
   proc{Locker Nr D S Lim}
      L = {NewLock} in
      if(Nr mod Lim == 0) then
	 thread {Wait S} lock L then skip end
	 end
      end
      {Send D store(L Nr)}
   end
   
   proc{Celler Nr D S Lim}
      L = {NewCell Nr} in
      if(Nr mod Lim == 0) then
	 thread {Wait S} {Access L} = Nr end
      end
      {Send D store(L Nr)}
   end
   
   
   proc{Variabler Nr D S Lim}
      L in
      if(Nr mod Lim == 0) then
	 thread {Wait S} L = Nr end
      end
      {Send D store(L Nr)}
   end
   
   proc{Porter Nr D S Lim}
      St P= {NewPort St}   in
      if(Nr mod Lim == 0) then
	 thread {Wait S} {Send P Nr} St.1 = Nr end
      end
      {Send D store(P Nr)}
   end
   
   
   Return=
   dp([
       table_nofrag(
	    proc {$}
	       S={New Remote.manager init(host:TestMisc.localHost)}
	       D

	       proc{Stuffer PP}
		  S
		  PPP = proc{$ Nr} {PP.1 Nr D S 100} end
	       in
		  {For 1 PP.2 1 PPP}
		  {Send D gc}
		  {System.gcDo}
		  {Send D gcR(S)}
		  {Wait S}
		  {System.gcDo}
		  {System.gcDo}
	       end
	    in
	       {S ping}
	       {S apply(url:'' functor
			       import
				  System
			       export
				  PP
			       define
				  S
				  P = {NewPort S}
				  CC = {NewCell nil}
				  proc{R X}
				     case X of
					store(E _) then
					{Assign CC E|{Access CC}}
				     elseof gc then
					{System.gcDo}
				     elseof gcR(A) then
					{Assign CC nil}
					{System.gcDo}
					A = unit

				     end
				  end
			       			      
				  
				  thread
				     {ForAll S R}
				  end
				  PP = P
			       end $)}.pP = D

	       {ForAll [Celler#40#celler
			Locker#300#locker
			Celler#100#celler
			Porter#564#porter
			Locker#1003#locker
			Celler#267#celler
			Variabler#1200#variabler
			Celler#5000#celler
			Locker#45#locker
			Locker#10000#locker
			Celler#10000#celler
		       ]
		
		Stuffer}
	       
	       {S close}
	    end
	    keys:[remote])

       table_frag(
	    proc {$}
	       S={New Remote.manager init(host:TestMisc.localHost)}
	       D
	       
	       proc{Stuffer PP}
		  S
		  PPP
	       in
		  if(PP.1 == gc) then
		     {Send D gcR(S PP.2)}
		     {Wait S}
		     {System.gcDo}
		     {System.gcDo}
		  else
		     PPP  = proc{$ Nr} {PP.1 PP.4 D S 100} end
		     {For 1 PP.2 1 PPP}
		  end
	       end
	    in
	       {S ping}
	       {S apply(url:'' functor
			       import
				  System
			       export
				  PP
			       define
				  S
				  P = {NewPort S}
				  C =o({NewCell nil}
				       {NewCell nil}
				       {NewCell nil}
				       {NewCell nil}
				       {NewCell nil})
				  proc{R X}
				     case X of
					store(E Nr) then
					{Assign C.Nr E|{Access C.Nr}}
				     elseof gc then
					{System.gcDo}
				     elseof gcR(A Nr) then
					{Assign C.Nr nil}
					{System.gcDo}
					A = unit
				     end
				  end
			       			      
				  
				  thread
				     {ForAll S R}
				  end
				  PP = P
			       end $)}.pP = D

	       {ForAll [Celler#23#celler#1
			Locker#70#locker#2
			Celler#150#celler#3
			Porter#64#porter#4
			gc#2
			Locker#103#locker#5
			gc#4
			Celler#267#celler#2
			gc#1
			Variabler#120#variabler#1
			gc#2
			gc#5
			Celler#500#celler#2
			gc#1
			Locker#450#locker#4
			gc#1
			gc#2
			gc#3
			gc#4
			gc#5
			Locker#100#locker#1
			Locker#100#locker#2
			Locker#100#locker#3
			Locker#100#locker#4
			Locker#100#locker#5
			gc#1
			gc#3
			gc#5
			Locker#300#locker#3
		       ]
		
		Stuffer}
	       
	       {S close}
	    end
	    keys:[remote])
      ])
end

