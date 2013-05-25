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
   Search(base)
   RecordC
   Space
   System(show)
   Browser(getsBoundB) at 'x-oz://boot/Browser'
export
   Return

define

   fun {Id X} X end
   
   Return=
   misc([
	      search1(
		     proc {$}
			{Search.base.all fun {$} Ele in thread Ele=a end Ele=b end}
			=nil
		     end
		     keys:[fixedBug search])
	      search2(
		 proc {$}
			 fun {FailChk}
			    local X={Id a} in
			       try choice true
				   [] X=b  %% failure
				   [] Ele in
				      choice Ele=b(b) %% failure
				      [] Ele=a        %% failure
				      end
				      {Wait Ele}
				      Ele=b
				      Ele
				   [] Ele in
				      choice Ele=b(b) %% ok
				      [] Ele=a        %% failure
				      end
				      {Wait Ele}
				      {RecordC.'^' Ele 1 b}
				      Ele
				   [] Ele in
				      choice Ele=b(b) %% ok
				      [] Ele=a        %% failure not caught!
				      end
				      {Wait Ele}
				      {RecordC.'^' Ele 1 b}
				   end
			       catch failure(debug:D) then failure(D)
			       [] error(T debug:D) then error(T D)
			       [] system(T debug:D) then system(T D)
			       end
			    end
			 end
		    in
			 {Search.base.all FailChk _}
		      end
		      keys:[fixedBug search])

	 apply([
		bug1(
		     proc {$}
			proc {P X Y Z}
			   {Wait X} {Wait Y} {Wait Z} X=a Y=b Z=c
			end
			Sync1 Sync2
		     in
			{Procedure.apply P [a b c]}
			local X in
			   thread {Procedure.apply P X} Sync1=unit end
			   X=[a b c] end
			local Y in
			   thread {Procedure.apply Y [a b c]} Sync2=unit end
			   Y=P end
			{Wait Sync1} {Wait Sync2}
		     end
		     keys:[fixedBug apply suspend])

		bug2(
		     proc {$}
			{Procedure.apply {New BaseObject noop} [noop]}
		     end
		     keys:[fixedBug apply object])

		bug3(
		     proc {$}
			{Procedure.apply IsAtom [nil true]}
		     end
		     keys:[fixedBug apply])
		])

	 object(proc {$}
		   X = {New class $ from BaseObject
			       attr a
			       meth test
				  cond thread skip end then skip end
			       end
			    end
			noop}
		in
		   {X test}
		end
		keys:[fixedBug object])


	 %% trailing local bindings is necessary with exception handling
	 undoBinding(
		     proc {$}
			X=f(a b) Y=f(a c)
		     in
			try
			   X={Id Y}
			catch failure(...) then skip
			end
			X=f(a b) Y=f(a c)
		     end
		     keys:[fixedBug unification exception])
		     
	 adjoinAt(equal(
			fun {$} {AdjoinAt a|b a b} end
			'|'(1:a 2:b a:b)
		       )
		  keys:[fixedBug adjoin record list])

	 toRecord(equal(
			fun {$} {List.toRecord '|' [1#a 2#b]} end
			a|b
		       )
		  keys:[fixedBug record list])

	 deepObject(proc {$}
		       O = {New class $ from BaseObject
				   meth wuff skip end
				end
			    wuff}
		    in
		       _={Space.new proc {$ _}
				       {O noop}
				    end}
		    end
		    keys:[fixedBug object space])

	 bug(proc {$}
		cond Ele in
		   Ele={Id a}
		   dis Ele=a then skip
		   [] Ele=b then Ele=b
		   end
		   thread Ele=c end
		then fail
		else skip
		end
	     end
	     keys:[fixedBug 'dis' guard space])

	 list(proc {$}
		 L in
		 L={Id L|nil} case L of nil then fail else skip end
	      end
	      keys:[fixedBug list])

	 bug(proc {$}
		X Y Z
	     in
		thread cond thread X=Y end then Z = unit end end
		{For 1 10000 1 proc {$ X} _=X*X end}
		X=Y
		{Wait Z}
	     end
	     keys:[fixedBug])


	 getsBound(proc {$}
		      %% the getsBound bug: UVAR->SVAR invariant
		      _={Space.new proc {$ _}
				      GB=Browser.getsBoundB
				      proc {P X}
					 thread Y in
					    thread {Wait Y} end
					    X=Y
					 end
					 {Wait {GB X}}
					 {System.show a}
					 if {IsFree X} then
					    {P X}
					 else skip
					 end
				      end
				   in
				      {P _}
				   end}
		   end
		   keys:[fixedBug getsBound])

	 unif(
% non-terminating unification
	      proc {$}
		 X1=X2|X1
		 X2=X1|(X2|X1)
	      in
		 X1=X2
	      end
	      keys:[fixedBug unification])

	 'thread'(
% First-class threads and actors tasks
		proc {$}
		   T X
		in
		   thread
		      try
			 T = {Thread.this}
			 or X = 1 [] X = 2 end
		      catch test then X = 1 end
		   end
		   {Thread.injectException T test}
		end
		keys:[fixedBug 'thread' exception])

	 stringIsFinite(
		proc {$}
		   X=1|X
		in
		   if {IsString X} then fail else skip end
		end
		keys:[fixedBug string])

	 
	 adjoinList(
		    proc {$}
		       X=a#1|X
		    in
		       try {Record.adjoinList f X _}
		       catch error(kernel(type ...) ...) then skip
		       end
		    end
		    keys:[fixedBug adjoin record])
\ifdef COMPILER_SHOULD_RAISE_ERROR
	 arityCheck(
		    proc {$}

		       try
			  X in X::0#10
			  {FD.watch.size X 10 true
			   und hier kommen einfach zu viele argumente}
			  fail
		       catch X then {System.show X} end

		    end
		    keys:[fixedBug arity application])
\endif
	 biSuspend(proc {$}
		      X Y
		   in
		      thread X=true end
		      Y={FoldL [X] And true}
		      if Y==true then skip end
		   end
		   keys:[fixedBug suspension builtin])

	 object(proc {$}
		   M C
		in
		   M = init()
		   thread
		      class C
			 meth init()
			    skip
			 end
		      end
		   end
		   {New C M _}
		end
		keys:[fixedBug object message])
	 unification(proc {$}
			proc {P L1 L2}
			   X Y in X::1#10 Y::1#20 L1=[X a] L2=[Y b]
			end
			L1 L2
		     in
			{P L1 L2}
			if L1==L2 then fail else skip end
		     end
		     keys:[fixedBug unification cvar])
	])
end

