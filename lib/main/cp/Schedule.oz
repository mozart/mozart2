%%%
%%% Authors:
%%%   Jörg Würtz (wuertz@dfki.de)
%%%   Tobias Müller (tmueller@ps.uni-sb.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Jörg Würtz, 1997
%%%   Tobias Müller, 1997
%%%   Christian Schulte, 1997, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

require
   CpSupport(vectorsToLists: VectorsToLists
             vectorToTuple:  VectorToTuple
             vectorToList:   VectorToList

             formatOrigin:   FormatOrigin)

import
   SCP(disjoint_card:      Disjoint
       cpIterate:          SchedCpIterate
       taskIntervals:      SchedTaskIntervals
       disjunctive:        SchedDisjunctive
       cpIterateCap:       SchedCpIterateCap
       cumulativeTI:       SchedCumulativeTI
       cpIterateCapUp:     SchedCpIterateCapUp
       taskIntervalsProof: SchedTaskIntervalsProof
       firstsLasts:        SchedFirstsLasts)
   at 'x-oz://boot/Schedule'

   FD(bool
      is
      sum
      reflect)

   Error(registerFormatter)

export
   %% Serialization propagators for unary propagators
   Serialized
   SerializedDisj
   TaskIntervals

   %% Distribution for unary resources
   TaskIntervalsDistP
   TaskIntervalsDistO
   FirstsLastsDist
   FirstsDist
   LastsDist

   %% Propagators for cumulative scheduling
   Cumulative
   CumulativeEF
   CumulativeTI
   CumulativeUp

   %% Misc propagators
   Disjoint

prepare

   V2A = VirtualString.toAtom
   L2R = List.toRecord

   local
      proc {TupleMapping I M}
         if I>0 then
            M.I={V2A I} {TupleMapping I-1 M}
         end
      end
      fun {RecordMapping As I}
         case As of nil then nil
         [] A|Ar then
            A # if {IsInt A} then {V2A A}
                elseif {IsName A} then {V2A n#I}
                else A
                end|{RecordMapping Ar I+1}
         end
      end
   in
      fun {GetMapping V ?M}
         if {IsTuple V} then N={Width V} in
            M={MakeTuple '#' N} {TupleMapping N M} true
         else As={Arity V} A|_=As in
            if {IsInt A} orelse {IsName A} then
               M={L2R '#' {RecordMapping As 0}} true
            else false
            end
         end
      end
   end

   local
      fun {DoTuple N R M}
         if N>0 then M.N#R.N|{DoTuple N-1 R M}
         else nil
         end
      end
      fun {DoRecord As R M}
         case As of nil then nil
         [] A|Ar then M.A#R.A|{DoRecord Ar R M}
         end
      end
      fun {DoList Fs M}
         case Fs of nil then nil
         [] F|Fr then M.F|{DoList Fr M}
         end
      end
   in
      fun {MapRecord R M}
         {L2R '#' if {IsTuple R} then {DoTuple {Width R} R M}
                  else {DoRecord {Arity R} R M}
                  end}
      end
      fun {MapVectors VV M}
         {Map {VectorToList VV} fun {$ V}
                                   {DoList {VectorToList V} M}
                                end}
      end
   end


   fun {ListsToTuples Ts}
      {VectorToTuple {Map Ts VectorToTuple}}
   end


define


   %% Force linking of finite domain module
   {Wait FD.bool}


   %% Serialization propagators for unary resources
   local
      fun {NewSerializer Propagator}
         proc {$ Tasks Start Dur}
            M TasksM StartM DurM
         in
            if {GetMapping Start ?M} then
               TasksM = {MapVectors Tasks M}
               StartM = {MapRecord Start M}
               DurM   = {MapRecord Dur M}
            else
               TasksM = Tasks
               StartM = Start
               DurM   = Dur
            end
            {Propagator TasksM StartM DurM}
         end
      end
   in
      Serialized     = {NewSerializer SchedCpIterate}
      SerializedDisj = {NewSerializer SchedDisjunctive}
      TaskIntervals  = {NewSerializer SchedTaskIntervals}
   end


   %% Propagators for cumulative scheduling
   local
      proc {MapCum Tasks Start Dur Use ?TasksM ?StartM ?DurM ?UseM}
         M
      in
         if {GetMapping Start ?M} then
            TasksM = {MapVectors Tasks M}
            StartM = {MapRecord Start M}
            DurM   = {MapRecord Dur M}
            UseM   = {MapRecord Use M}
         else
            TasksM = Tasks
            StartM = Start
            DurM   = Dur
            UseM   = Use
         end
      end
   in
      proc {Cumulative Tasks Start Dur Use Cap}
         TasksM StartM DurM UseM
      in
         {MapCum Tasks Start Dur Use ?TasksM ?StartM ?DurM ?UseM}
         {SchedCpIterateCap TasksM StartM DurM UseM Cap 0}
      end
      proc {CumulativeEF Tasks Start Dur Use Cap}
         TasksM StartM DurM UseM
      in
         {MapCum Tasks Start Dur Use ?TasksM ?StartM ?DurM ?UseM}
         {SchedCpIterateCap TasksM StartM DurM UseM Cap 1}
      end
      proc {CumulativeTI Tasks Start Dur Use Cap}
         TasksM StartM DurM UseM
      in
         {MapCum Tasks Start Dur Use ?TasksM ?StartM ?DurM ?UseM}
         {SchedCumulativeTI TasksM StartM DurM UseM Cap}
      end
      proc {CumulativeUp Tasks Start Dur Use Cap}
         TasksM StartM DurM UseM
      in
         {MapCum Tasks Start Dur Use ?TasksM ?StartM ?DurM ?UseM}
         {SchedCpIterateCapUp TasksM StartM DurM UseM Cap}
      end
   end


   %% Distribution

   local
      proc {Check Tasks Start Dur}
         if {All Tasks fun {$ Ts}
                          {All Ts fun {$ T}
                                     {HasFeature Start T} andthen
                                     {HasFeature Dur T}
                                  end}
                       end}
         then skip else
            {Exception.raiseError
             schedule('Check'
                      [Tasks Start Dur]
                      'vector(vector)'
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


      proc {EnumTI ETTuple Start Dur OldOut Stream}
         {Space.waitStable}
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
            {Space.waitStable}
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
            {Space.waitStable}
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

      fun {NewDist Dist Enum Flag}
         proc {$ Tasks Start Dur}
            Stream M TasksM StartM DurM
            TaskLists TaskTuples
         in
            if {GetMapping Start ?M} then
               TasksM = {MapVectors Tasks M}
               StartM = {MapRecord Start M}
               DurM   = {MapRecord Dur M}
            else
               TasksM = Tasks
               StartM = Start
               DurM   = Dur
            end
            TaskLists  = {VectorsToLists TasksM}
            TaskTuples = {ListsToTuples TaskLists}
            {Check TaskLists StartM DurM}
            {Dist  TaskTuples StartM DurM Stream Flag}
            {Enum  TaskTuples StartM DurM nil Stream}
         end
      end
   in
      TaskIntervalsDistO = {NewDist SchedTaskIntervalsProof EnumTI 1}
      TaskIntervalsDistP = {NewDist SchedTaskIntervalsProof EnumTI 0}
      FirstsLastsDist    = {NewDist SchedFirstsLasts EnumFL 0}
      FirstsDist         = {NewDist SchedFirstsLasts EnumFL 1}
      LastsDist          = {NewDist SchedFirstsLasts EnumFL 2}
   end


   %%
   %% Register error formatter
   %%

   {Error.registerFormatter schedule
    fun {$ E}
       T = 'error in scheduling'
    in
       case E
       of schedule(A Xs T P S) then
          %% expected Xs:list, T:atom, P:int S:virtualString
          error(kind: T
                items: (hint(l:'At argument' m:P)|
                        hint(l:'Expected type' m:T)|
                        hint(l:'In statement' m:apply(A Xs))|
                        {Append {FormatOrigin A} [line(S)]}))
       else
          error(kind: T
                items: [line(oz(E))])
       end
    end}

end
