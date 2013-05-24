%%%  Programming Systems Lab, DFKI Saarbruecken, 
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Joerg Wuertz 
%%%  Email: wuertz@dfki.uni-sb.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

local


   MaxBacktracks = 90

   proc {InitSets Entry Tasks Start Dur LowB UpB Set DurSet}
      Left = Entry.left
      Right = Entry.right
   in
      LowB = {FD.reflect.min Start.Left}
      UpB = {FD.reflect.max Start.Right}+Dur.Right
      Set#DurSet = if LowB > {FD.reflect.min Start.Right} orelse
		      {FD.reflect.max Start.Left}+Dur.Left > UpB
		   then
		      nil#0
		   else
		      {FoldR Tasks fun{$ Task In}
				      StartT = Start.Task
				      DurT = Dur.Task
				   in 
				      if LowB =< {FD.reflect.min StartT}
					 andthen
					 {FD.reflect.max StartT}+DurT =< UpB
				      then
					 (Task|In.1)#(In.2 + DurT)
				      else
					 In
				      end
				   end nil#0}
		   end
   end
   
   fun {SlackOfResource Tasks Start Dur}
      TI = {FoldL Tasks fun{$ I1 T1}
			   {FoldL Tasks fun{$ I2 T2}
					   e(left:T1 right:T2)|I2
					end I1}
			end nil}
   in
      {FoldL TI fun {$ I Entry}
		   LowB UpB Set DurSet 
		   in
		   {InitSets Entry Tasks Start Dur LowB UpB Set DurSet}
		   if {Length Set} > 1 then
		      {Min I UpB-LowB-DurSet}
		   else I
		   end
		end FD.sup}
   end
   
   fun {EasiestResources SortedRes Start Dur}
      ResJobs = {FoldL {Arity SortedRes}
		 fun{$ I Res}
		    Slack = {SlackOfResource SortedRes.Res Start Dur}
		 in
		    (Res#Slack)|I
		 end nil}
      Sorted = {Sort ResJobs fun{$ _#A _#B} A > B end}
   in
      {Map Sorted fun{$ A#_} A end}
   end

   %% One resource remains fixed. 
   fun {JumpBasic o(EasyResources SortedRes UB Leap FailureLimit Spec
		    SortedRes PertProblem Start Dur 
		    Enum CObject ?JumpSol)}
      case EasyResources of nil then false
      [] Resource|ResourceR then
	 Sol
      in
	 if {BasicShuffle o(Resource UB-Leap FailureLimit Spec
			      SortedRes PertProblem Enum ?Sol)}
	 then
	    JumpSol = Sol
	    true
	 else
	    if {CObject get($)} == stopped
	    then
	       false
	    else
	       {JumpBasic o(ResourceR SortedRes UB Leap
			    FailureLimit Spec SortedRes PertProblem
			    Start Dur Enum CObject JumpSol)}
	    end
	 end
      end
   end
   
   fun {BasicShuffle o(Resource UB FailureLimit Spec SortedRes
		       PertProblem Enum ?Sol)}
      TaskSpecs = Spec.taskSpec
      ExclusiveTasks =  % list of lists of exclusive tasks
      {MakeExclusiveTasks {Arity SortedRes} TaskSpecs}
   in
      Sol = {SolveDepth 
	     proc{$ X}
		{PertProblem.1 X}
		Dur = X.dur
		Start = X.start
	     in
		%% try to find a better solution
		X.start.pe =<: UB
		{ForAllTail SortedRes.Resource
		 proc{$ T1|Ts}
		    case Ts of nil then skip
		    else
		       T2=Ts.1
		    in
		       Start.T1+Dur.T1 =<: Start.T2
		       end
		 end}
		{Enum Start Dur ExclusiveTasks}
	     end FailureLimit}
      case Sol of nil then false
      else
	 {Trace 'Basic shuffle succeeded with resource '#Resource}
	 true
      end
   end
 

   %% take two resources and fix the task pairs t1, t2 ordered, if
   %% t2 is a critical task. 
   fun {JumpCrit o(EasyResources Occ UB Leap FailureLimit Spec
		   SortedRes PertProblem Start Dur ?CritSol Enum CObject)}
      if {Length EasyResources} < 2 then false
      else Resource1|ResourcesR = !EasyResources
      in
	 {JumpCritLoop o(Resource1 ResourcesR Occ UB
			 Leap FailureLimit Spec SortedRes PertProblem
			 Start Dur ?CritSol Enum CObject)}
      end
   end

   fun {JumpCritLoop o(Resource1 EasyResources Occ UB Leap
		       FailureLimit Spec SortedRes PertProblem Start
		       Dur ?CritSol Enum CObject)}
      case EasyResources of nil then false
      [] Resource2|ResourcesR then 
	 Sol
      in
	 if {CritShuffle o(Resource1 Resource2 Occ UB-Leap
			     FailureLimit Spec SortedRes PertProblem
			     ?Sol Enum)}
	 then
	    CritSol = Sol
	    true
	 else
	    if {CObject get($)} == stopped
	    then
	       false
	    else 
	       {JumpCritLoop o(Resource2 ResourcesR Occ
			       UB Leap FailureLimit Spec SortedRes
			       PertProblem Start Dur ?CritSol Enum CObject)}
	    end
	 end
      end
   end


   fun {CritShuffle o(Resource1 Resource2 Occ UB FailureLimit Spec
		      SortedRes PertProblem ?Sol Enum)}
      TaskSpecs = Spec.taskSpec
      ExclusiveTasks =  % list of lists of exclusive tasks
      {MakeExclusiveTasks {Arity SortedRes} TaskSpecs}
   in
      Sol = {SolveDepth 
	     proc{$ X}
		{PertProblem.1 X}
		Dur = X.dur
		Start = X.start
	     in
		%% try to find a better solution
		X.start.pe =<: UB
		{ForAll [Resource1 Resource2]
		 proc{$ Resource}
		    {ForAllTail SortedRes.Resource
		     proc{$ T1|Ts}
			case Ts of nil then skip
			else
			   T2=Ts.1
			in
			   if Occ.T2.crit then 
			      Start.T1+Dur.T1 =<: Start.T2
			   else skip
			   end
			end
		     end}
		 end}
		{Enum Start Dur ExclusiveTasks}
	     end FailureLimit}
      case Sol of nil then false
      else
	 {Trace 'critical shuffle succeeded with resource '#Resource1#' and '#Resource2}
	 true
      end
   end


in
   fun{MakeExclusiveTasks Resources TaskSpecs}
      {FoldR Resources
       fun {$ Resource Xs}
	  {FoldR TaskSpecs 
	   fun {$ Task#_#_#ThisResource In}
	      if Resource==ThisResource then Task|In else In end
	   end
	   nil} | Xs
       end
       nil}
   end
   
   fun {ShuffleLoop o(N PrevSol UB LB Leap Occ PertProblem ResSuccs
		      SortedRes Tasks Spec FailureLimit Start Dur
		      Enum CObject ?NewFailureLimit ?NewLeap ?ShuffleSol)}
      if {CObject get($)} == stopped
      then
	 false
      else 
	 if UB-Leap < LB
	 then if Leap > 1
	      then NewLeap = Leap div 3
		 NewFailureLimit = FailureLimit
		 ShuffleSol = PrevSol
		 {Trace 'first case of shuffle succeeded'#(UB-Leap)#LB#Leap}
		 true
	      else
		 NewLeap = Leap
		 NewFailureLimit = FailureLimit
		 ShuffleSol = PrevSol
		 {Trace 'second case of shuffle not succeeded'#(UB-Leap)#LB#Leap}
		 false
	      end
	 else
	    JumpSol CritSol
	    EasyResources = {EasiestResources SortedRes Start Dur}
	 in
	    if {JumpBasic o(EasyResources SortedRes UB Leap FailureLimit Spec
			      SortedRes PertProblem Start Dur
			      Enum CObject ?JumpSol)}
	    then
	    %{Counter inc(bshuffles)}
	       {Trace 'Basic shuffle has succeeded'}
	       NewLeap = Leap
	       NewFailureLimit = FailureLimit
	       JumpSol = ShuffleSol
	       true
	    else
	       if {CObject get($)} == stopped
	       then
		  false
	       else 
		  {Trace 'Basic shuffle not succeeded'}
		  if {JumpCrit o(EasyResources Occ UB Leap FailureLimit
				   Spec SortedRes PertProblem Start Dur
				   ?CritSol Enum CObject)}
		  then
		     %{Counter inc(cshuffles)}
		     {Trace 'Critical shuffle succeeded'}
		     NewLeap = Leap
		     NewFailureLimit = FailureLimit
		     CritSol = ShuffleSol
		     true
		  else
		     {Trace 'Critical shuffle not succeeded'}
		     if Leap > 1
		     then
			if FailureLimit >= MaxBacktracks then false
			else 
			   {ShuffleLoop o(N PrevSol UB LB (Leap div 3)
					  Occ PertProblem ResSuccs
					  SortedRes Tasks Spec FailureLimit*3
					  Start Dur Enum CObject
					  NewFailureLimit NewLeap ShuffleSol)}
			end
		     else
			if N > 0
			then
			   if FailureLimit >= MaxBacktracks then false
			   else
			      {ShuffleLoop o(N-1 PrevSol UB LB Leap Occ
					     PertProblem ResSuccs SortedRes
					     Tasks Spec FailureLimit*3 Start
					     Dur Enum CObject NewFailureLimit
					     NewLeap ShuffleSol)}
			   end
			else false
			end
		     end
		  end
	       end
	    end
	 end
      end
   end
end

