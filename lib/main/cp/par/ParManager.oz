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

require
   ParLogging(writer: LogWriter)

export
   one:  OneManager
   all:  AllManager
   best: BestManager

prepare

   local
      DelayNoneFound = 100

      fun {FindWork Bs W}
         case Bs of nil then no
         [] B|Br then A={W.B steal($)} in
            case {Label A}
            of yes then A
            [] no  then {FindWork Br W}
            end
         end
      end

   in

      class Manager from LogWriter
         feat
            done
         attr
            busy:       nil
            workers:    '#'
            no_workers: 0
            task_id:    0
            is_done:    false

         meth init(logger:L worker:W)
            LogWriter, init(L)
            busy       <- nil
            workers    <- W
            no_workers <- {Width W}
            task_id    <- 0
            is_done    <- false
         end

         meth sync($)
            self.done
         end

         meth getTaskId(?I)
            I=@task_id task_id <- I+1
         end

         meth start
            ID = Manager,getTaskId($)
         in
            busy <- [1]
            Manager, log(manager(start))
            Manager, log(manager(steal(task:nil id:ID pid:~1
                                       worker:1 start:0)))
            {@workers.1 start(task:nil id:ID)}
            {For 2 @no_workers 1 proc {$ I}
                                    {self.server idle(I)}
                                 end}
         end

         meth broadcast(M)
            {Record.forAll @workers proc {$ W}
                                       {W M}
                                    end}
         end

         meth idle(WID)
            busy <- {List.subtract @busy WID}
            case @busy of nil then
               if @is_done then skip else
                  is_done   <- true
                  self.done = unit
                  {self done}
               end
            elseof Bs then
               case {FindWork Bs @workers}
               of no then
                  %% Sleep and start again
                  thread
                     {Delay DelayNoneFound}
                     {self.server idle(WID)}
                  end
               [] yes(task:Task id:PID start:SID) then
                  ID=Manager,getTaskId($)
               in
                  %% This guy is busy now
                  busy <- {Append Bs [WID]}
                  %% Give him the work
                  Manager,log(manager(steal(task:Task id:ID pid:PID
                                            worker:WID start:SID)))
                  {@workers.WID start(task:Task id:ID)}
               end
            end
         end

         meth done
            Manager, log(manager(done))
         end

         meth stop
            Manager, log(manager(done))
            {ForAll busy <- nil proc {$ WID}
                                   {@workers.WID stop}
                                end}
         end

      end

   end


   class OneManager from Manager
      attr sol: nil
      meth init(logger:L worker:Ws)
         Manager, init(logger:L worker:Ws)
         sol <- _
      end
      meth succeeded(S)
         if {IsDet @sol} then skip else
            [S] = @sol
            Manager, stop
         end
      end
      meth get($)
         @sol
      end
      meth done
         Manager,done
         if {IsDet @sol} then skip else
            @sol=nil
         end
      end
   end

   class AllManager from Manager
      attr
         sol_head: nil
         sol_tail: nil
      meth init(logger:L worker:Ws)
         Ss
      in
         Manager, init(logger:L worker:Ws)
         sol_head <- Ss
         sol_tail <- Ss
      end
      meth done
         Manager, done
         @sol_tail = nil
      end
      meth succeeded(S)
         Ss in S|Ss = (sol_tail <- Ss)
      end
      meth get($)
         @sol_head
      end
   end

   class BestManager from Manager
      attr
         sol_head: nil
         sol_tail: nil
         sol_best: unit
      meth init(logger:L worker:Ws)
         Ss
      in
         Manager, init(logger:L worker:Ws)
         sol_head <- Ss
         sol_tail <- Ss
         sol_best <- unit
      end
      meth done
         Manager, done
         @sol_tail = nil
      end
      meth constrain(?S A)
         S = @sol_best
         if A\=unit then Ss in
            sol_best <- A
            Manager,broadcast(constrain(A))
            A|Ss = (sol_tail <- Ss)
         end
      end
      meth get($)
         @sol_head
      end
   end

end
