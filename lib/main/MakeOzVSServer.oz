%%%
%%% Authors:
%%%   Konstantin Popov (kost@sics.se)
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

local
   %%
   %% exit codes;
   OKDone = 0
   ErrorInit = 1
   ErrorTicket = 2
in
    functor $ prop once
    import
       Syslet
       Connection.{take}
       Module.{link}
       Property.{get}
       System.{showInfo gcDo}
       Fault.install
       VirtualSite.initServer

       %%
    body
       Syslet.spec = single(shmkey(type:atom)
                            ticket(type:atom))
       %%
       CloseProc = proc {$} {Syslet.exit OKDone} end

       %%
       %% Right now we load just everything, but that can be easily
       %% changed;
       \insert 'dp/VSServer.oz'
    in

       %%
       try
          %%
          %% First initialize the virtual site, so that the
          %% ticket-based connection following it would use the
          %% virtual site communication mechanism;
          {VSServer.init Syslet.args.shmkey}
       catch _ then
          {System.showInfo "VS: failed to initialize"}
          {Syslet.exit ErrorInit}
       end

       %%
       try
          vsserver(watchedEntity: WatchedEntity
                   taskPort:TaskPort
                   ctrlPort:CtrlPort) =
          {Connection.take Syslet.args.ticket}
       in
          %%
          {Wait WatchedEntity}  % but should be there already;
          %%
          %% kost@ : to be replaced by 'Fault.install';
          {Fault.install
           WatchedEntity
           watcher('cond':permHome once_only:yes variable:no)
           proc {$ E C}
              {System.showInfo "VS: master is gone?"}
              {CloseProc}
           end}

          %%
          {VSServer.engine CloseProc TaskPort CtrlPort}
       catch _ then
          {System.showInfo "VS: engine failed"}
          {Syslet.exit ErrorTicket}
       end

       %%
    end
end
