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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local

   \insert 'RemoteServer.oz'

   \insert 'MakeAllLoader.oz'

   IMPORT_ALL = {MakeAllLoader {Adjoin IMPORT full}}

   proc {StartRemote Host Cmd}
      try
         0={OS.system 'rsh '#Host#' '#Cmd#' '#[&&]}
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
      attr
         Run:  nil
         Ctrl: nil

      meth init(Host)
         RunRet  RunPort ={Port.new RunRet}
         CtrlRet CtrlPort={Port.new CtrlRet}
         Show = {`Builtin` 'Show' 1}
      in
         case {VirtualString.toAtom Host}==samehost then
            {RemoteServer RunRet CtrlRet
             IMPORT_ALL
             proc {$} skip end}
         else
            Ticket={Connection.offer RunPort#CtrlPort}
         in
            {StartRemote Host
             {OS.getEnv 'OZHOME'}#'/bin/ozserver --ticket='#Ticket}
            {Show started(RunRet CtrlRet)}
         end
         Run      <- RunRet.2
         {Show run}
         Ctrl     <- CtrlRet.2
         {Show ctrl}
         self.Run  = RunRet.1
         self.Ctrl = CtrlRet.1
      end

      meth Send(Which What $)
         OldS NewS Ret
      in
         lock
            OldS = (Which <- NewS)
            {Port.send self.Which What}
         end
         {Wait OldS}
         Ret|NewS = OldS
         case Ret
         of okay(A)      then A
         [] exception(E) then raise E end
         end
      end

      %% Run methods
      meth run(P $)
         ComputeClient,Send(Run P $)
      end

      %% Ctrl methods
      meth ping($)
         ComputeClient,Send(Ctrl ping  $)
      end
      meth close
         ComputeClient,Send(Ctrl close _)
      end
   end

in

   Remote = remote(server: ComputeClient
                   farm:   unit)

end
