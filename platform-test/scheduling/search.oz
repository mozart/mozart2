%%%  Programming Systems Lab, DFKI Saarbruecken, 
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Joerg Wuertz 
%%%  Email: wuertz@dfki.uni-sb.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

%% resource limited search (number of failures)
local
   
   C = {NewCell 0}
      
   proc {NewKiller ?Killer ?KillFlag}
      proc {Killer}
	 KillFlag=kill
      end
   end
      
   fun {OneDepthNR KF S Limit}
      CFails = {Exchange C $ CFails}
   in
      if CFails == Limit then nil
      else
	 if {IsFree KF} then
	    case {Space.ask S}
	    of failed then
	       CFails = {Exchange C $ CFails}
	    in
\ifdef TRACEON
	       {Trace fails#CFails#Limit}
\endif
	       {Exchange C _ CFails+1}
	       nil
	    [] succeeded then S
	    [] alternatives(N) then C={Space.clone S} in
	       {Space.commit S 1}
	       case {OneDepthNR KF S Limit}
	       of nil then {Space.commit C 2#N} {OneDepthNR KF C Limit}
	       elseof O then O
	       end
	    end
	 else 
	    nil
	 end
      end
   end
      
   fun {WrapP S}
      proc {$ X}
	 {Space.merge {Space.clone S} X}
      end
   end
      
   fun {OneDepth P Limit}
      KF={NewKiller _} S={Space.new P}
   in
      {OneDepthNR KF S Limit}
   end
in
   fun {SolveDepth P Limit}
      {Exchange C _ 0}
      case {OneDepth P Limit}
      of nil then nil
      elseof S then [{WrapP S}]
      end
   end
end


fun {WrapSearch S}
   if S == nil orelse S == stopped then S
   else S.1
   end
end

%% classical search
      
%% search classes for finish and lower phase
   
class SearchBAB from Search.object
   attr label last
   meth run(?Sol)
      Solution = thread {WrapSearch {self next($)}} end
      Last = @last
   in
      thread
	 if Solution == nil
	 then
	    Sol = Last 
	 elseif Solution == stopped then
	    Sol = Last
	 else
	    {self goOn(Solution Sol)}
	 end
      end
   end
   meth goOn(Solution ?Sol)
      {@label tk(conf(text: {Int.toString Solution.start.pe}))}
      last <- Solution
      {self run(Sol)}
   end
   meth resume(?Sol)
      case @last of nil then skip
      else 
	 {@label tk(conf(text: {Int.toString @last.start.pe}))}
      end
      {self run(Sol)}
   end
   meth start(spec:                 TaskSpecification
	      compiler:             Compiler
	      taskDistribution:     TaskEnumeration
	      resourceDistribution: ResourceEnumeration
	      resourceConstraints:  ResourceConstraints
	      ub:                   UpperBound
	      lb:                   _
	      order:                Order
	      label:                FLabel
 	      rcd:                  RCD
	      solution: ?Solution)
      SimpleProblem =  {Compiler TaskSpecification TaskEnumeration
			ResourceEnumeration ResourceConstraints}
      Problem = case UpperBound 
		of nil then
		   SimpleProblem
		else
		   proc{$ X}
		      {SimpleProblem X}
		      X.start.pe <: UpperBound
		   end
		end
   in
      {self script(Problem Order rcd:RCD)}
      label <- FLabel
      last <- nil
      {self run(Solution)}
   end
end
   


