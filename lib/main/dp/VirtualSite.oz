%%%
%%% Authors:
%%%   Konstantin Popov (kost@sics.se)
%%%
%%% Credits:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Konstantin Popov, 1998
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

%%
local
   %%
   local BINewVSMailbox = {`Builtin` 'VirtualSite.newMailbox' 1} in
      fun {NewVSMailbox}
         {BINewVSMailbox}
      end
   end

   %%
   %% 'P' is a pipe to be printed out;
   proc {ShowPipe P}
      S = {P read(list: $)}
   in
      case S == nil then skip else
         {System.showInfo S} {ShowPipe P}
      end
   end

   %%
   proc {StartVSServer Cmd}
      try
         P = {New Open.pipe init(cmd:'sh' args:[Cmd])}
      in thread {ShowPipe P} end
      catch _ then raise error end
      end
   end

   %%
   class VirtualSiteObject
      prop
         locking
      %%
      feat
         VSMailbox
         TaskPort
         CtrlPort

      %%
      meth init(H)
         Ticket = {Connection.offer vsserver(taskPort: self.TaskPort
                                             ctrlPort: self.CtrlPort)}
      in
         self.VSMailbox = {NewVSMailbox}
         {StartVSServer {OS.getEnv 'OZHOME'}#'/bin/ozvsserver'#
          ' --shmid='#self.VSMailbox#
          ' --ticket='#Ticket}
         {Wait self.TaskPort}
         {Wait self.CtrlPort}
      end

      %%
      meth inject(P)
         {Port.send self.TaskPort P}
      end

      %%
      meth ping($)
         {Port.send self.CtrlPort spec(ping($))}
      end

      %%
      %% Closing a virtual site means it will stop its operatioin in
      %% some future. It does NOT mean 'close' is the last processed
      %% message;
      meth close
         {Port.send self.CtrlPort spec(close)}
      end
   end

   %%
in
   VirtualSite = vs(server: VirtualSiteObject)
end
