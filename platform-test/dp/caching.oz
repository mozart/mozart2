% This test sets the number of availabel tcptransobjs to 2 (2*2 temporarily)
% and runs 10 sites simultaneously.

%\define DBG
functor
import
   Remote(manager)
   Property
   System
   Fault
export
   Return
define
   Sites=5
   Weak=2    % Use these per thread
   Hard=4
   SeenList={MakeList Sites}

\ifdef DBG
   Show=System.show
\else
   proc{Show _} skip end
\endif

   class TcpPropMonitor
      prop locking
      attr n:0 hard weak
      meth init skip end
      meth enter
         lock
            if @n==0 then
               hard <- {Property.get 'dp.tcpHardLimit'}
               weak <- {Property.get 'dp.tcpWeakLimit'}
               {Fault.defaultDisable _}
               {Fault.defaultEnable [permFail] _}
            end
            {Property.put 'dp.tcpWeakLimit' Weak*(@n+1)}
            {Property.put 'dp.tcpHardLimit' Hard*(@n+1)}
            n <- @n+1
         end
      end
      meth leave
         lock
            if @n==1 then
               {Property.put 'dp.tcpHardLimit' @hard}
               {Property.put 'dp.tcpWeakLimit' @weak}
               % Assumes that the system had these settings to begin with.
               % If there was a way to check, this could have been done
               % in enter...
               {Fault.defaultEnable [tempFail permFail] _}
            else
               {Property.put 'dp.tcpWeakLimit' Weak*(@n-1)}
               {Property.put 'dp.tcpHardLimit' Hard*(@n-1)}
            end
            n <- @n-1
         end
      end
   end

   Monitor = {New TcpPropMonitor init}
   {Show properties_set}

   Stream
   CentralPort={NewPort Stream}
   proc {Serve Stream}
      {ForAll Stream proc{$ Msg}
                        case Msg of hi(N) then
                           {Nth SeenList N}=seen
                        end
                     end}
   end

   fun {StartSites Left Started}
      if Left==0 then
         Started=unit
         nil
      else Site=site(man:_ num:Left) StartNext in
         {Show init_manager(Left)}
         Site.man={New Remote.manager init(host:localhost)}
         thread
            {Wait StartNext}
            {Show starting(Left)}
            {Site.man apply(url:'' functor
                                   import
                                      Fault
%                                     System
                                   define
                                      proc{Run}
                                         {Send CentralPort hi(Left)}
                                         {Delay 1000}
                                         {Run}
                                      end
                                   in
                                      {Fault.defaultDisable _}
                                      {Fault.defaultEnable [permFail] _}
%                                     {System.show starting_client}
                                      thread {Run} end
                                   end)}
            {Show started(Left)}
            Started=unit
         end
         Site|thread{StartSites Left-1 StartNext}end
      end
   end

   proc {Start}
      try
         {Monitor enter}
         {Show start}
         local
            All Started
         in
            thread {Serve Stream} end
            thread All={StartSites Sites Started} end % Started=>all started
            {Wait Started}
            {Show allstarted}
            {ForAll SeenList Wait}
            {Show allseen}
            {ForAll All proc{$ site(man:M num:_)}
                           {M ping}
                        end}
            {Show all_pings_done}
            {ForAll All proc{$ site(man:M num:_)}
                           {M close}
                        end}
            {Show all_closes_done}
         end % At this point known sites should go out of scope
         {System.gcDo}
         {System.gcDo}
         {System.gcDo}
      finally
         {Monitor leave}
      end
   end

\ifdef DBG
   Return=dp([caching(proc{$} try {Start} catch X then raise X end end end keys:[cache])])
\else
   Return=dp([caching(Start keys:[cache])])
\endif
end
