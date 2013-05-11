%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%   Konstantin Popov <kost@sics.se>
%%%
%%% Contributors:
%%%   Andreas Franke <afranke@ags.uni-sb.de>
%%%   Raphael Collet (raphael.collet@uclouvain.be)
%%%
%%% Copyright:
%%%   Kostantin Popov, 1998
%%%   Christian Schulte, 1997--2000
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
   OS(exec wait getEnv)
   Connection(offer)
   Property(get condGet put)
   Module(link)
   Error(registerFormatter)
   DP(getFaultStream)

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

   [VirtualSite
\ifdef DENYS_EVENTS
    VirtualSiteAux
\endif
   ]  = if HasVirtualSite then
           %% Now we know that there is in fact virtual site
           %% support in our emulator, go and get it.
           {Module.link ['x-oz://boot/VirtualSite'
\ifdef DENYS_EVENTS
                         'x-oz://system/VirtualSite'
\endif
                        ]}
        else
           [unit
\ifdef DENYS_EVENTS
            unit
\endif
           ]
        end

   if {Property.condGet 'oz.engine' unit}==unit then
      {Property.put 'oz.engine'
       case {OS.getEnv 'OZ_ENGINE'} of false then
          case {OS.getEnv 'OZENGINE'} of false then 'ozengine'
          elseof X then X end
       elseof X then X end}
   else skip end

   if {Property.condGet 'oz.remote.fork' unit}==unit then
      {Property.put 'oz.remote.fork'
       case {OS.getEnv 'OZ_REMOTE_FORK'} of false then
          case {OS.getEnv 'OZREMOTEFORK'} of false then 'rsh'
          elseof X then X end
       elseof X then X end}
   else skip end

   fun {ForkProcess Fork Host Ports Detach PORT IP FW}
      Cmd       = {Property.get 'oz.engine'}
      Func      = 'x-oz://system/RemoteServer'
      TicketArg = '--ticket='#{Connection.offer Ports}
      DetachArg = '--'#if Detach then '' else 'no' end#'detached'
      PortArg   = '--port='#if PORT==default then 0 else PORT end
      IPArg     = '--ip='#if IP==default then default else
                             {VirtualString.toAtom IP} end
      FWArg     = if FW then '--firewall' else '' end
   in
      try
         CMD#ARGS = case Fork
                    of sh then
                       Cmd # [Func DetachArg TicketArg PortArg IPArg FWArg]
                    [] virtual then Key={VirtualSite.newMailbox} in
\ifdef DENYS_EVENTS
                       %% start VS threads
                       {Wait VirtualSiteAux}
\endif
                       Cmd # [Func TicketArg DetachArg PortArg IPArg FWArg
                              '--shmkey='#Key]
                    else
                       Fork #
                       [Host ('exec '#Cmd#' '#Func#' '#
                              DetachArg#' '#TicketArg#' '#
                              ' '#PortArg#' '#IPArg#' '#FWArg)]
                    end
      in
         {OS.exec CMD ARGS {Not Detach}}
      catch E then
         {OS.wait _ _}
         raise E end
      end
   end

   %% returns X whenever entity P is permFail, _ otherwise
   fun {WhenFailed P X}
      if {Member permFail {DP.getFaultStream P}} then X else _ end
   end

   class ManagerProxy
      prop locking

      feat
         Run
         Ctrl
         ProxyFailed

      attr
         Run:    nil
         Ctrl:   nil
         Status: okay

      meth init(host:    HostIn  <= localhost
                fork:    ForkIn  <= automatic
                detach:  Detach  <= false
                timeout: Timeout <= {Property.get 'dp.probeTimeout'}
                pid:     PID     <= _
                port:    PORT    <= default
                ip:      IP      <= default
                firewall:FW      <= false)
         RunRet  RunPort  = {Port.new RunRet}
         CtrlRet CtrlPort = {Port.new CtrlRet}

         Host = {VirtualString.toAtom HostIn}
         Fork = {VirtualString.toAtom ForkIn}
         Cancel
      in
         PID={ForkProcess
              local OFork =
                 case Fork
                 of automatic then
                    if Host==localhost then
                       if HasVirtualSite then virtual
                       else sh
                       end
                    else {Property.condGet 'oz.remote.fork' rsh}
                    end
                 [] sh then sh
                 else Fork
                 end
              in
                 OFork
              end
              Host RunPort#CtrlPort Detach PORT IP FW}

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
               %% bind self.ProxyFailed whenever self.Run or self.Ctrl fails
               thread self.ProxyFailed={WhenFailed self.Run failed} end
               thread self.ProxyFailed={WhenFailed self.Ctrl failed} end
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
         %% The operation might fail if the proxy has failed
         case {Record.waitOr OldS#self.ProxyFailed} of
            2 then
            {Exception.raiseError remote(crashed self What)}
         elseof 1 then
            Answer|NewS = OldS
            case Answer
            of okay         then skip
            [] exception(E) then
               raise E end
            [] failed       then
               raise error(dp('export' exceptionNogoods self)) end
            end
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
