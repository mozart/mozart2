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
   class ResourceLimitObject
      attr
         limit
         checkInterval
         getFun
         cmpFun
         actionProc
         terminate
         %%

         %%
         %% 'ActionProc' is a procedure of arity 2: it takes
         %% actual value of the resource, and the control port of
         %% the virtual site server.
      meth init(limit:          Value
                checkInterval:  Interval
                getFun:         GetFun
                cmpFun:         CmpFun
                actionProc:     ActionProc)
         limit <- Value
         checkInterval <- Interval
         getFun <- GetFun
         cmpFun <- CmpFun
         actionProc <- ActionProc
         %% terminate is a variable
      end

      %%
      %% 'CP' is the control port of the virtual site server (for
      %% 'action proc');
      meth start(CP)
         case {IsDet @terminate} then skip
         else C in
            {Delay @checkInterval}
            C = {@getFun}
            case {@cmpFun C @limit} then {@actionProc C CP}
            else skip
            end
            %%
            {self start(CP)}
         end
      end

      %%
      meth terminate
         @terminate = unit
      end
   end
   %%

   %%
   Init = VirtualSite.initServer

   %%
   %% Right now, there is no limitation/overloading of sub-modules
   %% an imported functor can use. But this will change;
   proc {Engine CloseProc ?TaskPort ?CtrlPort}
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
                elsecase {Functor.is T} then
                   {Module.link '' T _}
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
                of ping(Ack)        then Ack = unit
                [] close            then {CloseProc}
                [] mem(Lim Int AP)  then RLO in
                   RLO = {New ResourceLimitObject
                          init(limit:          Lim
                               checkInterval:  Int
                               getFun:         fun {$}
                                                  {System.gcDo}
                                                  {Property.get 'gc.size'}
                                               end
                               cmpFun:         fun {$ C L} C >= L end
                               actionProc:     AP)}
                   thread
                      {RLO start(CtrlPort)}
                   end
                [] time(Lim Int AP) then RLO in
                   RLO = {New ResourceLimitObject
                          init(limit:          Lim
                               checkInterval:  Int
                               getFun:         fun {$}
                                                  {Property.get 'time.user'} +
                                                  {Property.get 'time.system'}
                                               end
                               cmpFun:         fun {$ C L} C >= L end
                               actionProc:     AP)}
                   thread
                      {RLO start(CtrlPort)}
                   end
                end
             [] gen(Func) then
                {Module.link '' Func _}
             end
          end}
      end

      %%
      %% Watching for resources;

      %%
   end

   %%
in
   VSServer = vsserver(init:   Init
                       engine: Engine)
end
