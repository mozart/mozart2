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
   proc {Init ShmId}
      BIVSInitServer = {`Builtin` 'VirtualSite.initServer' 1}
   in
      {BIVSInitServer ShmId}
   end

   %%
   %% Right now, there is no limitation/overloading of sub-modules
   %% an imported functor can use. But this will change;
   proc {Engine Linker CloseProc ?TaskPort ?CtrlPort}
      RunStr CtrlStr
   in
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
          proc {$ T}
             thread
                case {Procedure.is T} then {T}
                elsecase {Chunk.is T} andthen {HasFeature T apply} then
                   {Linker '' T _}
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
             [] gen(Func) then
                {Linker '' Func _}
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
