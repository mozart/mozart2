functor

import

   FD

   Search

export
   Return
define


   fun {DurationTasks Tasks Dur}
      {FoldL Tasks fun{$ I T} I+Dur.T end 0}
   end
   
   fun {MaxDueWithout Tasks Task Start Dur}
      {FoldL Tasks
       fun {$ IMax T}
	  if Task==T then
	     IMax
	  else
	     {Max IMax {FD.reflect.max Start.T}+Dur.T}
	  end
       end 0}
   end
   
   fun {MinReleaseWithout Tasks Task Start Dur}
      {FoldL Tasks
       fun {$ IMin T}
	  if Task==T then
	     IMin
	  else
	     {Min IMin {FD.reflect.min Start.T}}
	  end
       end FD.sup}
   end
   
   fun {PossibleFirsts Tasks Start Dur}
      SumDur = {DurationTasks Tasks Dur}
   in 
      %% {Task | max(d(i)|i\=Task) - r(Task) >= SumDur
      {FoldL Tasks fun {$ FIn Task}
		      MaxDue = {MaxDueWithout Tasks Task Start Dur}
		   in
		      if MaxDue-{FD.reflect.min Start.Task} >= SumDur
		      then Task|FIn else FIn
		      end
		   end nil}
   end
   
   fun {PossibleLasts Tasks Start Dur}
      SumDur = {DurationTasks Tasks Dur}
   in 
      %% {Task | d(Task) - min(r(i) | i\=Task) >= SumDur}
      {FoldL Tasks fun {$ I Task}
		      MinRelease = {MinReleaseWithout Tasks Task Start Dur}
		   in 
		      if {FD.reflect.max Start.Task}+Dur.Task-MinRelease >= SumDur
		      then Task|I else I
		      end
		   end nil}
   end
      
   fun {MinimalStartOrder Task1 Task2 Start}
      Start1 = Start.Task1
      Start2 = Start.Task2
   in 
      {FD.reflect.min Start1}<{FD.reflect.min Start2}
      orelse
      ({FD.reflect.min Start1}=={FD.reflect.min Start2}
       andthen
       {FD.reflect.max Start1}<{FD.reflect.max Start2})
   end
   
   fun {MinimalEndOrder Task1 Task2 Start Dur}
      Start1 = Start.Task1
      Start2 = Start.Task2
      Dur1 = Dur.Task1
      Dur2 = Dur.Task2
   in
      {FD.reflect.max Start1}+Dur1>{FD.reflect.max Start2}+Dur2
      orelse
      ({FD.reflect.max Start1}+Dur1=={FD.reflect.max Start2}+Dur2
       andthen
       {FD.reflect.min Start1}+Dur1>{FD.reflect.min Start2}+Dur2)
   end
   
   fun {GetCandidates Tasks Start Dur}
      case Tasks of nil then nil
      else
	 Firsts = {Sort
		   {PossibleFirsts Tasks Start Dur}
		   fun{$ X Y} {MinimalStartOrder X Y Start} end}
	 Lasts = {Sort
		  {PossibleLasts Tasks Start Dur}
		  fun{$ X Y} {MinimalEndOrder X Y Start Dur} end}
      in
	 Firsts#Lasts
      end
   end
   
   fun {Slack Tasks Start Dur}
      MaxDue#MinRelease#Demand =
      {FoldL Tasks fun{$ MD#MR#D T}
		      {Max MD {FD.reflect.max Start.T}+Dur.T} #
		      {Min MR {FD.reflect.min Start.T}} #
		      D+Dur.T
		   end 0#FD.sup#0}
      Supply = MaxDue - MinRelease
   in
      Supply - Demand
   end
   
   fun {FindMinAndRest TMin CostTMin Tasks Start Dur ?Min}
      case Tasks of nil then
	 Min=TMin  nil
      [] Task|Tr then
	 NCost = {Slack Task Start Dur}
      in
	 if NCost < CostTMin then
	    TMin|{FindMinAndRest Task NCost Tr Start Dur Min}
	 else
	    Task|{FindMinAndRest TMin CostTMin Tr Start Dur Min}
	 end
      end
   end
   
   proc {EnumResource Tasks Rest Start Dur}
%	 {Show enum}	 
      choice
	 if {Length Tasks}<2 then {SchedDistribute Rest Start Dur}
	 else
	    Firsts#Lasts = {GetCandidates Tasks Start Dur}
	 in
	    if Firsts == nil then fail
	    elseif Lasts == nil then fail
	    else LFirsts = {Length Firsts}
	       LLasts = {Length Lasts}
	    in
	       if LFirsts==1
	       then {TryFirstsLasts Firsts firsts Tasks Rest Start Dur}
	       elseif LLasts==1
	       then {TryFirstsLasts Lasts lasts Tasks Rest Start Dur}
	       elseif LLasts<LFirsts
	       then {TryFirstsLasts Lasts lasts Tasks Rest Start Dur}
	       else {TryFirstsLasts Firsts firsts Tasks Rest Start Dur}
	       end
	    end
	 end
      end
   end
   
   proc {TryFirstsLasts FLs Mode Tasks Rest Start Dur}
      choice
%	    {Show 'try'}
	 Post = case Mode of firsts then Before else After end
      in
	 case FLs of nil then fail
	 [] H|T then
	    case T of nil then
%		  {Show one#H}
	       {Post H Tasks Start Dur}
	       {EnumResource {List.subtract Tasks H} Rest Start Dur}
	    else
	       choice
%		     {Show deep#H}
		  {Post H Tasks Start Dur}

%		     {Show after}
		  {EnumResource {List.subtract Tasks H} Rest Start Dur}
	       [] 
%		     {Show trueCase}
		  {TryFirstsLasts T Mode Tasks Rest Start Dur}
	       end
	    end
	 end
      end
   end
   
   proc {Before Task Tasks Start Dur}
      {ForAll Tasks proc{$ T}
		       if Task==T then skip
		       else Start.Task+Dur.Task =<: Start.T
		       end
		    end}
   end
   
   proc {After Task Tasks Start Dur}
      {ForAll Tasks proc{$ T}
		       if Task==T then skip
		       else Start.T+Dur.T =<: Start.Task
		       end
		    end}
   end
   
   proc {SchedDistribute ExclusiveTasks Start Dur}
      case ExclusiveTasks of nil then skip
      [] H|T then
	 Min 
	 Rest = {FindMinAndRest H {Slack H Start Dur} T Start Dur Min}
      in 
	 {EnumResource Min Rest Start Dur}
      end
   end
   

   proc {BridgeNoterm TaskSpecs Constraints}
      TaskSpecs = [% task # duration # preceding tasks # resources
		   pa # 0  # nil  # noResource
		   a1 # 4  # [pa] # excavator
		   a2 # 2  # [pa] # excavator
		   a3 # 2  # [pa] # excavator
		   a4 # 2  # [pa] # excavator
		   a5 # 2  # [pa] # excavator
		   a6 # 5  # [pa] # excavator
		   p1 # 20 # [a3] # pileDriver
		   p2 # 13 # [a4] # pileDriver
		   ue # 10 # [pa] # noResource
		   s1 # 8  # [a1] # carpentry
		   s2 # 4  # [a2] # carpentry
		   s3 # 4  # [p1] # carpentry
		   s4 # 4  # [p2] # carpentry
		   s5 # 4  # [a5] # carpentry
		   s6 # 10 # [a6] # carpentry
		   b1 # 1  # [s1] # concreteMixer
		   b2 # 1  # [s2] # concreteMixer
		   b3 # 1  # [s3] # concreteMixer
		   b4 # 1  # [s4] # concreteMixer
		   b5 # 1  # [s5] # concreteMixer
		   b6 # 1  # [s6] # concreteMixer 
		   ab1 # 1 # [b1] # noResource
		   ab2 # 1 # [b2] # noResource
		   ab3 # 1 # [b3] # noResource
		   ab4 # 1 # [b4] # noResource
		   ab5 # 1 # [b5] # noResource
		   ab6 # 1 # [b6] # noResource
		   m1 # 16 # [ab1]# bricklaying
		   m2 # 8 # [ab2] # bricklaying
		   m3 # 8 # [ab3] # bricklaying
		   m4 # 8 # [ab4] # bricklaying
		   m5 # 8 # [ab5] # bricklaying
		   m6 # 20 # [ab6]# bricklaying
		   l  # 2  # nil  # crane
		   t1 # 12 # [m1 m2 l] # crane
		   t2 # 12 # [m2 m3 l] # crane
		   t3 # 12 # [m3 m4 l] # crane
		   t4 # 12 # [m4 m5 l] # crane
		   t5 # 12 # [m5 m6 l] # crane
		   ua # 10 # nil # noResource
		   v1 # 15 # [t1] # caterpillar
		   v2 # 10 # [t5] # caterpillar
		   pe # 0 # [t2 t3 t4 v1 v2 ua] # noResource
		  ]

      proc {Constraints Start Dur}
	 {ForAll [s1#b1 s2#b2 s3#b3 s4#b4 s5#b5 s6#b6]
	  proc {$ A#B}
	     (Start.B + Dur.B) - (Start.A + Dur.A) =<: 4
	  end}
      
	 {ForAll [a1#s1 a2#s2 a5#s5 a6#s6 p1#s3 p2#s4]
	  proc{$ A#B}
	     Start.B - (Start.A + Dur.A) =<: 3
	  end}
      
	 {ForAll [s1 s2 s3 s4 s5 s6]
	  proc{$ A}
	     Start. A >=: Start.ue + 6
	  end}

	 {ForAll [m1 m2 m3 m4 m5 m6]
	  proc{$ A}
	     (Start.A + Dur.A) - 2 =<: Start.ua
	  end}

	 Start.l =: Start.pa + 30
	 Start.pa = 0
      end
   end

%%%%%%%%%%%%%%
%  Compiler  %
%%%%%%%%%%%%%%
	       
   fun {NoTermCompile Specification}
      TaskSpecs
      Constraints
      {Specification TaskSpecs Constraints}
      MaxTime =
      {FoldR TaskSpecs fun {$ _#D#_#_ A} D+A end 0}
      Tasks =
      {FoldR TaskSpecs fun {$ T#_#_#_ A} T|A end nil}
      Dur =    % task --> duration 
      {MakeRecord dur Tasks}
      {ForAll TaskSpecs proc {$ T#D#_#_} Dur.T = D end}
      Resources =
      {FoldR TaskSpecs
       fun {$ _#_#_#Resource A}
	  if Resource==noResource orelse {Member Resource A}
	  then A else Resource|A end
       end
       nil}
      ExclusiveTasks =  % list of lists of exclusive tasks
      {Map Resources
       fun {$ Resource}
	  {FoldR TaskSpecs
	   fun {$ Task#_#_#ThisResource A}
	      if Resource==ThisResource then Task|A else A end
	   end
	   nil}
       end}
   in
      proc {$ Start}
	 Start =       % task --> start time
	 {FD.record start Tasks 0#MaxTime}
      % impose precedences
	 {ForAll TaskSpecs
	  proc {$ Task#_#Preds#_}
	     {ForAll Preds
	      proc {$ Pred}
		 Start.Pred + Dur.Pred =<: Start.Task
	      end}
	  end}
      % impose other constraints
	 {Constraints Start Dur}
      % impose resource constraints

	 {ForAll ExclusiveTasks
	  proc{$ Tasks}
	     {ForAllTail Tasks
	      proc{$ T1|Tail}
		 {ForAll Tail
		  proc{$ T2}
		     thread
			or Start.T1 + Dur.T1 =<: Start.T2
			[] Start.T2 + Dur.T2 =<: Start.T1
			end
		     end
		  end}
	      end}
	  end}

      
      % serialize and commit
	 {SchedDistribute ExclusiveTasks Start Dur}

	 choice
	    {Record.forAll Start proc {$ S} S = {FD.reflect.min S} end}
	 end
      
      end
   end


   Return=
   fd([bridge([noterm_entailed(entailed(proc {$} {Search.base.best {NoTermCompile BridgeNoterm}
				     proc{$ O N} N.pe <: O.pe end _}
			    end)
		      keys: [fd entailed])
	      ])
      ])
end
