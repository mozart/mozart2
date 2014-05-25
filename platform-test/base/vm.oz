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

	identForPort(proc {$}
			FuturePort={fun lazy {$} {VM.getPort {VM.current}} end}
		     in
			{VM.identForPort {VM.getPort {VM.current}}} = {VM.current}

			{IsDet FuturePort} = false
			{VM.identForPort FuturePort} = {VM.current}

			try
			   NotAVMPort={NewPort _}
			in
			   {VM.identForPort NotAVMPort _}
			   fail
			catch error(kernel(type ...)...) then
			   skip
			end
		     end
		     keys:[mvm port])

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
		in
		   {VM.list} = [1 Other]
		   S.1 = terminated(Other reason:normal)

		   {VM.monitor Other} % already dead
		   S.2.1 = terminated(Other reason:unknown)

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

	monitorChain(proc {$}
			Master={VM.current}
			functor MonitorF
			import VM
			define
			   S={VM.getStream}
			   ToMonitor=S.1
			   {VM.monitor ToMonitor}
			   {Send {VM.getPort ToMonitor} ack}
			   {Send {VM.getPort Master} monitor(S.2.1)}
			   {VM.closeStream}
			end
			S={VM.getStream}
			Monitor={VM.new MonitorF}
			Watched={VM.new functor import VM define
					   {Send {VM.getPort Monitor} {VM.current}}
					   {VM.getStream}.1 = ack
					   {VM.closeStream}
					end}
		     in
			S.1 = terminated(Watched reason:normal)
			S.2.1 = monitor(terminated(Watched reason:normal))
			S.2.2.1 = terminated(Monitor reason:normal)
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
		{VM.list} = [1 Sleeper]
		
		{VM.kill Sleeper}
		S.1 = terminated(Sleeper reason:kill)
		{VM.list} = [1]

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
		    AutoKill={VM.new Suicide}
		 in
		    S.1 = terminated(AutoKill reason:kill)
		 end
		 keys:[mvm new stream monitor kill])

	getPortOfKilledVM(proc {$}
			     functor Skip
			     define
				skip
			     end
			     DeadVM={VM.new Skip}
			     P
			     S={VM.getStream}
			  in
			     S.1 = terminated(DeadVM reason:normal)

			     % It is ok to get the port of a dead VM
			     P={VM.getPort DeadVM}

			     % But {Send P} becomes no-op
			     {Send P ignored}
			     {VM.identForPort P} = DeadVM
			  end
			  keys:[mvm new stream])

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
			      S.1 = terminated(Other reason:kill)
			   end
			   keys:[mvm new monitor kill])

	gc(proc {$}
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
	      VMs={VM.current}|{Map {List.number 2 NVMs 1} fun {$ _} {VM.new F} end}
	      Msgs
	   in
	      thread {Module.apply [F] _} end
	      thread
		 MsgsPort={NewPort Msgs}
	      in
		 % NVMs messages + (NVMs-1) termination records
		 for Msg in {List.take S NVMs+NVMs-1} do
		    case Msg
		    of terminated(...) then skip
		    else {Send MsgsPort Msg}
		    end
		 end
	      end
	      {Sort {List.take Msgs NVMs} Value.'<'} = {Sort VMs Value.'<'}
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
			      Same Changed
			   in
			      Same={VM.new F} % inherit
			      S.1 = Max
			      S.2.1 = terminated(Same reason:normal)

			      {Property.put 'gc.max' NewMax}
			      Changed={VM.new F}
			      S.2.2.1 = NewMax
			      S.2.2.2.1 = terminated(Changed reason:normal)

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
		       {Send {VM.getPort Other} unit}
		       S.1 = terminated(Other reason:outOfMemory)
		    end
		    keys:[mvm new gc kill])

	exception(proc {$}
		     functor Fail
		     import
			VM
		     define
			{VM.getStream}.1 = unit
			raise error(expectedError) end
		     end
		     Other={VM.new Fail}
		     S={VM.getStream}
		  in
		     {Send {VM.getPort Other} unit}
		     S.1 = terminated(Other reason:exception)
		  end
		  keys:[mvm kill])

	% teardown
	closeStream(proc {$}
		       {VM.closeStream}
		    end
		    keys:[mvm stream teardown])
       ])
end
