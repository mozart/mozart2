%%%  Programming Systems Lab, DFKI Saarbruecken, 
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Joerg Wuertz 
%%%  Email: wuertz@dfki.uni-sb.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

local
   
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

in 
   
   fun {Compiler Specification TaskDistribution ResourceDistribution ResourceConstraint}
      TaskSpecs = Specification.taskSpec
      Constraints = Specification.constraints

      %% simply add the durations
      MaxTime = {FoldL TaskSpecs fun {$ In _#D#_#_} D+In end 0}
      
      Tasks = {FoldL TaskSpecs fun {$ In T#_#_#_} T|In end nil}
      
      %% task -> duration
      Dur = {Record.make dur Tasks}
      
      {ForAll TaskSpecs proc {$ T#D#_#_} Dur.T = D end}

      Resources =
      {FoldR TaskSpecs
       fun {$ _#_#_#Resource In}
	  if Resource==noResource orelse {Member Resource In}
	  then In else Resource|In end
       end
       nil}
      
      
      ExclusiveTasks =  % list of lists of exclusive tasks
      {MakeExclusiveTasks Resources TaskSpecs}
      
   in
      proc {$ Sol}
	 r(start:Start
	   dur: !Dur) = Sol
      in 
	 
	 %% task --> start time
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

	 %% Resource constraints

	 {ResourceConstraint Start Dur ExclusiveTasks}

	 %% Resource Distribution
	 thread
	    choice
	       if ResourceDistribution == NoRE then skip
	       else
		  %% enumerate exclusion choices
		  {ResourceDistribution Start Dur ExclusiveTasks}
	       end
	       %% fix all start points to minimum after Distribution
	       if TaskDistribution == NoTE then skip
	       else
		  choice
		     {TaskDistribution Start Dur ExclusiveTasks}
		  end
	       end
	    end
	 end

      end
   end
end





