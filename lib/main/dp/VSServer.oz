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
   proc {Init Import ShmId}
      BIVSInitServer = {`Builtin` 'VirtualSite.initServer' 1}
   in
      {BIVSInitServer ShmId}
   end

   %%
   proc {Engine Import CloseProc ?TaskPort ?CtrlPort}
      FullImport RunStr CtrlStr
   in
      %% Will change on the day when user requests will not be allowed
      %% to perform e.g. local I/O;
      FullImport = Import
      %%
      TaskPort = {Port.new RunStr}
      CtrlPort = {Port.new CtrlStr}

      %%
      %% Serve incoming tasks, which are either nullary- (no
      %% environment), or unary ((local) environment) procedures.
      %% Note that exceptions are silently ignored since we cannot
      %% catch all of them anyway (due to created threads);
      thread
         {ForAll RunStr
          proc {$ P}
             thread
                case {Procedure.arity P}
                of 0 then {P}
                [] 1 then {P Import}
                end
             end
          end}
      end

      %%
      %% Serve control requests. "Generic" requests are also
      %% procedures which are however trusted and always get the full
      %% local environment;
      thread
         {ForAll CtrlStr
          proc {$ CRq}
             case CRq
             of spec(Action) then
                case Action
                of ping(Ack) then Ack = unit
                [] close     then {CloseProc}
                end
             [] gen(Proc) then
                case {Procedure.arity Proc}
                of 0 then {Proc}
                [] 1 then {Proc FullImport}
                end
             end
          end}
      end

      %%
   end

   %%
in
   VSServer = vsserver(init:   Init
                       engine: Engine)
end
