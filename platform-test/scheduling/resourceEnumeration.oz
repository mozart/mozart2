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
      case S==0.0 then FloatFDSup-1.0
      else
         SQRT = {Float.sqrt {Abs S}}
         BSPIJ = {Int.toFloat SlackIJ}/SQRT
         BSPJI = {Int.toFloat SlackJI}/SQRT
         {Min FloatFDSup-1.0 {Min BSPIJ BSPJI}}
      end
   end

   fun {DurationTasks Tasks Dur}
      {FoldL Tasks fun{$ I T} I+Dur.T end 0}
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Constraining tasks
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   proc {Before Task Tasks Start Dur}
      {ForAll Tasks proc{$ T}
                       case Task==T then skip
                       else Start.Task+Dur.Task =<: Start.T
                       end
                    end}
   end

   proc {After Task Tasks Start Dur}
      {ForAll Tasks proc{$ T}
                       case Task==T then skip
                       else Start.T+Dur.T =<: Start.Task
                       end
                    end}
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Enumeration
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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
            case {IsKinded TP.3}
            then
               TCost = {TaskPairCost TP Start Dur}
            in
            case TCost < CCost
%              case TCost =< CCost
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
            case TaskPairs of nil then skip
            [] TP|TPr then
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
                  case S==0.0 then BSPIJ=2 BSPJI=1
                  else
                     SQRT = {Float.sqrt {Abs S}}
                     BSPIJ = {Int.toFloat SlackIJ}/SQRT
                     BSPJI = {Int.toFloat SlackJI}/SQRT
                  end
                  case BSPIJ>BSPJI then
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

   %% as in CHIP
   %% resources with largest duration first, static order. Then distribute
   %% tasks
   proc {MaximalDurStat Start Dur ExclusiveTasks}
      SortedExclusiveTasks =  % larger duration goes first
      {Sort ExclusiveTasks
       fun{$ Xs Ys}
          {DurationTasks Xs Dur} > {DurationTasks Ys Dur}
       end}
   in
      {LabelResources SortedExclusiveTasks Start Dur}
   end


   %% Consider all pairs of tasks on a resource. Choose the pair with minimal
   %% slack according to the used ordering (Cheng/Smith).
   proc {MinimalPairs Start Dur ExclusiveTasks}
      choice
         ControlledPairs = {FoldR ExclusiveTasks
                            fun {$ Xs Ps}
                               {FoldRTail Xs
                                fun {$ Y|Ys Pss}
                                   {FoldR Ys fun {$ Z Pss} Y#Z#_|Pss end Pss}
                                end
                                Ps}
                            end
                         nil}
      in
         %% Control each pair by a variable C. If C is determined, it needs
         %% not to be enumerated.
         {ForAll ControlledPairs proc{$ I#J#C}
                                    {FD.disjointC Start.I Dur.I Start.J Dur.J C}
                                 end}
         {TaskPairEnum ControlledPairs ControlledPairs Start Dur}
      end
   end



   proc {TaskIntervalsProofNew Start Dur Tasks}
      {FD.schedule.taskIntervalsDistP Tasks Start Dur}
   end

   proc {TaskIntervalsOptNew Start Dur Tasks}
      {FD.schedule.taskIntervalsDistO Tasks Start Dur}
   end

   proc {MinimalSlackFirstsLasts Start Dur Tasks}
      {FD.schedule.firstsLastsDist Tasks Start Dur}
   end

   proc {MinimalSlackFirsts Start Dur Tasks}
      {FD.schedule.firstsDist Tasks Start Dur}
   end

   proc {MinimalSlackLasts Start Dur Tasks}
      {FD.schedule.lastsDist Tasks Start Dur}
   end

end
