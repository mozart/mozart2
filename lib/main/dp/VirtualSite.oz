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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
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

   VirtualSite.{newMailbox}
      from 'oz-x-boot:VirtualSite'

   Fault.{install}

export
   server: VirtualSiteObject

   %%
body

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
         %% 'watchedEntity' is used by the slave for watching
         %% for master's (premature) termination;
         Ticket = {Connection.offer vsserver(watchedEntity: {Port.new _}
                                             taskPort: self.TaskPort
                                             ctrlPort: self.CtrlPort)}
      in
         self.VSMailbox = VirtualSite.newMailbox
         %%
         try
            self.PipeObj =
            {New Open.pipe
             init(cmd:{OS.getEnv 'OZHOME'}#'/bin/ozvsserver'
                  args:['--shmkey='#self.VSMailbox
                        '--ticket='#Ticket])}
         in thread {ShowPipe self.PipeObj self.ClosedFlag} end
         catch _ then raise error end
         end

         %%
         {Wait self.TaskPort}
         {Wait self.CtrlPort}

         {Fault.install
          self.TaskPort
          watcher(cond:permHome once_only:yes variable:no)
          proc {$ E C}
             {System.showInfo "VS: slave exited."}
             {self close}
          end}
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
      %% Size in bytes, and interval in ms;
      meth setMemoryLimit(size: Size
                          interval: Interval <= 1000)
         {Port.send self.CtrlPort
          spec(mem(Size Interval
                   proc {$ _ CP}
                      {System.showInfo "VS: memory limit exceeded"}
                      {Port.send CP spec(close)}
                   end))}
      end

      %%
      %% Time and interval in ms;
      meth setTimeLimit(time: MS
                        interval: Interval <= 1000)
         {Port.send self.CtrlPort
          spec(time(MS Interval
                    proc {$ _ CP}
                       {System.showInfo "VS: time limit exceeded"}
                       {Port.send CP spec(close)}
                    end))}
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
