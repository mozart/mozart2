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

require
   Server  at 'ParServer.ozf'

import
   Process at 'ParProcess.ozf'
   Logging at 'x-oz://system/ParLogging.ozf'
   Manager at 'ParManager.ozf'

export
   Engine

define

   fun {UnRoll N X Xr}
      if N>0 then X|{UnRoll N-1 X Xr} else Xr end
   end

   class Engine
      feat
         Hosts
         Names
      attr
         Trace:      false
         CurManager: unit
         CurLogger:  unit
      prop
         locking
      meth init(...) = M
         lock
            Spec = {List.toTuple '#'
                    {Record.foldRInd M
                     fun {$ F X Ps}
                        H#N#M = if {IsInt F} then
                                   X#1#automatic
                                else
                                   if {IsInt X}  then
                                      F#X#automatic
                                   elseif {IsAtom X} then
                                      F#1#X
                                   else
                                      F#X.1#X.2
                                   end
                                end
                     in
                        {UnRoll N H#M Ps}
                     end nil}}
         in
            self.Hosts = {Record.mapInd Spec
                          fun {$ I H#M}
                             {New Process.worker init(name:H fork:M id:I)}
                          end}
            self.Names = {Record.map Spec fun {$ H#_} H end}
         end
      end
      meth trace(OnOff <= unit)
         lock
            if OnOff==unit then
               Trace <- {Not @Trace}
            else
               Trace <- OnOff
            end
            if {Not @Trace} andthen @CurLogger\=unit then
               {@CurLogger close}
               CurLogger <- unit
            end
         end
      end
      meth GetLogger($)
         if @Trace then
            if @CurLogger==unit then
               CurLogger <- {Server.new Logging.reader init(self.Names)}
            else
               {@CurLogger reset}
            end
            @CurLogger
         else
            unit
         end
      end
      meth one(SF ?Ss)
         lock
            CurManager <- M
            L={self GetLogger($)}
            M={Server.new Manager.one
               init(logger: L
                    worker: {Record.map self.Hosts fun {$ H}
                                                      {H plain(manager: M
                                                               logger:  L
                                                               script:  SF $)}
                                                   end})}
         in
            {M start} {M get(?Ss)} {Wait {M sync($)}}
            CurManager <- unit
         end
      end
      meth all(SF ?Ss)
         lock
            CurManager <- M
            L={self GetLogger($)}
            M={Server.new Manager.all
               init(logger: L
                    worker: {Record.map self.Hosts fun {$ H}
                                                      {H plain(manager: M
                                                               logger:  L
                                                               script:  SF $)}
                                                   end})}
         in
            {M start} {M get(?Ss)} {Wait {M sync($)}}
            CurManager <- unit
         end
      end
      meth best(SF ?Ss)
         lock
            CurManager <- M
            L={self GetLogger($)}
            M={Server.new Manager.best
               init(logger: L
                    worker: {Record.map self.Hosts fun {$ H}
                                                      {H best(manager: M
                                                              logger:  L
                                                              script:  SF $)}
                                                   end})}
         in
            {M start} {M get(?Ss)} {Wait {M sync($)}}
            CurManager <- unit
         end
      end
      meth stop
         M=@CurManager
      in
         if M\=unit then
            {M stop}
         end
      end
      meth close
         Engine,stop
         lock
            {Record.forAll self.Hosts proc {$ H} {H close} end}
         end
      end
   end
end
