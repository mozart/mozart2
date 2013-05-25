%%%
%%% Authors:
%%%   Christian Schulte, <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
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
   FD Schedule Space Search

export
   Return
   
prepare

   TaskSpec =[pa(dur: 0)
	      a1(dur: 4 pre:[pa] res:excavator)
	      a2(dur: 2 pre:[pa] res:excavator)
	      a3(dur: 2 pre:[pa] res:excavator)
	      a4(dur: 2 pre:[pa] res:excavator)
	      a5(dur: 2 pre:[pa] res:excavator)
	      a6(dur: 5 pre:[pa] res:excavator)
	      p1(dur:20 pre:[a3] res:pileDriver)
	      p2(dur:13 pre:[a4] res:pileDriver)
	      ue(dur:10 pre:[pa])
	      s1(dur: 8 pre:[a1] res:carpentry)
	      s2(dur: 4 pre:[a2] res:carpentry)
	      s3(dur: 4 pre:[p1] res:carpentry)
	      s4(dur: 4 pre:[p2] res:carpentry)
	      s5(dur: 4 pre:[a5] res:carpentry)
	      s6(dur:10 pre:[a6] res:carpentry)
	      b1(dur: 1 pre:[s1] res:concreteMixer)
	      b2(dur: 1 pre:[s2] res:concreteMixer)
	      b3(dur: 1 pre:[s3] res:concreteMixer)
	      b4(dur: 1 pre:[s4] res:concreteMixer)
	      b5(dur: 1 pre:[s5] res:concreteMixer)
	      b6(dur: 1 pre:[s6] res:concreteMixer)
	      ab1(dur:1 pre:[b1])
	      ab2(dur:1 pre:[b2])
	      ab3(dur:1 pre:[b3])
	      ab4(dur:1 pre:[b4])
	      ab5(dur:1 pre:[b5])
	      ab6(dur:1 pre:[b6])
	      m1(dur:16 pre:[ab1] res:bricklaying)
	      m2(dur: 8 pre:[ab2] res:bricklaying)
	      m3(dur: 8 pre:[ab3] res:bricklaying)
	      m4(dur: 8 pre:[ab4] res:bricklaying)
	      m5(dur: 8 pre:[ab5] res:bricklaying)
	      m6(dur:20 pre:[ab6] res:bricklaying)
	      l(dur:  2 res:crane)
	      t1(dur:12 pre:[m1 m2 l] res:crane)
	      t2(dur:12 pre:[m2 m3 l] res:crane)
	      t3(dur:12 pre:[m3 m4 l] res:crane)
	      t4(dur:12 pre:[m4 m5 l] res:crane)
	      t5(dur:12 pre:[m5 m6 l] res:crane)
	      ua(dur:10)
	      v1(dur:15 pre:[t1] res:caterpillar)
	      v2(dur:10 pre:[t5] res:caterpillar)
	      pe(dur: 0 pre:[t2 t3 t4 v1 v2 ua])]
define
   
   BridgeSpec =
   bridge(tasks: TaskSpec
	  constraints:
	     proc {$ Start Dur}
		{ForAll [s1#b1 s2#b2 s3#b3 s4#b4 s5#b5 s6#b6]
		 proc {$ A#B}
		    (Start.B + Dur.B) - (Start.A + Dur.A) =<: 4 
		 end}
		{ForAll [a1#s1 a2#s2 a5#s5 a6#s6 p1#s3 p2#s4]
		 proc {$ A#B}
		    Start.B - (Start.A + Dur.A) =<: 3
		 end}
		{ForAll [s1 s2 s3 s4 s5 s6]
		 proc {$ A}
                 Start. A >=: Start.ue + 6
		 end}
		{ForAll [m1 m2 m3 m4 m5 m6]
		 proc {$ A}
		    (Start.A + Dur.A) - 2 =<: Start.ua
		 end}
		Start.l  =: Start.pa + 30
		Start.pa = 0
	     end)

   fun {GetDur TaskSpec}
      {List.toRecord dur {Map TaskSpec fun {$ T}
					  {Label T}#T.dur
				       end}}
   end
   
   fun {GetStart TaskSpec}
      MaxTime = {FoldL TaskSpec fun {$ Time T} 
				   Time+T.dur
				end 0}
      Tasks   = {Map TaskSpec Label}
   in
      {FD.record start Tasks 0#MaxTime}
   end
   
   fun {GetTasksOnResource TaskSpec}
      D={Dictionary.new}
   in
      {ForAll TaskSpec 
       proc {$ T}
	  if {HasFeature T res} then R=T.res in
	     {Dictionary.put D R {Label T}|{Dictionary.condGet D R nil}}
	  end
       end}
      {Dictionary.toRecord tor D}
   end

   fun {Compile Spec}
      TaskSpec    = Spec.tasks
      Constraints = if {HasFeature Spec constraints} then
		       Spec.constraints
		    else
		       proc {$ _ _} 
			  skip
		       end
		    end
      Dur         = {GetDur TaskSpec}
      TasksOnRes  = {GetTasksOnResource TaskSpec}
   in
      proc {$ Start}
	 Start = {GetStart TaskSpec}
	 {ForAll TaskSpec
	  proc {$ T}
	     {ForAll {CondSelect T pre nil}
	      proc {$ P}
		 Start.P + Dur.P =<: Start.{Label T}
	      end}
	  end}
	 {Constraints Start Dur}
	 {Record.forAll TasksOnRes
	  proc {$ Ts}
	     {ForAllTail Ts
	      proc {$ T1|Ts}
		 {ForAll Ts
		  proc {$ T2}
		     (Start.T1 + Dur.T1 =<: Start.T2) +
		     (Start.T2 + Dur.T2 =<: Start.T1) >=: 1
		  end}
	      end}
	  end}
	 {Schedule.firstsDist TasksOnRes Start Dur}
	 {Space.waitStable}
	 {Record.forAll Start proc {$ S} 
				 S={FD.reflect.min S} 
			      end}
      end
   end

   Bridge = {Compile BridgeSpec}

   proc {Earlier Old New}
      Old.pe >: New.pe
   end


   Return = bridge(proc {$}
		      {Search.base.best Bridge Earlier _}
		   end
		   keys:[bench bridge]
		   bench:1)


end
