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
      case CFails == Limit then nil
      else
         case {IsFree KF} then
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

%% LDS

local
   fun {LDSprobe K S Is}
      case Is==nil then skip
      else {Space.commit S Is}
      end
      case {Space.ask S}
      of succeeded then S
      [] failed then nil
      [] alternatives(N) then
         case K of 0 then
            {LDSprobe 0 S 1}
         else
            case {LDSprobe K-1 {Space.clone S} 2#N}
            of nil then
               {LDSprobe K S 1}
            elseof R then
               R
            end
         end
      end
   end
   fun {DoLDS KFirst KLast P}
      case KFirst=<KLast then
         case {LDSprobe KFirst {Space.new P} nil} of
            nil then {DoLDS KFirst+1 KLast P}
         elseof S then S end
      else
         nil
      end
   end

   fun {LDS  KFirst KLast P}
      case {DoLDS KFirst KLast P} of
         nil then nil
      [] S then [{Space.merge S}]
      end
   end

   local
      class Counter from BaseObject
         attr val: 0
         meth reset
            val <- 0
         end
         meth inc
            val <- @val+1
         end
         meth get(?X)
            X = @val
         end
      end
      class Solution from BaseObject
         attr quality sol
         meth reset
            quality <- ~1
            sol <- nil
         end
         meth new(Q S)
            case @quality == ~1 orelse
               Q < @quality then
               sol <- S
               quality <- Q
            else skip end
         end
         meth get(q:?Q s:?S)
            Q = @quality
            S = @sol
         end
      end
      NbSolutions = {New Counter reset}
      BestSolution = {New Solution reset}
      fun {DoLDS KFirst KLast MaxNbSolutions P}
         fun {LDSprobe K S In}
            case In==nil then skip
            else {Space.commit S In}
            end
            case {Space.ask S}
            of succeeded then
               I  NS
            in
               NS = {Space.merge S}
               {BestSolution new(NS.start.pe NS)}
               {NbSolutions inc}
               {NbSolutions get(I)}
               case I >= MaxNbSolutions then
                  break
               else nil end
            [] failed then nil
            [] alternatives(N) then
               case K of 0 then
                  {LDSprobe 0 S 1}
               else
                  C = {Space.clone S}
               in
                  case {LDSprobe K-1 C 2#N}
                  of break then break
                  else %nil
                     {LDSprobe K S 1}
                  end
               end
            end
         end
         S = {Space.new P}
      in
         case KFirst=<KLast andthen {LDSprobe KFirst S nil} of nil then
            {DoLDS KFirst+1 KLast MaxNbSolutions P}
         else Q B in
            {BestSolution get(q:Q s:B)}
            case B of nil then nil
            else B end
         end
      end
   in
      LDSOPT = 40
      fun {LDSopt KFirst KLast MaxNbSolutions P}
         {NbSolutions reset}
         {BestSolution reset}
         case {DoLDS KFirst KLast MaxNbSolutions P} of
            nil then nil
         [] S then [S]
         end
      end
   end


in

   fun {SearchLDS1 Problem Order RCD}
      {LDS 1 1 Problem}
   end

   fun {SearchLDS2 Problem Order RCD}
      {LDS 2 2 Problem}
   end

   fun {SearchLDSEarly Problem Order RCD}
      {LDS 0 6 Problem}
   end
   fun {SearchLDSLate Problem Order RCD}
      {LDS 7 10 Problem}
   end
   fun {SearchLDSOpt Problem Order RCD}
      {LDSopt 0 2 LDSOPT Problem}
   end
end

fun {WrapSearch S}
   case S == nil orelse S == stopped then S
   else S.1
   end
end

%% classical search

proc {SearchDFS Problem Order RCD ?Sol}
   Solver = {New Search.object script(Problem rcd:RCD)}
in
   {Solver next(Sol)}
end

proc {SearchBABS Problem Order RCD ?Sol}
   Solver = {New Search.object script(Problem Order rcd:RCD)}
in
   {Solver last(Sol)}
end

%% search classes for finish and lower phase

class SearchBAB from Search.object
   attr label last
   meth run(?Sol)
      Solution = thread {WrapSearch {self next($)}} end
      Last = @last
   in
      thread
         case Solution == nil
         then
            Sol = Last
         elsecase Solution == stopped then
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


class SearchLB from BaseObject
   attr
      ub label problem lb last searchObject rcd
   meth start(spec:                 TaskSpecification
              compiler:             Compiler
              taskDistribution:     TaskEnumeration
              resourceDistribution: ResourceEnumeration
              resourceConstraints:  ResourceConstraints
              ub:                   UpperBound
              lb:                   LowerBound
              label:                LowerLabel
              order:                Order
              rcd:                  RCD
              solution: ?Solution)
      SimpleProblem =  {Compiler TaskSpecification TaskEnumeration
                        ResourceEnumeration ResourceConstraints}
      UB = case UpperBound
           of nil then
              {FoldL TaskSpecification.taskSpec
               fun{$ I D} I+D.2 end 0}
           else UpperBound
           end
   in
      ub <- UB
      label <- LowerLabel
      problem <- SimpleProblem
      lb <- 0
      last <- nil
      rcd <- RCD
      {LowerLabel tk(conf(text: '0'))}
      {self run(Solution)}
      {Wait Solution}
      LowerBound = @lb
   end
   meth stop
      {@searchObject stop}
   end
   meth run(?Sol)
      Problem = @problem
   in
      {Trace @lb#@ub}
      case @ub==@lb+1 then Sol=@last
      else Mid = (@lb+@ub) div 2
         SO = {New Search.object script(proc{$ X}
                                           {Problem X}
                                           X.start.pe =<: Mid
                                        end
                                       rcd: @rcd)}
         Tmp = thread {WrapSearch {SO next($)}} end
         Label = @label
         Last = @last
         LB = @lb
      in
         searchObject <- SO
         thread
            case Tmp of nil
            then
               {Label tk(conf(text: {Int.toString Mid}))}
               {self goMid(Mid Sol)}
            [] stopped then Sol=Last
            else
               {Label tk(conf(text: {Int.toString LB}))}
               {self goTmp(Mid Tmp Sol)}
            end
         end
      end
   end
   meth goMid(Mid ?Sol)
      lb <- Mid
      {self run(Sol)}
   end
   meth goTmp(Mid Tmp ?Sol)
      ub <- Mid
      last <- Tmp
      {self run(Sol)}
   end
   meth resume(UB ?LowerBound ?Sol)
      case UB < @ub then ub <- UB
      else skip
      end
      {@label tk(conf(text: {Int.toString @lb}))}
      {self run(Sol)}
      {Wait Sol}
      LowerBound = @lb
   end
end
