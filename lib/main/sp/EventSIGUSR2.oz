functor
import VS(handler:Handler) at 'x-oz://boot/VirtualSite'
export handler : SIGUSR2
define
   Synch = {NewCell _}
   proc {SIGUSR2 E}
      {Exchange Synch unit _}
   end
   thread
      This = {Thread.this}
      proc {Loop}
         %% look it up now to avoid race condition
         %% since it may become bound concurrently
         More = {Access Synch}
      in
         if {Handler} then {Thread.preempt This}
         else {Wait More} end
         {Loop}
      end
   in
      {Thread.setPriority This 'high'}
      {Loop}
   end
end
