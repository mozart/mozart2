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
\insert 'dp/MakeAllLoader.oz'
\insert 'dp/VSServer.oz'

   %%
   ErrorInit = 1
   ErrorTicket = 2
in
   {Application.syslet
    'ozvsserver'

    %%
    c                           % no environment in this form;

    %%
    fun {$ _UnusedImports}
       Import = {AllLoader}
    in
       proc {$ Argv ?Status}
          CloseProc = proc {$} Status = 0 end
       in
          %%
          try
             %%
             %% First initialize the virtual site, so that the
             %% ticket-based connection following it would use the
             %% virtual site communication mechanism;
             {VSServer.init Import Argv.shmid}
          catch _ then
             Status = ErrorInit
          end

          %%
          case {Value.status Status}
          of free then
             try
                vsserver(taskPort:TaskPort ctrlPort:CtrlPort) =
                {Import.'DP'.'Connection'.take Argv.ticket}
             in
                {VSServer.engine Import CloseProc TaskPort CtrlPort}
             catch _ then
                Status = ErrorTicket
             end
          else skip             % already failed;
          end

          %%
          {Wait Status}
       end

    end

    %%
    single(shmid(type:atom)
           ticket(type:atom))}

   %%
end
