functor

import

   FD

   Schedule

   Search

export
   Return
define


   BridgeProb =
   bridge(tasks:
	     [% task # duration # preceding tasks # resources
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
	  constraints:
	     proc {$ Start Dur}
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
	     end)

%%%%%%%%%%%%%%
%  Compiler  %
%%%%%%%%%%%%%%
	       

   fun {Compile Specification Global}
      TaskSpecs   = Specification.tasks
      Constraints = Specification.constraints

      MaxTime =
      {FoldL TaskSpecs fun {$ In _#D#_#_} D+In end 0}
   
      Tasks =
      {Map TaskSpecs fun {$ T#_#_#_} T end}

      Dur =    % task --> duration 
      {MakeRecord dur Tasks}
      {ForAll TaskSpecs proc {$ T#D#_#_} Dur.T = D end}

      Resources =
      {FoldL TaskSpecs
       fun {$ In _#_#_#Resource}
	  if Resource==noResource orelse {Member Resource In}
	  then In else Resource|In end
       end
       nil}

      ExclusiveTasks =  % list of lists of exclusive tasks
      {FoldR Resources
       fun {$ Resource Xs}
	  {FoldR TaskSpecs
	   fun {$ Task#_#_#ThisResource In}
	      if Resource==ThisResource then Task|In else In end
	   end
	   nil} | Xs
       end
       nil}

      SortedExclusiveTasks =  % most requested resource first
      {Sort ExclusiveTasks
       fun {$ Xs Ys}
	  fun {Aux Xs}
	     {FoldL Xs fun {$ In X} In + Dur.X end 0}
	  end
       in
	  {Aux Xs} > {Aux Ys}
       end}

      ExclusionPairs =  
      {FoldR SortedExclusiveTasks
       fun {$ Xs Ps}
	  {FoldRTail Xs
	   fun {$ Y|Ys Pss}
	      {FoldR Ys fun {$ Z Pss} Y#Z|Pss end Pss}
	   end
	   Ps}
       end
       nil}
   in
      proc {$ Start}
	 Choices
      in 
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

      % impose Constraints

	 {Constraints Start Dur}

      % impose resource constraints

	 if Global then skip else
	    {FoldR ExclusionPairs
	     fun {$ A#B Cs}
		{FD.disjointC Start.A Dur.A Start.B Dur.B} | Cs
	     end
	     
	     nil
	     Choices}
	 end
	 
      % enumerate exclusion choices

	 if Global then
	    {Schedule.serializedDisj SortedExclusiveTasks Start Dur}
	    {Schedule.firstsLastsDist SortedExclusiveTasks Start Dur}
	 else {FD.distribute naive Choices}
	 end

      % fix all start points to minimum after enumeration

	 thread
	    choice
	       {Record.forAll Start proc {$ S} S = {FD.reflect.min S} end}
	    end
	 end

      end
   end 

   BridgeSolNonGlobal =
   [start(a1:3 a2:13 a3:7 a4:15 a5:1 a6:38 ab1:19 ab2:23 ab3:34 ab4:47
	  ab5:11 ab6:57 b1:18 b2:22 b3:33 b4:46 b5:10 b6:56 l:30 m1:20
	  m2:36 m3:44 m4:52 m5:12 m6:60 p1:9 p2:29 pa:0 pe:104 s1:10
	  s2:18 s3:29 s4:42 s5:6 s6:46 t1:44 t2:56 t3:68 t4:92 t5:80
	  ua:78 ue:0 v1:56 v2:92)]

   BridgeSolGlobal =
   [start(a1:7 a2:1 a3:11 a4:3 a5:5 a6:35 ab1:23 ab2:11 ab3:44 ab4:27
          ab5:15 ab6:54 b1:22 b2:10 b3:43 b4:26 b5:14 b6:53 l:30 m1:28
          m2:12 m3:52 m4:44 m5:20 m6:60 p1:19 p2:6 pa:0 pe:104 s1:14
          s2:6 s3:39 s4:22 s5:10 s6:43 t1:44 t2:68 t3:92 t4:56 t5:80
          ua:78 ue:0 v1:56 v2:92)]


   Return=

   fd([bridge([
	       nonglobal(equal(fun {$}
				{Search.base.best {Compile BridgeProb false}
				 proc {$ Old New} Old.pe >: New.pe end}
			     end
			     BridgeSolNonGlobal)
			 keys: [fd])
	       global(equal(fun {$}
				{Search.base.best {Compile BridgeProb true}
				 proc {$ Old New} Old.pe >: New.pe end}
			     end
			     BridgeSolGlobal)
		       keys: [fd])
	       nonglobal_entailed(entailed(proc {$}
				{Search.base.best {Compile BridgeProb false}
				 proc {$ Old New} Old.pe >: New.pe end _}
			     end)
			 keys: [fd entailed])
	       global_entailed(entailed(proc {$}
				{Search.base.best {Compile BridgeProb true}
				 proc {$ Old New} Old.pe >: New.pe end _}
			     end)
		       keys: [fd entailed])
		  ])
	    ])

   
end
