%%%  Programming Systems Lab, DFKI Saarbruecken, 
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Joerg Wuertz 
%%%  Email: wuertz@dfki.uni-sb.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

local
   
   LeapInit         = 10
   FailureLimitInit = 10
   IterationNb      = 2

   \insert 'localUtils.oz'
   
   \insert 'swaps.oz'
   
   \insert 'greedy.oz'
   
   \insert 'shuffle.oz'

   class LocalSearch from BaseObject
      attr state localObject
      meth start(spec:                 Spec
		 resourceDistribution: REnum
		 taskDistribution:     _
		 resourceConstraints:  RConstraints
		 compiler:             Compiler
		 label:                Label
		 order:                _
		 rcd:                  _
		 lb:                   LB
		 solution:             ?FinalSol)
	 state <- running
	 localObject <-  thread {New LocalObject
				 init(spec:                Spec
				      resourceEnum:        REnum
				      resourceConstraints: RConstraints 
				      compiler:            Compiler
				      label:               Label
				      cObject:             self
				      heuristic:           {self getHeuristic($)}
				      lb:                  LB
				      final:               FinalSol)}
			 end
      end
      meth stop
	 state <- stopped
      end
      meth resume(?Sol)
	 LocalObject = @localObject
      in
	 state <- running
	 thread {LocalObject resume(Sol)} end
      end
      meth get(X)
	 X=@state
      end
      meth getHeuristic(_)
	 %% must be implemented by concrete classes
	 skip
      end
   end

   
