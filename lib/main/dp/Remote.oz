%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
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

functor $ prop once

import
   OS.{getEnv}
   Open.{pipe}
   Connection.{offer}
   System.{showInfo}

export
   server: ComputeClient
   farm:   Farm

body

   Farm = unit

   proc {SuckUp P}
      S={P read(list:$)}
   in
      case S==nil then skip else
         {System.showInfo S} {SuckUp P}
      end
   end

   proc {StartRemote Host Cmd}
      try
         P={New Open.pipe init(cmd:'rsh'
                               args: [Host Cmd])}
      in
         thread {SuckUp P} end
      catch _ then
         raise error end
      end
   end

   class ComputeClient
      prop
         locking
      feat
         Run
         Ctrl
         Host
      attr
         Run:  nil
         Ctrl: nil

      meth init(H)
         RunRet  RunPort ={Port.new RunRet}
         CtrlRet CtrlPort={Port.new CtrlRet}
         Ticket={Connection.offer RunPort#CtrlPort}
      in
         self.Host = H
         {StartRemote H
          {OS.getEnv 'OZHOME'}#'/bin/ozserver --ticket='#Ticket}
         Run      <- RunRet.2
         Ctrl     <- CtrlRet.2
         self.Run  = RunRet.1
         self.Ctrl = CtrlRet.1
      end

      meth getHost($)
         self.Host
      end

      meth AsyncSend(Which What ?Ret)
         OldS NewS
      in
         lock
            OldS = (Which <- NewS)
            {Port.send self.Which What}
         end
         Ret|NewS = OldS
      end

      meth Send(Which What $)
         case {self AsyncSend(Which What $)}
         of okay(A)      then A
         [] exception(E) then
            raise E end
         [] failed       then
            raise error(dp('export' exceptionNogoods self)) end
         end
      end

      %% Run methods
      meth run(P $)
         ComputeClient,Send(Run P $)
      end

      %% Ctrl methods
      meth ping($)
         ComputeClient,Send(Ctrl ping $)
      end

      meth close
         ComputeClient,AsyncSend(Ctrl close _)
      end
   end

end
