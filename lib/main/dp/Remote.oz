%%%
%%% Authors:
%%%   Christian Schulte <schulte@dfki.de>
%%%   Konstantin Popov <kost@sics.se>
%%%
%%% Copyright:
%%%   Christian Schulte, 1997, 1998
%%%   Kostantin Popov, 1998
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

import
   Open(pipe)
   OS(getEnv)
   System(showInfo)
   Connection(offer)
   Property(get)
   Module(manager)

export
   manager: ManagerProxy

define

   %%
   %% Force linking of base libraries
   %%
   {Wait Connection.offer}

   HasVirtualSite = {Property.get 'distribution.virtualsites'}

   VirtualSite = if HasVirtualSite then
                    %% Now we know that there is in fact virtual site
                    %% support in our emulator, go and get it.
                    {{New Module.manager init}
                     link(name: 'x-oz://boot/VirtualSite' $)}
                 else
                    unit
                 end

   local
      proc {SuckUp Pipe}
         S={Pipe read(list:$)}
      in
         if S\=nil then
            {System.showInfo S} {SuckUp Pipe}
         end
      end
   in
      fun {CreatePipe Fork Host Ports Detach}
         HOME      = {OS.getEnv 'OZHOME'}
         Cmd       = HOME#'/bin/ozengine'
         Func      = HOME#'/share/RemoteServer.ozf'
         TicketArg = '--ticket='#{Connection.offer Ports}
         DetachArg = '--'#if Detach then '' else 'no' end#'detached'
         ModelArg  = '--'#if {Property.get 'perdio.minimal'} then ''
                          else 'no'
                          end#'minimal'
      in
         try
            Pipe = {New Open.pipe
                    case Fork
                    of rsh then
                       init(cmd:  'rsh'
                            args: [Host
                                   ('exec '#Cmd#' '#Func#' '#
                                    DetachArg#' '#TicketArg#' '#ModelArg)])
                    [] virtual then
                       init(cmd:  Cmd
                            args: [Func
                                   TicketArg
                                   DetachArg
                                   ModelArg
                                   '--shmkey='#{VirtualSite.newMailbox}])
                    end}
         in
            thread {SuckUp Pipe} end
            Pipe
         catch E then
            raise error(E) end
         end
      end
   end


   class ManagerProxy
      prop locking

      feat
         Run
         Ctrl
         Pipe

      attr
         Run:  nil
         Ctrl: nil

      meth init(host:   HostIn <= localhost
                fork:   ForkIn <= automatic
                detach: Detach <= false)

         RunRet  RunPort  = {Port.new RunRet}
         CtrlRet CtrlPort = {Port.new CtrlRet}

         Host = {VirtualString.toAtom HostIn}
         Fork = {VirtualString.toAtom ForkIn}
      in
         self.Pipe = {CreatePipe
                      if
                         Host==localhost andthen
                         Fork==automatic andthen
                         HasVirtualSite
                      then virtual
                      else rsh
                      end
                      Host RunPort#CtrlPort Detach}

         Run      <- RunRet.2
         Ctrl     <- CtrlRet.2
         self.Run  = RunRet.1
         self.Ctrl = CtrlRet.1
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

      meth SyncSend(Which What)
         case {self AsyncSend(Which What $)}
         of okay         then skip
         [] exception(E) then
            raise E end
         [] failed       then
            raise error(dp('export' exceptionNogoods self)) end
         end
      end

      %% Manager methods
      meth link(...) = Message
         ManagerProxy,SyncSend(Run Message)
      end

      meth apply(...) = Message
         ManagerProxy,SyncSend(Run Message)
      end

      meth enter(...) = Message
         ManagerProxy,SyncSend(Run Message)
      end

      %% Ctrl methods
      meth ping
         ManagerProxy,SyncSend(Ctrl ping)
      end

      meth close
         ManagerProxy,AsyncSend(Ctrl close _)
         {self.Pipe close}
      end

   end


end
