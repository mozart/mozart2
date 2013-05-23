%%%  Programming Systems Lab, DFKI Saarbruecken, 
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Joerg Wuertz 
%%%  Email: wuertz@dfki.uni-sb.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

fun{GetPE Problem}
   {Int.toString {FD.reflect.min {Problem.1}.start.pe}}
end

local
   fun {Convert Ss}
      case Ss of nil then nil
      [] S|Sr then
	 if S >= 48 andthen S =< 57
	 then {Convert Sr}
	 else S|Sr
	 end
      end
   end
in 
   fun {TaskToJob Task}
      TaskString = {Reverse {Atom.toString Task}}
   in
      {String.toAtom {Reverse {Convert TaskString}}}
   end
end

fun {GetUnscheduled Specification Resources}
   TaskSpecs   = Specification.taskSpec
   %% UnScheduled = r(m1: [t1 t2 ...] ... mk: [t8 t9 ...])
   UnscheduledD = {NewDictionary}
   {ForAll Resources proc{$ R} {Dictionary.put UnscheduledD R nil} end}
   {ForAll TaskSpecs proc{$ T#_#_#R}
			case R of noResource then skip
			else Old = {Dictionary.get UnscheduledD R} in
			   {Dictionary.put UnscheduledD R T|Old}
			end
		     end}
   Unscheduled  = {Record.make unScheduled Resources}
   {ForAll Resources proc{$ R}
			Unscheduled.R = {Dictionary.get UnscheduledD R}
		     end}
in
   Unscheduled
end

local
   proc {Help Ls Preds Succs}
      case Ls
      of [Task]
      then Old = {Dictionary.get Succs Task} in 
	 {Dictionary.put Succs Task pe|Old}
      [] First|Second|Rest
      then
	 OldP = {Dictionary.get Preds Second}
	 OldS = {Dictionary.get Succs First}
      in
	 {Dictionary.put Preds Second First|OldP}
	 {Dictionary.put Succs First Second|OldS}
	 {Help Second|Rest Preds Succs}
      end
   end
in 
   fun {GetResPredSucc Specification Start Resources Tasks}
      TaskSpecs = Specification.taskSpec
      %% UnScheduled = r(m1: [t1 t2 ...] ... mk: [t8 t9 ...])
      UnscheduledD = {NewDictionary}
      {ForAll Resources proc{$ R} {Dictionary.put UnscheduledD R nil} end}
      {ForAll TaskSpecs proc{$ T#_#_#R}
			   case R of noResource then skip
			   else Old = {Dictionary.get UnscheduledD R} in
			      {Dictionary.put UnscheduledD R T|Old}
			   end
			end}
      Sorted  = {Record.make unScheduled Resources}
      {ForAll Resources proc{$ R}
			   Sorted.R = {Sort
				       {Dictionary.get UnscheduledD R}
				       fun{$ A B}
					  {FD.reflect.min Start.A} < {FD.reflect.min Start.B}
				       end}
			end}
	 
      %% Compute the sets of predecessors and successors
      PredsD = {NewDictionary}
      SuccsD = {NewDictionary}
      {ForAll Tasks proc{$ T}
		       {Dictionary.put PredsD T nil}
		       {Dictionary.put SuccsD T nil}
		    end}
      {Record.forAll Sorted proc{$ Job}
			       OldPred = {Dictionary.get PredsD Job.1}
			    in
			       {Dictionary.put PredsD Job.1 pa|OldPred}
			       {Help Job PredsD SuccsD}
			    end}
      Preds = {MakeRecord preds Tasks}
      Succs = {MakeRecord succs Tasks}
      {ForAll Tasks proc{$ T}
		       Preds.T = {Dictionary.get PredsD T}
		       Succs.T = {Dictionary.get SuccsD T}
		    end}

   in
      o(Preds Succs Sorted)
   end
   fun {GetThemAll Specification}
      TaskSpecs = Specification.taskSpec
      Resources = {FoldL TaskSpecs
		   fun {$ In _#_#_#Resource}
		      if Resource==noResource orelse {Member Resource In}
		      then In else Resource|In end
		   end
		   nil}
      Tasks       = {Map TaskSpecs fun{$ Task#_#_#_} Task end}  
      %% UnScheduled = r(m1: [t1 t2 ...] ... mk: [t8 t9 ...])

      %% Compute the set of jobs as a record
      JobNames    = {FoldL TaskSpecs
		     fun {$ In Task#_#_#_}
			TTJ = {TaskToJob Task}
		     in 
			if Task==pe orelse Task==pa orelse
			   {Member TTJ In}
			then In else TTJ|In end
		     end
		     nil}
      JobsD        = {NewDictionary}
      {ForAll JobNames proc{$ JN} {Dictionary.put JobsD JN nil} end}
      {ForAll {Reverse TaskSpecs}
       proc{$ T#_#_#_}
	  First = {TaskToJob T} in
	  if T==pe orelse T==pa then skip
	  else Old = {Dictionary.get JobsD First} in
	     {Dictionary.put JobsD First T|Old}
	  end
       end}
      Jobs        = {Record.make jobs JobNames}
      {ForAll JobNames proc{$ R}
			  Jobs.R = {Dictionary.get JobsD R}
		       end} 
      %% Machines maps tasks to resource: r(a1:m1 a2:m3 ...)
      Machines    = {Record.make machines Tasks}
      {ForAll TaskSpecs proc {$ Task#_#_#Resource}
			   Machines.Task = Resource
			end}
      PredsD = {NewDictionary}
      %% Compute Job preds and succs
      SuccsD = {NewDictionary}
      {ForAll Tasks proc{$ T}
		       {Dictionary.put PredsD T nil}
		       {Dictionary.put SuccsD T nil}
		    end}
      {ForAll TaskSpecs proc{$ Task#_#Pred#_}
			   OldP = {Dictionary.get PredsD Task}
			in 
			   {Dictionary.put PredsD Task {Append OldP Pred}}
			   {ForAll Pred proc{$ P}
					   OldS = {Dictionary.get SuccsD P} in
					   {Dictionary.put SuccsD P Task|OldS}
					end}
			end}
      Preds = {MakeRecord preds Tasks}
      Succs = {MakeRecord succs Tasks}
      {ForAll Tasks proc{$ T}
		       Preds.T = {Dictionary.get PredsD T}
		       Succs.T = {Dictionary.get SuccsD T}
		    end}
	 
   in
      o(Tasks Resources Jobs Machines Preds Succs)
   end
end
