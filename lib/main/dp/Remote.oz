%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

import
   OS(exec wait)
   Connection(offer)
   Property(get)
   Module(link)
   Error(registerFormatter)

export
   manager: ManagerProxy

prepare
   WaitDelay = 2000

define

   %%
   %% Force linking of base libraries
   %%
   {Wait Connection.offer}

   HasVirtualSite = {Property.get 'distribution.virtualsites'}

   [VirtualSite]  = if HasVirtualSite then
                       %% Now we know that there is in fact virtual site
                       %% support in our emulator, go and get it.
                       {Module.link ['x-oz://boot/VirtualSite']}
                    else
                       [unit]
                    end

   fun {ForkProcess Fork Host Ports Detach}
      Cmd       = 'ozengine'
      Func      = 'x-oz://System/RemoteServer'
      TicketArg = '--ticket='#{Connection.offer Ports}
      DetachArg = '--'#if Detach then '' else 'no' end#'detached'
      ModelArg  = '--'#if {Property.get 'perdio.minimal'} then ''
                       else 'no'
                       end#'minimal'
   in
      try
         CMD#ARGS = case Fork
                    of rsh then
                       'rsh' #
                       [Host ('exec '#Cmd#' '#Func#' '#
                              DetachArg#' '#TicketArg#' '#ModelArg)]
                    [] sh then
                       Cmd # [Func DetachArg TicketArg ModelArg]
                    [] virtual then
                       Cmd # [Func TicketArg DetachArg ModelArg
                              '--shmkey='#{VirtualSite.newMailbox}]
                    end
      in
         {OS.exec CMD ARGS {Not Detach}}
      catch E then
         {OS.wait _ _}
         raise E end
      end
   end


   class ManagerProxy
      prop locking

      feat
         Run
         Ctrl

      attr
         Run:    nil
         Ctrl:   nil
         Status: okay

      meth init(host:    HostIn  <= localhost
                fork:    ForkIn  <= automatic
                detach:  Detach  <= false
                timeout: Timeout <= {Property.get 'perdio.timeout'}
                pid:     PID     <= _)
         RunRet  RunPort  = {Port.new RunRet}
         CtrlRet CtrlPort = {Port.new CtrlRet}

         Host = {VirtualString.toAtom HostIn}
         Fork = {VirtualString.toAtom ForkIn}
         Cancel
      in
         PID={ForkProcess
              if Host==localhost then
                 if Fork==automatic then
                    if HasVirtualSite then virtual
                    else sh
                    end
                 else Fork
                 end
              else rsh
              end
              Host RunPort#CtrlPort Detach}

         thread
            {Delay Timeout}
            Cancel = unit
         end

         case {Record.waitOr RunRet#Cancel}
         of 1 then
            case {Record.waitOr CtrlRet#Cancel}
            of 1 then
               Run        <- RunRet.2
               Ctrl       <- CtrlRet.2
               self.Run    = RunRet.1
               self.Ctrl   = CtrlRet.1
            else
               {Exception.raiseError remote(cannotCreate self Host)}
            end
         else
            {Exception.raiseError remote(cannotCreate self Host)}
         end
      end

      meth SyncSend(Which What)
         OldS Answer NewS
      in
         lock
            if @Status==okay then
               OldS = (Which <- NewS)
               {Port.send self.Which What}
            else
               {Exception.raiseError remote(alreadyClosed self What)}
            end
         end
         %% might block, since OldS might be future
         Answer|NewS = OldS
         case Answer
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
         lock
            if @Status==okay then
               Status <- closed
               {Port.send self.Ctrl close}
               thread
                  {Delay WaitDelay}
                  {OS.wait _ _}
               end
            end
         end
      end

   end
   %%
   %% Register error formatter
   %%

   {Error.registerFormatter remote
    fun {$ E}
       T = 'Error: remote module manager'
    in
       case E
       of remote(alreadyClosed O M) then
          error(kind: T
                msg: 'Remote manager already closed'
                items: [hint(l:'Object application'
                             m:'{' # oz(O) # ' ' # oz(M) # '}')])
       else
          error(kind: T
                items: [line(oz(E))])
       end
    end}

end
