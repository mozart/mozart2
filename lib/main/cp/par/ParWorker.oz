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
%%%    http://www.mozart-oz.org/
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

import
   TraceSpace(plain best)     at 'ParTraceSpace.ozf'
   Space(new ask)

require
   Logging(writer: LogWriter) at 'ParLogging.ozf'
   Server(new)                at 'ParServer.ozf'

export
   plain: NewPlainWorker
   best:  NewBestWorker

define

   local

      fun {CanSteal Ss}
         case Ss of nil then false
         [] _|Sr then Sr\=nil
         end
      end

      fun {Steal S1|S1r ?SS}
         case S1r of nil then SS=S1 nil
         [] _|_ then S1|{Steal S1r SS}
         end
      end

   in

      class PlainWorker from LogWriter
         feat
            manager
            root
            id
         attr
            open:     nil
            overhead: unit
            nodes:    0
            task_id:  0

         meth init(logger:  L
                   manager: M
                   script:  S
                   id:      I)
            LogWriter, init(L)
            self.manager    = M
            self.root       = {New TraceSpace.plain new(S)}
            self.id         = I
         end

         meth start(task:Is id:I)
            S={self.root clone($)}
         in
            {S internalize(Is)}
            overhead <- {Length Is}
            open     <- [S]
            nodes    <- 0
            task_id  <- I
            PlainWorker, explore
         end

         meth explore
            case @open of nil then
               PlainWorker, log(worker(self.id
                                       idle(overhead: @overhead
                                            nodes:    @nodes
                                            id:       @task_id)))
               {self.manager idle(self.id)}
            [] S|Sr then
               nodes <- @nodes + 1
               case {S ask($)}
               of failed    then
                  open <- Sr
               [] succeeded then
                  {self.manager succeeded({S merge($)})}
                  open <- Sr
               [] alternatives(N) then C={S clone($)} in
                  {S commit(1)} {C commit(2#N)}
                  open <- S|C|Sr
               end
               {self.server explore}
            end
         end

         meth steal(?Stolen)
            if {CanSteal @open} then
               S
            in
               open <- {Steal @open ?S}
               Stolen = yes(task:{S externalize($)} id:@task_id
                            start:@nodes+@overhead)
            else Stolen=no
            end
         end

         meth stop
            PlainWorker, log(worker(self.id
                                    stop(overhead: @overhead
                                         nodes:    @nodes
                                         id:       @task_id)))
            open <- nil
         end
      end
   end

   local
      fun {CanSteal Ss}
         case Ss of nil then false
         [] _|Sr then Sr\=nil
         end
      end

      fun {CanStealBest Fs Bs}
         case Bs of nil then {CanSteal Fs}
         [] _|Br then Br\=nil orelse Fs\=nil
         end
      end

      fun {Steal S1|S1r ?SS}
         case S1r of nil then SS=S1 nil
         [] _|_ then S1|{Steal S1r SS}
         end
      end
   in

      class BestWorker from LogWriter
         feat
            manager
            order
            root
            id
         attr
            fore:     nil
            back:     nil
            best:     unit
            overhead: unit
            nodes:    0
            task_id:  0

         meth init(manager:M script:S order:O logger:L id:I)
            LogWriter, init(L)
            self.manager    = M
            self.root       = {New TraceSpace.best new(S O)}
            self.order      = O
            self.id         = I
            fore <- nil
            back <- nil
            best <- unit
         end

         meth IsBetter(S1 S2 $)
            %% Returns true, iff S2 is better than S1
            if S1==unit then true else
               TS={Space.new proc {$ _}
                                {self.order S1 S2}
                             end}
            in
               if {Space.ask TS}==failed then false else true end
            end
         end

         meth constrain(S)
            if BestWorker,IsBetter(@best S $) then
               back <- {Append @fore @back}
               fore <- nil
               best <- S
            end
         end

         meth start(task:Is id:I)
            S={self.root clone($)}
         in
            {S internalize(Is)}
            overhead <- {Length Is}
            fore     <- [S]
            back     <- nil
            nodes    <- 0
            task_id  <- I
            BestWorker, log(worker(self.id start(id:I)))
            BestWorker, explore
         end

         meth explore
            case @fore of nil then
               case @back of nil then
                  BestWorker, log(worker(self.id
                                         idle(overhead: @overhead
                                              nodes:    @nodes
                                              id:       @task_id)))
                  {self.manager idle(self.id)}
               [] S|Sr then
                  back <- Sr
                  fore <- [S]
                  {S constrain(@best)}
                  {self.server explore}
               end
            [] S|Sr then
               nodes <- @nodes + 1
               case {S ask($)}
               of failed    then
                  fore <- Sr
               [] succeeded then Sol={S merge($)} in
                  {self.manager collect(Sol)}
                  back <- {Append Sr @back}
                  fore <- nil
                  best <- Sol
               [] alternatives(N) then C={S clone($)} in
                  {S commit(1)} {C commit(2#N)}
                  fore <- S|C|Sr
               end
               {self.server explore}
            end
         end

         meth steal($)
            if {CanStealBest @fore @back} then S in
               if @back==nil then
                  %% Steal from foreground stack
                  fore <- {Steal @fore ?S}
               else
                  %% Steal from background stack
                  back <- {Steal @back ?S}
                  {S constrain(@best)}
               end
               yes(task:{S externalize($)} id:@task_id
                   start:@nodes+@overhead)
            else
               no
            end
         end

         meth stop
            BestWorker, log(worker(self.id
                                   stop(overhead: @overhead
                                        nodes:    @nodes
                                        id:       @task_id)))
            fore <- nil
            back <- nil
         end
      end

   end

   fun {NewPlainWorker M}
      {Server.new PlainWorker M}
   end

   fun {NewBestWorker M}
      {Server.new BestWorker M}
   end

end
