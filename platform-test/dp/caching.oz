% This test sets the number of availabel tcptransobjs to 2 (2*2 temporarily)
% and runs 10 sites simultaneously.

%\define DBG
functor
import
   Remote(manager)
   Property(put)
   System
   Fault
export
   Return
define
   {Property.put 'perdio.maxTCPCache' 2}
   {Fault.defaultDisable _}
   {Fault.defaultEnable [permFail] _}

   Sites=10
   SeenList={MakeList Sites}

\ifdef DBG
   Show=System.show
\else
   proc{Show _} skip end
\endif

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
         Site.man={New Remote.manager init(host:localhost)}
         thread
            {Wait StartNext}
            Started=unit
            {Site.man apply(url:'' functor
                                   import
                                      Fault
                                   define
                                      proc{Run}
                                         {Send CentralPort hi(Left)}
                                         {Delay 1000}
                                         {Run}
                                      end
                                   in
                                      {Fault.defaultDisable _}
                                      {Fault.defaultEnable [permFail] _}
                                      {Run}
                                   end)}
         end
         Site|thread{StartSites Left-1 StartNext}end
      end
   end

   proc {Start}
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
   end

   Return=dp([caching(Start keys:[cache])])
end
