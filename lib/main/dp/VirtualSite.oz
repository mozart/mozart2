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
functor $ prop once
   %%
import
   System.{showInfo}
   Open.{pipe}
   Connection.{offer}
   OS.{getEnv}

export
   server: VirtualSiteObject

   %%
body
   %%
   local BINewVSMailbox = {`Builtin` 'VirtualSite.newMailbox' 1} in
      fun {NewVSMailbox}
         {BINewVSMailbox}
      end
   end

   %%
   %% 'P' is a pipe to be printed out;
   proc {ShowPipe P Closed}
      S = {P read(list: $)}
   in
      case {IsDet Closed} orelse S == nil then skip else
         {System.showInfo S} {ShowPipe P Closed}
      end
   end

   %%
   class VirtualSiteObject
      prop
         locking
      %%
      feat
         PipeObj
         ClosedFlag
      %%
         VSMailbox
         TaskPort
         CtrlPort

      %%
      meth init
         Ticket = {Connection.offer vsserver(taskPort: self.TaskPort
                                             ctrlPort: self.CtrlPort)}
      in
         self.VSMailbox = {NewVSMailbox}
         %%
         try
            self.PipeObj =
            {New Open.pipe
             init(cmd:{OS.getEnv 'OZHOME'}#'/bin/ozvsserver'
                  args:['--shmkey='#self.VSMailbox
                        '--ticket='#Ticket])}
            %% {System.show 'Virtual site: '#{String.toAtom self.VSMailbox}#Ticket}
         in thread {ShowPipe self.PipeObj self.ClosedFlag} end
         catch _ then raise error end
         end

         %%
         {Wait self.TaskPort}
         {Wait self.CtrlPort}
      end

      %%
      meth run(P)
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
         self.ClosedFlag = unit
         {self.PipeObj close}
      end
   end

   %%
end
