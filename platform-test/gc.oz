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
	     proc {Waker N}
		%% we only enter Waker when the previous GO has
		%% been bound, i.e. it is safe to inject an exception
		%% into WaitingThread
		if N>0 then NewGO in
		   {Thread.injectException WaitingThread wakeup(NewGO)}
		   {Wait NewGO}
		   {Waker N-1}
		end
	     end
	     WaitingThread
	     FirstGO
	     TrickyVariable
	     DONE
	     thread
		WaitingThread={Thread.this}
		try {Waiter TrickyVariable FirstGO}
		catch exit then skip end
		DONE=unit
	     end
	     {Wait FirstGO}
	     {Waker 100000}
	     %% at this point it is guaranteed that WaitingThread is suspended
	     %% on TrickyVariable
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	  in
	     %% check the susplist when WaitingThread is still live
	     if {IsDet TrickyVariable} orelse
		{SusplistLength TrickyVariable}\=1
	     then
		raise gc_susplist end
	     end
	     %% kill WaitingThread (in a synchronized fashion)
	     {Thread.injectException WaitingThread exit}
	     {Wait DONE}
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	     {System.gcDo}
	     %% check the susplist when WaitingThread is dead
	     if {IsDet TrickyVariable} orelse
		{SusplistLength TrickyVariable}\=0
	     then
		raise gc_susplist end
	     end
	  end
	  keys:[gc])
      ])
end
