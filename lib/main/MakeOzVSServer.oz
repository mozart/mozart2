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
   %% Right now we load just everything, but that can be easily
   %% changed;
\insert 'dp/VSServer.oz'

   %%
   %% exit codes;
   OKDone = 0
   ErrorInit = 1
   ErrorTicket = 2
in
   {Application.syslet
    %%
    'ozvsserver'

    %%
    functor $ prop once
    import
       Syslet.{args exit}
       Connection.{take}
       Module.{link}
       System.{showInfo}

       %%
    body
       CloseProc = proc {$} {Syslet.exit OKDone} end
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
          vsserver(taskPort:TaskPort ctrlPort:CtrlPort) =
          {Connection.take Syslet.args.ticket}
       in
          {VSServer.engine Module.link CloseProc TaskPort CtrlPort}
       catch _ then
          {System.showInfo "VS: engine failed"}
          {Syslet.exit ErrorTicket}
       end

       %%
    end

    %%
    single(shmkey(type:atom)
           ticket(type:atom))}

   %%
end