in

   class LocalSearchHeuristic from LocalSearch
      meth getHeuristic(X)
	 X = SearchGreedy
      end
   end

   class LocalObject from BaseObject
      attr
	 spec
	 pertProblem
	 lastSol
	 lb
	 leap
	 failureLimit
	 enum
	 cObject
	 label
	 finalSol
	 tasks resources jobs machines jobPreds jobSuccs

      meth move
	 Spec=@spec
	 PertProblem=@pertProblem
	 LastSol=@lastSol
	 JobPreds=@jobPreds
	 JobSuccs=@jobSuccs
	 LB=@lb
	 Leap=@leap
	 FailureLimit=@failureLimit
	 Enum=@enum
	 CObject=@cObject
	 Label=@label
	 Tasks = @tasks
	 Resources = @resources
      in 
	 if {CObject get($)} == stopped
	 then
	    finalSol <- LastSol
	 else
	    UB = {FD.reflect.min {LastSol.1}.start.pe}
	    
	    FixedUBSol = {Search.one.depthP proc{$ X}
					       {LastSol.1 X}
					       X.start.pe = UB
					    end 1 _}
	    Dur = {FixedUBSol.1}.dur
	    Start = {FixedUBSol.1}.start
	    
	    o(ResPreds ResSuccs SortedRes)  = {GetResPredSucc Spec Start Resources Tasks}
	    
	    %% Criticals is a pair of a record of r(occ: crit:) indicating whether
	    %% a task is critical and on how many crit.paths it occurs,
	    %% and a list of critical paths.
	    Criticals = {Paths o(Start Dur ResSuccs JobSuccs
				 JobPreds SortedRes Tasks)} 
	    
	    {Trace criticals#Criticals.2}
	    case Criticals.2 of nil then skip
	    else {ForAll Criticals.2.1 Trace}
	    end
	    %% Swaps is a list of swap occurrences Task#Occ#Gain, where
	    %% Task is the task to swap, Occ the number of occurrences on
	    %% critical paths of Task and its successor and Gain the gain,
	    %% by swapping.
	    Swaps = {AnalyzeSwaps o(Criticals.1 Criticals.2 ResSuccs
				    JobSuccs ResPreds JobPreds
				    Tasks Start Dur)}
	    
	    RepairSol 
	 in
	    %% termination?
	    if {FD.reflect.min {FixedUBSol.1}.start.pe}==LB
	    then  finalSol <- FixedUBSol
	    else 
	       {Trace swaps#Swaps}
	       RepairResult = {Repair o(Criticals.1 Criticals.2 Swaps
					PertProblem ResSuccs SortedRes
					Tasks UB ?RepairSol)}
	    in
	       if RepairResult
		  andthen {FD.reflect.min {RepairSol.1}.start.pe} < UB
	       then 
		  {Trace repairSucceeded#{FD.reflect.min {RepairSol.1}.start.pe}}
		  {Label tk(conf(text: {GetPE RepairSol}))}
		  lastSol <- RepairSol
		  {self move}
	       else
		  {Trace repairNotSucceeded}
		  if {CObject get($)} == stopped
		  then
		     finalSol <- LastSol
		  else
		     ShuffleSol NewFailureLimit NewLeap
		  in
		     if {ShuffleLoop o(IterationNb FixedUBSol UB LB Leap
					 Criticals.1 PertProblem
					 ResSuccs SortedRes Tasks
					 Spec FailureLimit Start
					 Dur Enum CObject
					 ?NewFailureLimit ?NewLeap
					 ?ShuffleSol)}
		     then
			{Trace 'Shuffle succeeded'#{FD.reflect.min {ShuffleSol.1}.start.pe}}
			{Label tk(conf(text: {GetPE ShuffleSol}))}
			lastSol <- ShuffleSol
			failureLimit <- NewFailureLimit
			leap <- NewLeap
			{self move}
		     else
			{Trace 'Shuffle not succeeded'}
			finalSol <- FixedUBSol
		     end
		  end
	       end
	    end
	 end
      end
      
      meth resume(FinalSol)
	 PertProblem = @finalSol
	 GreedyProb = {Search.one.depthP
		       proc{$ X}
			  {PertProblem.1 X}
		       end 1 _}
      in
	 {@label tk(conf(text: {GetPE GreedyProb}))}
	 if {@cObject get($)} == stopped
	 then
	    FinalSol = GreedyProb
	 else
	    lastSol <- GreedyProb
	    {self move}
	    FinalSol = @finalSol
	 end
      end
      
      meth init(spec:                Spec
		resourceEnum:        REnum
		compiler:            Compiler
		resourceConstraints: RConstraints
		cObject:             CObject
		label:               Label
		heuristic:           Heuristic
		lb:                  LB
		final:               ?FinalSol)
	 try
	    o(Tasks Resources Jobs Machines JobPreds JobSuccs) = {GetThemAll Spec}
	    
	    %% Compute greedy solution. Result is a start record.
	    GreedySol = {Greedy Spec Heuristic Machines Jobs Resources}
	    o(_ _ SortedRes) = {GetResPredSucc Spec GreedySol Resources Tasks}
	    
	    %% Compute the PERT space.
	    PertProblem = {Search.one.depthP
			   proc{$ X}
			      {{Compiler Spec NoTE NoRE RConstraints} X}
			   end 1 _}
	    
	    UB = {FD.reflect.min GreedySol.pe}
	    
	    GreedyProb = {Search.one.depthP
			  proc{$ X}
			     {PertProblem.1 X}
			     Dur = X.dur
			     Start = X.start
			  in
			     X.start.pe = UB
			     {Record.forAll SortedRes
			      proc{$ Tasks}
				 {ForAllTail Tasks
				  proc{$ T1|Ts}
				     case Ts of nil then skip
				     else T2=Ts.1 in
					Start.T1+Dur.T1 =<: Start.T2
				     end
				  end}
			      end} 
			  end 1 _}
	    
	 in
	    {Label tk(conf(text: {GetPE GreedyProb}))}
	    lastSol <- GreedyProb
	    spec <- Spec
	    pertProblem <- PertProblem
	    jobPreds <- JobPreds
	    jobSuccs <- JobSuccs
	    lb <- LB
	    leap <- LeapInit
	    failureLimit <- FailureLimitInit
	    enum <- REnum
	    cObject <- CObject
	    label <- Label
	    tasks <- Tasks
	    resources <- Resources
	    machines <- Machines
	    jobs <- Jobs
	    if {CObject get($)} == stopped
	    then FinalSol = GreedyProb
	       finalSol <- GreedyProb
	    else
	       {self move}
	       FinalSol = @finalSol
	    end
	 catch failure(...) then FinalSol = nil
	 [] system(...) then FinalSol = nil
	 [] error(...) then FinalSol = nil
	 end
      end
   end
   
end

