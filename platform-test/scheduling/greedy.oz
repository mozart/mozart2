%%%  Programming Systems Lab, DFKI Saarbruecken, 
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Joerg Wuertz 
%%%  Email: wuertz@dfki.uni-sb.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

local


   fun {Try o(Start Dur Machines _ Unscheduled Next)}
      Raise = {FD.reflect.min Start.Next}+Dur.Next
   in
      {ForAll Unscheduled.(Machines.Next)
       proc {$ Task}
	  if Task \= Next then Raise =<: Start.Task
	  else skip
	  end
       end}
      choice 
	 {Record.foldL Unscheduled
	  fun{$ I1 Tasks}
	     {FoldL Tasks fun{$ I2 Task}
			     MinTask = {FD.reflect.min Start.Task}
			  in 
			     {Max I2 {FoldL Tasks
				      fun{$ I T}
					 if {FD.reflect.min Start.T}>=MinTask
					 then I+Dur.T
					 else I
					 end
				      end MinTask}}
			  end I1}
	  end 0}
      end
   end
   
   fun {GreedyCompile Specification}
      TaskSpecs   = Specification.taskSpec
      Constraints = Specification.constraints
      MaxTime     = {FoldL TaskSpecs fun {$ In _#D#_#_} D+In end 0}
      Tasks       = {Map TaskSpecs fun {$ T#_#_#_} T end}
      Dur         = {MakeRecord dur Tasks}
      {ForAll TaskSpecs proc {$ T#D#_#_} Dur.T = D end}
	 
   in
      proc {$ Arg}
	 a(start:Start
	   dur:!Dur
	   next:_
	   lb:_) = !Arg
      in
	 Start = {FD.record start Tasks 0#MaxTime}
	 %% impose precedences
	 {ForAll TaskSpecs
	  proc {$ Task#_#Preds#_}
	     {ForAll Preds
	      proc {$ Pred}
		 Start.Pred + Dur.Pred =<: Start.Task
	      end}
	  end}
	 %% impose Constraints
	 {Constraints Start Dur}
      end
   end
in


   fun {SearchGreedy Candidates Problem Machines Jobs Unscheduled}
      {FoldL Candidates
       fun{$ CMin#CLB#CMax Cand}
	  S = {Search.one.depthP proc{$ X}
				    {Problem.1 X}
				    X.next = Cand
				    choice 
				       {Try o(X.start X.dur
					      Machines Jobs
					      Unscheduled
					      X.next) X.lb}
				    end
				 end 1 _}
       in
	  {Wait S}
	  local 
	     TLB = {S.1}.lb
	     TMax = {FD.reflect.max {Problem.1}.start.Cand}
	  in
	     if TLB < CLB then Cand#TLB#TMax
	     elseif TLB==CLB andthen
		TMax<CMax then
		Cand#TLB#TMax
	     else CMin#CLB#CMax
	     end
	  end
       end _#FD.sup#FD.sup}
   end
   
   fun {UpperBound Problem Heuristic Unscheduled Jobs Machines Candidates}
      %% try the first operation on the jobs. compute the resulting
      %% lower bound if the operation is scheduled next.
      %% in case of ties choose minimal due-dur(t) or dur(t).
      Next#LB#_ = {Heuristic Candidates Problem Machines Jobs Unscheduled}

      NewProblem
      JobName = {TaskToJob Next}
      %% delete scheduled operation from its job
      NewJobs = {AdjoinAt Jobs JobName Jobs.JobName.2}
      NextMachine = Machines.Next
      %% delete scheduled operation from unscheduled ops on its machine
      NewUS = {AdjoinAt Unscheduled NextMachine {List.subtract Unscheduled.NextMachine Next}}
      NewCandidates = case NewJobs.JobName of nil
		      then {List.subtract Candidates Next}
		      else (NewJobs.JobName.1)|{List.subtract Candidates Next}
		      end
   in
      {Trace LB}
      %% add the constraint that Next is scheduled next
      NewProblem = {Search.one.depthP
		    proc{$ X}
		       {Problem.1 X}
		       Start = X.start
		       Raise 
		    in
		       choice 
			  Raise = {FD.reflect.min Start.Next}+X.dur.Next
			  {ForAll NewUS.NextMachine
			   proc {$ Task}
			      Raise =<: Start.Task
			   end}
		       end
		    end 1 _}
      case NewCandidates of nil 
      then
	 {NewProblem.1}.start 
      else {UpperBound NewProblem Heuristic NewUS NewJobs
	    Machines NewCandidates}
      end
   end
   
   fun {Greedy Problem Heuristic Machines Jobs Resources}
      %% Compute an upper bound
      S = {Search.one.depthP proc{$ X}
				{{GreedyCompile Problem} X}
			     end 1 _}
      Unscheduled = {GetUnscheduled Problem Resources}
      Candidates = {Record.foldL Jobs fun{$ I Jobs}
					 case Jobs of nil then I
					 else (Jobs.1)|I
					 end
				      end nil}
   in
      case S of nil then nil
      else 
	 {UpperBound S Heuristic Unscheduled Jobs Machines Candidates}
      end
   end
   
end
