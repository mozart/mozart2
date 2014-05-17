functor
import
   VM
   Module
   Property
export
   Return
define
   Return =
   mvm([ncores(proc {$}
		  {VM.ncores} > 0 = true
	       end
	       keys:[mvm])

	current(proc {$}
		   {VM.current} = 1
		end
		keys:[mvm ident])

	list(proc {$}
		{VM.list} = [1]
	     end
	     keys:[mvm])

	getStream(proc {$}
		     {IsDet {VM.getStream}} = false
		  end
		  keys:[mvm stream])

	getPort(proc {$}
		   P={VM.getPort {VM.current}}
		   S={VM.getStream}
		in
		   {Send P hello}
		   S.1 = hello

		   {Value.toVirtualString P 1 100} = '<Port>'

		   try
		      {VM.getPort 12345 _}
		      fail
		   catch error(vm(invalidVMIdent) ...) then
		      skip
		   end

		   try
		      {VM.getPort "not a VMIdent" _}
		      fail
		   catch error(kernel(type ...)...) then
		      skip
		   end
		end
		keys:[mvm stream])

	new(proc {$}
	       Master={VM.current}
	       functor F
	       import
		  VM
	       define
		  {Send {VM.getPort Master} {VM.current}}
	       end
	       S={VM.getStream}
	       Other={VM.new F}
	    in
	       Other = 2
	       {VM.list} = [1 2]
	       S.1 = 2
	    end
	    keys:[mvm new stream])

	monitor(proc {$}
		   functor F
		   define
		      skip
		   end
		   Other={VM.new F}
		   S={VM.getStream}
		   OldDeadVM=2
		in
		   Other = 3
		   {VM.list} = [1 Other]
		   {VM.monitor Other}
		   S.1 = terminated(Other reason:normal)

		   {VM.monitor OldDeadVM} % already dead
		   S.2.1 = terminated(OldDeadVM reason:unknown)

		   try
		      {VM.monitor {VM.current}}
		      fail
		   catch error(vm(cannotMonitorItself) ...) then
		      skip
		   end

		   try
		      {VM.monitor 12345}
		      fail
		   catch error(vm(invalidVMIdent) ...) then
		      skip
		   end
		end
		keys:[mvm new stream monitor])

	kill(proc {$}
		functor Sleeping
		define
		   {Delay 30*1000} % 30s
		   raise unreachable end
		end
		S={VM.getStream}
		Sleeper={VM.new Sleeping}
	     in
		Sleeper = 4
		{VM.monitor Sleeper}
		
		{VM.kill Sleeper}
		S.1 = terminated(Sleeper reason:kill)

		{VM.monitor Sleeper} % already killed, message sent immediately
		S.2.1 = terminated(Sleeper reason:unknown)

		{VM.kill Sleeper} % no-op

		try
		   {VM.kill 12345}
		   fail
		catch error(vm(invalidVMIdent) ...) then
		   skip
		end
	     end
	     keys:[mvm new stream monitor kill])

	autokill(proc {$}
		    functor Suicide
		    import
		       VM
		    define
		       {VM.kill {VM.current}}
		       raise unreachable end
		    end
		    S={VM.getStream}
		    AutoKill = {VM.new Suicide}
		 in
		    AutoKill = 5

		    {VM.monitor AutoKill}

		    S.1 = terminated(AutoKill reason:kill)
		 end
		 keys:[mvm new stream monitor kill])

	getPortOfKilledVM(proc {$}
			     % It is ok to get the port of a dead VM
			     P={VM.getPort 5}
			  in
			     % But {Send P} becomes no-op
			     {Send P ignored}
			  end
			  keys:[mvm stream])

	'Application.exit'(proc {$}
			      functor F
			      import
				 Application
			      define
				 {Application.exit 0}
			      end
			      S={VM.getStream}
			      Other={VM.new F}
			   in
			      Other = 6
			      {VM.monitor Other}
			      S.1 = terminated(Other reason:kill)
			   end
			   keys:[mvm new monitor kill])

	gc(proc {$}
	      FirstVM=7
	      NVMs=4
	      NGCs=4
	      KB=1024
	      Master={VM.current}
	      fun {Alloc}
		 T={MakeTuple hugeTuple 4*KB}
	      in
		 T.1="hello"
		 T.{Width T}='the end'
		 T
	      end

	      functor F
	      import
		 System(gcDo:GC)
		 VM
	      define
		 {Delay 100}
		 for _ in 1..NGCs do
		    {Wait {Alloc}} % use some memory
		    {GC}
		 end
		 {Send {VM.getPort Master} {VM.current}}
	      end
	      S={VM.getStream}
	      VMs={MakeTuple vms NVMs}
	      VMs.1={VM.current}
	   in
	      for I in 2..NVMs do
		 VMs.I={VM.new F}
		 VMs.I = FirstVM+I-2
	      end
	      thread {Module.apply [F] _} end
	      {Sort {List.take S 4} Value.'<'} = 1|{List.number FirstVM FirstVM+NVMs-2 1}
	   end
	   keys:[mvm new stream gc])

	maxMemoryInherited(proc {$}
			      Master={VM.current}
			      Max={Property.get 'gc.max'}
			      NewMax=Max div 2
			      functor F
			      import
				 VM Property
			      define
				 {Send {VM.getPort Master} {Property.get 'gc.max'}}
			      end
			      S={VM.getStream}
			   in
			      {VM.new F _} % inherit
			      S.1 = Max
			      {Property.put 'gc.max' NewMax}
			      {VM.new F _}
			      S.2.1 = NewMax
			      {Property.put 'gc.max' Max} % restore
			   end
			   keys:[mvm gc])

	outOfMemory(proc {$}
		       functor F
		       import
			  Property
			  VM
		       define
			  {VM.getStream}.1 = unit
			  {Property.put 'gc.min' 1}
			  {Property.put 'gc.max' 2}
			  {Wait {MakeTuple big 1000}} % should be out of memory
			  {VM.closeStream}
		       end
		       Other={VM.new F}
		       S={VM.getStream}
		    in
		       {VM.monitor Other}
		       {Send {VM.getPort Other} unit}
		       S.1 = terminated(Other reason:outOfMemory)
		    end
		    keys:[mvm new gc kill])

	% teardown
	closeStream(proc {$}
		       {VM.closeStream}
		    end
		    keys:[mvm stream teardown])
       ])
end
