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
   Server  at 'ParServer.ozf'

import
   Process at 'ParProcess.ozf'
   Logging at 'ParLogging.ozf'
   Manager at 'ParManager.ozf'

export
   Engine

define

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
            NameDict = {Dictionary.new}
            ProcDict = {Dictionary.new}
         in
            {Record.forAllInd M
             proc {$ F X}
                H#N = if {IsInt F} then X#1 else F#X end
             in
                {Dictionary.put NameDict H N+{Dictionary.condGet NameDict H 0}}
             end}
            {FoldL {Dictionary.keys NameDict}
             fun {$ N K}
                M = {Dictionary.get NameDict K}+N
             in
                {For N M-1 1
                 proc {$ I}
                    {Dictionary.put ProcDict I
                     {New Process.worker init(name:K id:I)}}
                 end}
                M
             end 1 _}
            self.Hosts = {Dictionary.toRecord hosts ProcDict}
            self.Names = {Record.map self.Hosts fun {$ H} H.name end}
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
