functor
import Process(handler:Handler) at 'x-oz://contrib/os/process.so{native}'
export handler : SIGCHLD
define
   proc {SIGCHLD E}
      {Handler}
   end
end
