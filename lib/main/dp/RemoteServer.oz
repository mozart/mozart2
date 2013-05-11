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
   Connection % Do not request!
   Application(exit getCmdArgs)
   Module(manager)
   System(showError gcDo)
   DP(initWith getFaultStream)
   Property(get put)
   OS(signal)
   Error(printException)

prepare
   ExitDone        = 0
   ExitErrorInit   = 1
   ExitErrorTicket = 2
   ExitErrorClient = 3

   ArgSpec = record(ticket(single type:atom)
                    shmkey(single type:atom default:'NONE')
                    detached(single type:bool default:false)
                    test(single type:bool default:false)
                    port(single type:int default:0)
                    ip(single type:atom default:default)
                    firewall(single type:bool default:false))

define

   %% Get the arguments
   Args = {Application.getCmdArgs ArgSpec}

   if Args.test then
      {System.showError 'Remote: Test succeeded...'}
      {Application.exit 0}
   end

   %% Initialize distribution with desired settings before Connection.take
   local
      S1 = if Args.ip\=default then [ip#exact(Args.ip)] else nil end
      S2 = if Args.port\=0 then [port#exact(Args.port)] else nil end
      S3 = [firewall#Args.firewall]
      Settings = {AdjoinList settings {Flatten [S1 S2 S3]}}
   in
      {DP.initWith Settings}
   end

   %% Module manager needed for
   ModMan = {New Module.manager init}

   if Args.shmkey\='NONE' then

      %% Link it via the module manager, since only now we know
      %% that the emulator has support for virtual sites indeed.

      VirtualSite = {ModMan link(name:'x-oz://boot/VirtualSite' $)}
   in

      try
         %% First initialize the virtual site, so that the
         %% ticket-based connection following it uses the
         %% virtual site communication mechanism.
         {VirtualSite.initServer Args.shmkey}
\ifdef DENYS_EVENTS
         %% start VS threads
         {ModMan link(name:'x-oz://system/VirtualSite')}
\endif
      catch _ then
         {System.showError 'Virtual Site: failed to initialize'}
         {Application.exit ExitErrorInit}
      end

   end
   RunRet = {NewCell _}
   CtrlRet = {NewCell _}
   RunStr
   CtrlStr

   try
      {Access RunRet} # {Access CtrlRet} = {Connection.take Args.ticket}
      {Port.send {Access RunRet}  {Port.new RunStr}}
      {Port.send {Access CtrlRet} {Port.new CtrlStr}}
   catch Ex then
      {System.showError 'Remote Server: failed to take a ticket'}
      {Error.printException Ex}
      {Application.exit ExitErrorTicket}
   end

   %% If we are detached, terminate when our client runs into trouble.
   %% This is the case, if one of the ports is found to refer to a dead
   %% site

   if Args.detached then
      {OS.signal 'SIGHUP'  ignore}
      {OS.signal 'SIGTERM' ignore}
   else
      thread
         if {Member permFail {DP.getFaultStream {Access RunRet}}} then
            {System.showError 'RemoteServer: client crashed.'}
            {Application.exit ExitErrorClient}
         end
       end
   end

   %% The module manager server
   thread
      {ForAll RunStr
       proc {$ What}
          try
             try
                {ModMan What}
             in
                {Port.send {Access RunRet} okay}
             catch E then
                {Port.send {Access RunRet} exception({Record.subtract E debug})}
             end
          catch _ then
             {Port.send {Access RunRet} failed}
          end
       end}
   end

   %% The server for control messages
   thread
      {ForAll CtrlStr
       proc {$ C}
          case C
          of ping  then {Port.send {Access CtrlRet} okay}
          [] close then
             %% No more applies
             %% Can be used concurently by the
             %% module manager server
             {Assign RunRet {NewPort _}}
             {Assign CtrlRet unit}
             {System.gcDo}
             {Application.exit ExitDone}
          end
       end}
   end

end
