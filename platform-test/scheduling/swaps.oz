%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Joerg Wuertz
%%%  Email: wuertz@dfki.uni-sb.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

local
   GetMin = FD.reflect.min
   GetMax = FD.reflect.max

   fun{MakeExclusiveTasks Resources TaskSpecs}
      {FoldR Resources
       fun {$ Resource Xs}
          {FoldR TaskSpecs
           fun {$ Task#_#_#ThisResource In}
              case Resource==ThisResource then Task|In else In end
           end
           nil} | Xs
       end
       nil}
   end

   fun {FindPaths o(Task UB Dur ResSuccs JobSuccs Path OccCrit#Paths)}
      JobS = JobSuccs.Task.1
      ResS = ResSuccs.Task.1
   in
      %% ResS = pe means that Task is last on that resource. Nevertheless,
      %% Task needs not to be last in the graph!
      case JobS==pe andthen ResS==pe then
         {Store Path UB Dur OccCrit#Paths}
      else
         Tmp
      in
         case JobS\=pe andthen OccCrit.JobS.crit then
            Tmp = {FindPaths o(JobS UB Dur ResSuccs JobSuccs
                               JobS|Path OccCrit#Paths)}
         else Tmp = OccCrit#Paths
         end
         case  ResS\=pe andthen OccCrit.ResS.crit then
            {FindPaths o(ResS UB Dur ResSuccs JobSuccs ResS|Path Tmp)}
         else
            Tmp
         end
      end
   end

   fun {Store Path UB Dur OccCrit#Paths}
      case UB=={FoldL Path fun{$ I T} Dur.T+I end 0}
      then
         NewOcc = {FoldL Path fun{$ I Task}
                                 Entry = I.Task
                              in
                                 {AdjoinAt I Task r(occ: Entry.occ+1
                                                    crit: Entry.crit)}
                              end OccCrit}
      in
         NewOcc#({Reverse Path}|Paths)
      else OccCrit#Paths
      end
   end

   fun {MakeSwap Task ResSuccs PertProblem SortedRes Tasks UB}
      %% Swap Task and its successor
      Succ = ResSuccs.Task.1
   in
      {Search.one.depthP
       proc{$ X}
          {PertProblem.1 X}
          Dur = X.dur
          Start = X.start
       in
          {Record.forAll SortedRes
           proc{$ Tasks}
              {ForAllTail Tasks proc{$ T1|Ts}
                                   case Ts of nil then skip
                                   else
                                      T2=Ts.1
                                   in
                                      case T1==Task then
                                         Start.Succ+Dur.Succ =<: Start.Task
                                      elsecase T1==Succ then
                                         Start.Task+Dur.Task =<: Start.T2
                                      elsecase T2==Task then
                                         Start.T1+Dur.T1 =<: Start.Succ
                                      else
                                         Start.T1+Dur.T1 =<: Start.T2
                                      end
                                   end
                                end}
           end}
       end 1 _}
   end

   fun {MakeTrySwap o(Task ResSuccs PertProblem SortedRes Tasks UB
                      Spec FailureLimit ?Enum)}
      %% Swap Task and its successor
      Succ = ResSuccs.Task.1
      TaskSpecs = Spec.taskSpec
      %% Machines maps tasks to resource: r(a1:m1 a2:m3 ...)
      Machines    = {Record.make machines Tasks}
      {ForAll TaskSpecs proc {$ Task#_#_#Resource}
                           Machines.Task = Resource
                        end}
      Resource = Machines.Task
      ExclusiveTasks =  % list of lists of exclusive tasks
      {MakeExclusiveTasks {Arity SortedRes} TaskSpecs}
   in
      {SolveDepth
       proc{$ X}
          {PertProblem.1 X}
          Dur = X.dur
          Start = X.start
       in
          %% try to find a better solution
          X.start.pe <: UB
          {Enum Start Dur ExclusiveTasks}
          choice
             {ForAllTail SortedRes.Resource
              proc{$ T1|Ts}
                 case Ts of nil then skip
                 else
                    T2=Ts.1
                 in
                    case T1==Task then
                       Start.Succ+Dur.Succ =<: Start.Task
                    elsecase T1==Succ then
                       Start.Task+Dur.Task =<: Start.T2
                    elsecase T2==Task then
                       Start.T1+Dur.T1 =<: Start.Succ
                    else
                       Start.T1+Dur.T1 =<: Start.T2
                    end
                 end
              end}
          end
          end FailureLimit}
   end
in
   fun {Paths o(Start Dur ResSuccs JobSuccs JobPreds Sorted Tasks)}
      %% critical paths are only those for which length = MakeSpan
      OccCrit = {MakeRecord occCrit Tasks}
      UB = Start.pe
   in
      {ForAll Tasks proc{$ Task}
                       case Task of pa
                       then OccCrit.pa = r(occ: 0
                                           crit: false)
                       [] pe
                       then OccCrit.pe = r(occ: 0
                                           crit: false)
                       else
                          case {FD.reflect.size Start.Task} of 1
                          then OccCrit.Task = r(occ: 0
                                                crit: true)
                          else OccCrit.Task = r(occ:0
                                                crit: false)
                          end
                       end
                    end}
      {Record.foldL Sorted fun{$ In Resource}
                              First = Resource.1
                           in
                              case OccCrit.First.crit
                                 andthen JobPreds.First==[pa]
                              then
                                 {FindPaths o(First UB Dur ResSuccs
                                              JobSuccs [First] In)}
                              else In
                              end
                           end OccCrit#nil}
   end

   fun {AnalyzeSwaps o(Occ Paths ResSuccs JobSuccs ResPreds
                       JobPreds Tasks Start Dur)}
      {FoldL Tasks
       fun{$ I Task}
          case Task==pe orelse Task==pa then I
          else
             U = ResSuccs.Task.1
          in
%            case U\=pe andthen (Occ.Task.crit orelse Occ.U.crit)
             case U\=pe andthen (Occ.Task.crit andthen Occ.U.crit)
             then
                S = ResPreds.Task.1
                V = ResSuccs.U.1
                TP = JobPreds.Task.1
                UP = JobPreds.U.1
                TPP = JobSuccs.Task.1
                UPP = JobSuccs.U.1
                ULow = {Max {GetMin Start.S}+Dur.S {GetMin Start.UP}+Dur.UP}
                TLow = {Max {GetMin Start.TP}+Dur.TP ULow+Dur.U}
                TUp = {Min {GetMax Start.V} {GetMax Start.TPP}}
                UUp = {Min {GetMax Start.UPP} TUp-Dur.Task}
                Gain = {Min UUp-ULow-Dur.U TUp-TLow-Dur.Task}
                Occ0 = 0
                Occ1 Occ2
             in
                {Trace Task#U#Gain}
                case TUp-ULow >= Dur.Task+Dur.U andthen Gain > 0
                then
                   case Occ.UPP.crit then Occ1 = {Max Occ0 Occ.UPP.occ}
                   else Occ1=Occ0
                   end
                   case Occ.TP.crit then Occ2 = {Max Occ1 Occ.TP.occ}
                   else Occ2=Occ1
                   end
                   case Occ2 > 0
                   then (Task#Occ2#Gain)|I
                   else I
                   end
                else I
                end
             else I
             end
          end
       end nil}
   end

   fun {Repair o(Occ Paths Swaps PertProblem ResSuccs SortedRes
                 Tasks UB ?NewSol)}
      NumberOfCrits = {Length Paths}
      BestSwap = {FoldL Swaps fun{$ I Task#O#Gain}
                                 case O==NumberOfCrits andthen
                                    %% the better is Gain > I.2 end noTask#0}
                                    Gain > I.2
                                 then Task#Gain
                                 else I
                                 end
                              end noTask#0}
   in
      case BestSwap.1 of noTask then false
      else
         {Trace 'swapping '#BestSwap.1#' and '#ResSuccs.(BestSwap.1).1}
         NewSol={MakeSwap BestSwap.1 ResSuccs PertProblem SortedRes Tasks UB}
         true
      end
   end

   fun {TrySwap o(Occ Paths Swaps PertProblem ResSuccs SortedRes
                  Tasks UB Spec FailureLimit Enum ?NewSol)}
      /*
      BestSwap = {FoldL Swaps fun{$ I Task#O#Gain}
                                 case O > I.2 then
                                    Task#O#Gain
                                 elsecase O==I.2 andthen Gain>I.3 then
                                    Task#O#Gain
                                 else I
                                 end
                              end noTask#0#0}
   in
      case BestSwap.1 of noTask then false
      else
         {Trace 'try swapping '#BestSwap.1#' and '#ResSuccs.(BestSwap.1).1}
         Sol
      in
         {MakeTrySwap o(BestSwap.1 ResSuccs PertProblem SortedRes
                        Tasks UB Spec FailureLimit Enum) ?Sol}
         case Sol of nil then false
         else NewSol = Sol
            true
         end
      end
      */
      false
   end
end
