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
   OS(exec wait)
   Connection(offer)
   Property(get)
   Module(link)
   Error(formatGeneric format dispatch)
   ErrorRegistry(put)


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

   HOME = {Property.get 'oz.home'}

   proc {ForkProcess Fork Home Host Ports Detach}
      Cmd       = Home#'/bin/ozengine'
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
         {OS.exec CMD ARGS {Not Detach} _}
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

      meth init(host:   HostIn <= localhost
                fork:   ForkIn <= automatic
                detach: Detach <= false
                home:   Home   <= HOME)
         RunRet  RunPort  = {Port.new RunRet}
         CtrlRet CtrlPort = {Port.new CtrlRet}

         Host = {VirtualString.toAtom HostIn}
         Fork = {VirtualString.toAtom ForkIn}

      in
         {ForkProcess
          if Host==localhost then
             if Fork==automatic then
                if HasVirtualSite then virtual
                else sh
                end
             else Fork
             end
          else rsh
          end
          Home Host RunPort#CtrlPort Detach}

         Run        <- RunRet.2
         Ctrl       <- CtrlRet.2
         self.Run    = RunRet.1
         self.Ctrl   = CtrlRet.1
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

   {ErrorRegistry.put remote
    fun {$ Exc}
       E = {Error.dispatch Exc}
       T = 'Error: remote module manager'
    in
       case E
       of remote(alreadyClosed O M) then
          {Error.format T
           'Remote manager already closed'
           [hint(l:'Object application' m:'{' # oz(O) # ' ' # oz(M) # '}')]
           Exc}
       else
          {Error.formatGeneric T Exc}
       end
    end}

end
