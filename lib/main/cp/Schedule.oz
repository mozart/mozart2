%%%
%%% Authors:
%%%   Joerg Wuertz (wuertz@dfki.de)
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Joerg Wuertz, 1997
%%%   Tobias Mueller, 1997
%%%   Christian Schulte, 1997, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

require
   CpSupport(waitStable:     WaitStable

             vectorsToLists: VectorsToLists
             vectorToTuple:  VectorToTuple

             formatOrigin:   FormatOrigin)

   at '../CpSupport.ozf'

import
   SCP at 'x-oz://boot/Schedule'

   FD(bool
      is
      sum
      reflect)

   ErrorRegistry(put)

   Error(formatTypes
         formatGeneric
         formatAppl
         formatHint
         format
         dispatch)

export
   serialized:            SchedCpIterate
   serializedDisj:        SchedDisjunctive
   disjoint:              SchedDisjointCard
   taskIntervals:         SchedTaskIntervals
   cumulative:            Cumulative
   cumulativeEF:          CumulativeEF
   cumulativeTI:          SchedCumulativeTI
   cumulativeUp:          SchedCpIterateCapUp

   taskIntervalsDistP:    TaskIntervalsDistP
   taskIntervalsDistO:    TaskIntervalsDistO
   firstsLastsDist:       NewDistFL
   firstsDist:            NewDistF
   lastsDist:             NewDistL

