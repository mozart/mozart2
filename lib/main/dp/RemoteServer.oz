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
   Connection % Do not request!

   Application(exit getCmdArgs)
   Module(manager)
   System(showError)
   Fault
   Property(put)
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
                    minimal(single type:bool)
                    test(single type:bool default:false))


define

   %% Get the arguments
   Args = {Application.getCmdArgs ArgSpec}

   if Args.test then
      {System.showError 'Remote: Test succeeded...'}
      {Application.exit 0}
   end

   %% Set the appropriate distribution model
   {Property.put 'perdio.minimal' Args.minimal}

   %%
   %% Force linking of base libraries
   %%
   {Wait Connection}

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

   RunRet CtrlRet
   RunStr CtrlStr

   try
      RunRet # CtrlRet = {Connection.take Args.ticket}
      {Port.send RunRet  {Port.new RunStr}}
      {Port.send CtrlRet {Port.new CtrlStr}}
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
      {Fault.installWatcher RunRet [permFail]
       proc {$ E C}
          {System.showError 'RemoteServer: client crashed.'}
          {Application.exit ExitErrorClient}
       end
       true}
   end

   %% The module manager server
   thread
      {ForAll RunStr
       proc {$ What}
          try
             try
                {ModMan What}
             in
                {Port.send RunRet okay}
             catch E then
                {Port.send RunRet exception({Record.subtract E debug})}
             end
          catch _ then
             {Port.send RunRet failed}
          end
       end}
   end

   %% The server for control messages
   thread
      {ForAll CtrlStr
       proc {$ C}
          case C
          of ping  then {Port.send CtrlRet okay}
          [] close then {Application.exit ExitDone}
          end
       end}
   end

end
