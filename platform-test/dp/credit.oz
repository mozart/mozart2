% These tests create and distribute different entities.
% Each entity is inserted in a weak dictionary. After a number of
% applications, they are discarded locally and remotely. They are
% then expected to show on the gc-stream of the weak dictionary.

% Since the current implementation of the message passing layer
% will transport any messages at the next thread switch, {Delay 10} or
% suspension on an unbound variable is assumed to lead to transport of
% the message.

functor
import
   System
   TestMisc
   Connection
export
   Return
define
   Sites=1
   Show=System.show

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% General procedures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Return a Start procedure invoked by the test-suite-engine
   % LocalTestProc and RemoteTestProc are the procedures to be
   % run in this particular test.
   fun {Start LocalTestProc RemoteTestProc}
      proc{$}
         Managers
         InP InS={NewPort $ InP}
         OutS OutP={NewPort OutS}
      in
         try Hosts in
            {TestMisc.getHostNames Hosts}
            {TestMisc.getRemoteManagers Sites Hosts Managers}
            {ForAll Managers proc {$ RemMan}
                                {StartRemSite RemMan OutS InP RemoteTestProc}
                             end}
            {LocalTestProc Managers InS OutP}
         catch X then
            {Show X}
            raise X end
         end
         {TestMisc.gcAll Managers}
         {TestMisc.listApply Managers close}
      end
   end

   % Start the specified procedure at a remote manager
   proc {StartRemSite Manager InS OutP RemoteTestProc}
      {Manager apply(url:'' functor
                            import
                               Connection
                            define
                               proc {Start InS OutP}
                                  % Must provide connection here to use
                                  % the right one.
                                  {RemoteTestProc Connection InS OutP}
                               end

                               thread {Start InS OutP} end
                            end)}
   end

   % Use {Assert Test} or {Assert Test#Msg} to get an
   % exception whenever Test==false.
   proc{Assert V}
      case V of Test#Msg then
         if Test \= true then raise assertion(Msg) end end
      [] Test then
         if Test \= true then raise assertion(Test) end end
      else
         skip
      end
   end

   proc{DoGC Managers}
      {TestMisc.gcAll Managers}
      {Delay 10}
      {System.gcDo}
      {Delay 10}
      {System.gcDo}
      {Delay 10}
      {System.gcDo}
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test procedures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Variable distributed and bound by manager.
   proc {LocalVariableBind Managers InS OutP}
      WS WD={NewWeakDictionary WS}
   in
      {Assert {Not {IsDet WS}}#'GCstream of WD bound to early'}
      local V in
         {WeakDictionary.put WD gc V}
         {Send OutP {Connection.offer V}}
         {Delay 10}
         V=42          % small integers are never considered 'marked' by the GC
         {Delay 10}
      end
      {DoGC Managers}
      {Assert {IsDet WS}#'Nothing on stream'}
   end

   proc {RemoteVariableBind Connection InS OutP}
      % Wait for variable to arrive and to be bound
      {Wait {Connection.take InS.1}}
   end

% Cell distributed and dropped
   proc {LocalCellDrop Managers InS OutP}
      WS WD={NewWeakDictionary WS}
   in
      {Assert {Not {IsDet WS}}#'GCstream of WD bound to early'}
      local C={NewCell 0} in
         {WeakDictionary.put WD gc C}
         {Send OutP {Connection.offer C}}
         {Delay 10}
      end
      {DoGC Managers}
      {Assert {IsDet WS}#'Nothing on stream'}
   end

   proc {RemoteCellDrop Connection InS OutP}
      % Wait for cell to arrive, then drop it
      {Wait {Connection.take InS.1}}
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For the test-suite engine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   Keys=[remote credit]
   Return = dp([credit_variable_bind({Start LocalVariableBind
                                      RemoteVariableBind}
                                keys:Keys)
                credit_cell_drop({Start LocalCellDrop RemoteCellDrop}
                                 keys:Keys)
               ])
end
