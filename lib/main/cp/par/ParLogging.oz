%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de/
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

import
   Statistics at 'ParStatistics.ozf'
   Property

export
   writer: LogWriter
   reader: LogReader

prepare

   fun {TaskToTree Ts Is}
      case Ts of nil then Is
      [] T|Tr then
         case T
         of commit(I) then {TaskToTree Tr I|Is}
         else {TaskToTree Tr Is}
         end
      end
   end

   proc {ArrayInc A I N}
      {Array.put A I {Array.get A I}+N}
   end

   class TaskData
      prop locking

      feat
         Tasks
         Overhead
         Nodes
         NoTasks
         Workers

      meth init(workers:WN)
         lock
            self.Tasks    = {Dictionary.new}
            self.Nodes    = {Array.new 1 WN 0}
            self.Overhead = {Array.new 1 WN 0}
            self.NoTasks  = {Array.new 1 WN 0}
            self.Workers  = WN
         end
      end

      meth PutTask(ID X)
         {Dictionary.put self.Tasks ID X}
      end

      meth GetTask(ID $)
         {Dictionary.get self.Tasks ID}
      end

      meth IncNoTask(WID)
         {ArrayInc self.NoTasks WID 1}
      end

      meth GetNoTask(WID $)
         {Array.get self.NoTasks WID}
      end

      meth AddNodes(WID N)
         {ArrayInc self.Nodes WID N}
      end

      meth GetNodes(WID $)
         {Array.get self.Nodes WID}
      end

      meth AddOverhead(WID N)
         {ArrayInc self.Overhead WID N}
      end

      meth GetOverhead(WID $)
         {Array.get self.Overhead WID}
      end

      meth start(id:ID pid:PID worker:WID start:SID)
         lock
            TaskData,PutTask(ID
                             task(id:ID pid:PID worker:WID start:SID
                                  overhead:_ nodes:_))
         end
      end

      meth stop(id:ID overhead:O nodes:N)
         lock
            TD  = TaskData,GetTask(ID $)
            WID = TD.worker
         in
            TD.overhead = O
            TD.nodes    = N
            TaskData,IncNoTask(WID)
            TaskData,AddOverhead(WID O)
            TaskData,AddNodes(WID N)
         end
      end

      meth getWorkers($)
         self.Workers
      end

      meth getTask(I $)
         lock
            TaskData,GetTask(I $)
         end
      end

      meth getNodes(WID Mode $)
         lock
            case Mode
            of avg then N=TaskData,GetNoTask(WID $) in
               if N==0 then 0 else TaskData,GetNodes(WID $) div N end
            [] total then
               TaskData,GetNodes(WID $)
            end
         end
      end

      meth getOverhead(WID Mode $)
         lock
            case Mode
            of avg then N=TaskData,GetNoTask(WID $) in
               if N==0 then 0 else TaskData,GetOverhead(WID $) div N end
            [] total then
               TaskData,GetOverhead(WID $)
            end
         end
      end

      meth taskToWorker(ID $)
         (TaskData,GetTask(ID $)).worker
      end

   end

   class LogWriter
      feat Logger
      meth init(L)
         self.Logger = L
      end
      meth log(M)
         L=self.Logger
      in
         if L\=unit then
            {L M}
         end
      end
   end

define

   class LogReader
      feat
         names
         statistics
      attr
         data
         time: 0
         used: 0

      meth init(WorkerNames)
         self.names      = WorkerNames
         self.statistics = {New Statistics.dialog init(worker:WorkerNames)}
         {self reset}
      end

      meth reset
         data <- {New TaskData init(workers:{Width self.names})}
         {self.statistics reset(@data)}
      end

      meth worker(WID What)
         case What
         of idle(nodes:N overhead:O id:ID) then
            {@data           stop(id:ID nodes:N overhead:O)}
            {self.statistics update(WID)}
         else skip
         end
      end

      meth manager(What)
         case What
         of start then
            time <- {Property.get 'time.total'}
         [] done  then
            used <- @time - {Property.get 'time.total'}
         [] steal(task:_ id:ID pid:PID worker:WID start:SID) then
            {@data start(id:ID pid:PID worker:WID start:SID)}
         else skip
         end
      end

      meth close
         {self.statistics tkClose}
      end

   end
end
