functor
import System(gcDo) Property(get)
export
   Return
define
   {Wait System.gcDo}
   {Wait Property.get}
   Return=
   gc([
       susplist(
          proc {$}
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
             thread WaitingThread={Thread.this} {Waiter _ FirstGO} end
             {Wait FirstGO}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             MemoryBefore={Property.get 'gc.active'}
             {Waker FirstGO 1000000}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             {System.gcDo}
             MemoryAfter={Property.get 'gc.active'}
          in
             MemoryAfter=MemoryBefore
          end
          keys:[gc])
      ])
end