define

   %% Hack, needed for dynamic linking of *.so

   {Wait FD.bool}

   SchedDisjointCard    =       SCP.disjoint_card
   SchedCpIterate =             SCP.cpIterate
   SchedTaskIntervals = SCP.taskIntervals
   SchedDisjunctive =   SCP.disjunctive
   SchedCpIterateCap    =       SCP.cpIterateCap
   SchedCumulativeTI    =       SCP.cumulativeTI
   SchedCpIterateCapUp =        SCP.cpIterateCapUp
   SchedTaskIntervalsProof = SCP.taskIntervalsProof
   SchedFirstsLasts =   SCP.firstsLasts


   %% Propagators

   proc {Cumulative Tasks Start Dur Use Capacities}
      {SchedCpIterateCap Tasks Start Dur Use Capacities 0}
   end

   proc {CumulativeEF Tasks Start Dur Use Capacities}
      {SchedCpIterateCap Tasks Start Dur Use Capacities 1}
   end


   %% Distribution

   local
      proc {Check Tasks Start Dur}
         if {IsList Tasks} andthen
            {All Tasks fun {$ Ts}
                          {IsList Ts} andthen
                          {All Ts fun {$ T}
                                     {HasFeature Start T} andthen
                                     {HasFeature Dur T}
                                  end}
                       end}
         then skip else
            {Exception.raiseError
             schedule('Check'
                      [Tasks Start Dur]
                      vector(vector)
                      1
                      'Scheduling: records with features for start times and durations expected.')}
         end

         if {HasFeature Start pe} then skip else
            {Exception.raiseError
             schedule('Check'
                      [Tasks Start Dur]
                      record
                      2
                      'Scheduling: task \'pe\' expected.') }
         end

         if {Record.all Start FD.is} then skip else
            {Exception.raiseError
             kernel(type
                    'Check'
                    [Tasks Start Dur]
                    'record(fd)'
                    2
                    'Scheduling: finite domains as start times expected.')}
         end

         if {Record.all Dur IsInt} then skip else
            {Exception.raiseError
             kernel(type
                    'Check'
                    [Tasks Start Dur]
                    'record(int)'
                    3
                    'Scheduling: integers as durations expected.')}
         end
      end


      fun {MakeTaskTuple Ts}
         {VectorToTuple {Map Ts VectorToTuple}}
      end

      proc {EnumTI ETTuple Start Dur OldOut Stream}
         {WaitStable}
         NewStream NewOut
      in
         Stream = dist(OldOut NewOut)|NewStream
         if NewOut==~1 then
            %% finished
            NewStream = nil
         else
            Res#Left#Right = NewOut
            Tasks          = ETTuple.(Res+1)
            LeftTask       = Tasks.(Left+1)
            RightTask      = Tasks.(Right+1)
         in
            dis
               {FD.sum Start.LeftTask#Dur.LeftTask '=<:' Start.RightTask}
            then
               {EnumTI ETTuple Start Dur Res#Left#Right NewStream}
            []
               {FD.sum Start.RightTask#Dur.RightTask '=<:' Start.LeftTask}
            then
               {EnumTI ETTuple Start Dur Res#Right#Left NewStream}
            end
         end
      end

      local
         proc {Before Task RT Tasks Start Dur}
            TaskId    = Tasks.(Task+1)
            StartTask = Start.TaskId
            DurTask   = Dur.TaskId
         in
            {ForAll RT proc {$ T}
                          if Task\=T then
                             {FD.sum StartTask#DurTask '=<:'
                              Start.(Tasks.(1+T))}
                          end
                       end}
         end

         proc {After Task RT Tasks Start Dur}
            StartTask = Start.(Tasks.(Task+1))
         in
            {ForAll RT proc {$ T}
                          if Task\=T then TaskId=Tasks.(1+T) in
                             {FD.sum Start.TaskId#Dur.TaskId '=<:'
                              StartTask}
                          end
                       end}
         end

         fun {MinimalStartOrder Task1 Task2 Start Dur Tasks}
            Start1    = Start.(Tasks.(Task1+1))
            MinStart1 = {FD.reflect.min Start1}
            Start2    = Start.(Tasks.(Task2+1))
            MinStart2 = {FD.reflect.min Start2}
         in
            MinStart1 < MinStart2
            orelse
            (MinStart1 == MinStart2 andthen
             {FD.reflect.max Start1} < {FD.reflect.max Start2})
         end

         fun {MinimalEndOrder Task1 Task2 Start Dur Tasks}
            TaskId1 = (Tasks.(Task1+1))
            TaskId2 = (Tasks.(Task2+1))
            Start1  = Start.TaskId1
            Start2  = Start.TaskId2
            Dur1    = Dur.TaskId1
            Dur2    = Dur.TaskId2
            MaxStartDur1 = {FD.reflect.max Start1} + Dur1
            MaxStartDur2 = {FD.reflect.max Start2} + Dur2
         in
            %% good for proof of optimality
            MaxStartDur1 > MaxStartDur2
            orelse
            (MaxStartDur1 == MaxStartDur2 andthen
             {FD.reflect.min Start1}+Dur1 > {FD.reflect.min Start2}+Dur2)
         end

         proc {Try FLs RestTasks Mode Tasks ETTuple Start Dur Stream}
            {WaitStable}
            case FLs of nil then fail
            [] H|T then
               case T
               of nil then
                  case Mode of firsts then
                     {Before H RestTasks Tasks Start Dur}
                  else
                     {After H RestTasks Tasks Start Dur}
                  end
                  {EnumFL ETTuple Start Dur '#'(H) Stream}
               else
                  choice
                     case Mode of firsts then
                        {Before H RestTasks Tasks Start Dur}
                     else
                        {After H RestTasks Tasks Start Dur}
                     end
                     {EnumFL ETTuple Start Dur '#'(H) Stream}
                  []
                     {Try T RestTasks Mode Tasks ETTuple Start Dur Stream}
                  end
               end
            end
         end

      in

         proc {EnumFL ETTuple Start Dur OldOut Stream}
            {WaitStable}
            NewStream NewOut
         in
            Stream = dist(OldOut NewOut)|NewStream
            case NewOut
            of finished then
               NewStream = nil
            else
               Mode#FL#RestTasks#Res = NewOut
               Tasks                 = ETTuple.(Res+1)
               Sorted = {Sort FL
                         case Mode of firsts then
                            fun {$ X Y}
                               {MinimalStartOrder X Y Start Dur Tasks}
                            end
                         else
                            fun {$ X Y}
                               {MinimalEndOrder X Y Start Dur Tasks}
                            end
                         end}
            in
               {Try Sorted RestTasks Mode Tasks ETTuple Start Dur NewStream}
            end
         end
      end

      proc {HelpDist Dist Enum Tasks Start Dur Flag}
         Stream
         Converted = {VectorsToLists Tasks}
         TaskTuple = {MakeTaskTuple Converted}
      in
         {Check Converted Start Dur}
         {Dist TaskTuple Start Dur Stream Flag}
         {Enum TaskTuple Start Dur nil Stream}
      end
   in
      proc {TaskIntervalsDistO Tasks Start Dur}
         {HelpDist SchedTaskIntervalsProof EnumTI Tasks Start Dur 1}
      end

      proc {TaskIntervalsDistP Tasks Start Dur}
         {HelpDist SchedTaskIntervalsProof EnumTI Tasks Start Dur 0}
      end

      proc {NewDistFL Tasks Start Dur}
         {HelpDist SchedFirstsLasts EnumFL Tasks Start Dur 0}
      end

      proc {NewDistF Tasks Start Dur}
         {HelpDist SchedFirstsLasts EnumFL Tasks Start Dur 1}
      end

      proc {NewDistL Tasks Start Dur}
         {HelpDist SchedFirstsLasts EnumFL Tasks Start Dur 2}
      end
   end


   %%
   %% Register error formatter
   %%

   {ErrorRegistry.put
    schedule
    fun {$ Exc}
       E = {Error.dispatch Exc}
       T = 'error in scheduling'
    in
       case E
       of schedule(A Xs T P S) then
          %% expected Xs:list, T:atom, P:int S:virtualString
          {Error.format
           T unit
           hint(l:'At argument' m:P)
           | {Append
              {Error.formatTypes T}
              hint(l:'In statement' m:{Error.formatAppl A Xs})
              | {Append {FormatOrigin A} {Error.formatHint S}}}
           Exc}
       else
          {Error.formatGeneric T Exc}
       end
    end}

end
