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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
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
       System.{get set showInfo gcDo}

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
       {System.set messages(idle:false)}

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
          local
             InstallHW = {`Builtin` 'installHW' 3}
          in
             {InstallHW
              WatchedEntity
              watcher(cond:permHome once_only:yes variable:no)
              proc {$ E C}
                 {System.showInfo "VS: master is gone?"}
                 {CloseProc}
              end}
          end

          %%
          {VSServer.engine CloseProc TaskPort CtrlPort}
       catch _ then
          {System.showInfo "VS: engine failed"}
          {Syslet.exit ErrorTicket}
       end

       %%
    end
end
