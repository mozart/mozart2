functor
import System(gcDo)
   SuspList(susplistLength:SusplistLength) at 'gcsusplist.so{native}'
export
   Return
define
   Return=
   gc([
       susplist(
          proc {$}
             {Wait System.gcDo}
             {Wait SusplistLength}
             proc {Waiter X GO}
                try GO=unit {Wait X}
                catch wakeup(NewGO) then {Waiter X NewGO} end
             end
             proc {Waker GO N}
                if N>0 then NewGO in
                   {Wait GO}
                   {Thread.injectException WaitingThread wakeup(NewGO)}
                   {Waker NewGO N-1}
                end
             end
             WaitingThread
             FirstGO
             TrickyVariable
             thread
                WaitingThread={Thread.this}
                {Waiter TrickyVariable FirstGO}
             end
             {Wait FirstGO}
             {Waker FirstGO 100000}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
          in
             if {IsDet TrickyVariable} orelse
                {SusplistLength TrickyVariable}\=1
             then
                raise gc_susplist end
             end
          end
          keys:[gc])
      ])
end
