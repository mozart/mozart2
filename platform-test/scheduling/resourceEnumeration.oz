%%%  Programming Systems Lab, DFKI Saarbruecken, 
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Joerg Wuertz 
%%%  Email: wuertz@dfki.uni-sb.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

local

   FloatFDSup = {Int.toFloat FD.sup}
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Task or resource specific values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {TaskPairCost I#J#_ Start Dur}
      StartI=Start.I StartJ=Start.J
      DurI=Dur.I DurJ=Dur.J
      SlackIJ = {FD.reflect.max StartJ}+DurJ-{FD.reflect.min StartI}-DurI-DurJ
      SlackJI = {FD.reflect.max StartI}+DurI-{FD.reflect.min StartJ}-DurI-DurJ
      Div =  {Max SlackIJ SlackJI}
      S = case Div of 0 then FloatFDSup-1.0
	  else {Int.toFloat {Min SlackIJ SlackJI}}/{Int.toFloat Div}
	  end
      SQRT BSPIJ BSPJI
   in
      if S==0.0 then FloatFDSup-1.0
      else 
	 SQRT = {Float.sqrt {Abs S}}
	 BSPIJ = {Int.toFloat SlackIJ}/SQRT
	 BSPJI = {Int.toFloat SlackJI}/SQRT
	 {Min FloatFDSup-1.0 {Min BSPIJ BSPJI}}
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% MaximalDurStat

   proc {LabelResources Res Start Dur}
      case Res of nil then skip
      [] H|T then {LabelResource H T Start Dur}
      end
   end

   proc {LabelResource Res Rest Start Dur}
      case Res of nil then {LabelResources Rest Start Dur}
      [] H|T  then {LabelTasks H T T Rest Start Dur}
      end
   end
   
   proc {LabelTasks Task TaskTail Tail Rest Start Dur}
      choice
	 case TaskTail of nil then {LabelResource Tail Rest Start Dur}
	 [] H|T then
	    dis Start.Task + Dur.Task =<: Start.H 
	    then {LabelTasks Task T Tail Rest Start Dur}
	    []  Start.H + Dur.H =<: Start.Task 
	    then {LabelTasks Task T Tail Rest Start Dur}
	    end
	 end
      end
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% MinimalPairs
   local 
      fun {FindMin CTaskPair CCost Start Dur TPs Acc Rest}
	 case TPs of nil then Rest=Acc CTaskPair
	 [] TP|TPr then
	    if {IsKinded TP.3}
	    then 
	       TCost = {TaskPairCost TP Start Dur}
	    in
	    if TCost < CCost
%	       case TCost =< CCost
	       then
		  case CTaskPair of empty then
		     {FindMin TP TCost Start Dur TPr Acc Rest}
		  else 
		     {FindMin TP TCost Start Dur TPr CTaskPair|Acc Rest}
		  end
	       else {FindMin CTaskPair CCost Start Dur TPr TP|Acc Rest}
	       end
	    else {FindMin CTaskPair CCost Start Dur TPr Acc Rest}
	 end
	 end
      end
   in

      proc {TaskPairEnum All TaskPairs Start Dur}
	 choice
	    if TaskPairs\=nil then
	       Rest 
	       Minimum = {FindMin empty FloatFDSup Start Dur TaskPairs nil Rest}
	    in
	       case Minimum of empty then skip
	       else
		  I#J#Co = !Minimum
		  StartI=Start.I StartJ=Start.J
		  DurI=Dur.I DurJ=Dur.J
		  SlackIJ = {FD.reflect.max StartJ}-{FD.reflect.min StartI}-DurI
		  SlackJI = {FD.reflect.max StartI}-{FD.reflect.min StartJ}-DurJ
		  Div = {Max SlackIJ SlackJI}
		  S = case Div of 0 then FloatFDSup-1.0
		      else {Int.toFloat {Min SlackIJ SlackJI}}/{Int.toFloat Div}
		      end
		  SQRT BSPIJ BSPJI 
	       in
		  if S==0.0 then BSPIJ=2 BSPJI=1
		  else
		     SQRT = {Float.sqrt {Abs S}}
		     BSPIJ = {Int.toFloat SlackIJ}/SQRT
		     BSPJI = {Int.toFloat SlackJI}/SQRT
		  end
		  if BSPIJ>BSPJI then
		     dis StartI+DurI=<:StartJ
		     then Co=0 {TaskPairEnum All Rest Start Dur}
		     [] StartJ+DurJ=<:StartI
		     then Co=1 {TaskPairEnum All Rest Start Dur}
		     end
		  else
		     dis StartJ+DurJ=<:StartI
		     then Co=1 {TaskPairEnum All Rest Start Dur}
		     [] StartI+DurI=<:StartJ
		     then Co=0 {TaskPairEnum All Rest Start Dur}
		     end
		  end
	       end
	    end
	 end
      end


   end

   

in
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% globals
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   proc {NoRE}
      skip
   end
   
   proc {TaskIntervalsProofNew Start Dur Tasks}
      {Schedule.taskIntervalsDistP Tasks Start Dur}
   end
   
   proc {TaskIntervalsOptNew Start Dur Tasks}
      {Schedule.taskIntervalsDistO Tasks Start Dur}
   end

end


