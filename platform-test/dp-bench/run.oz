functor
import
   Application(exit getArgs)
   System(showInfo)
   Remote(manager)
   Property(get)
export
   Bench
define
   GlobalOptions
   = ['host'(   multiple type:string)
      'local'(  single   type:int  default:0)
      'threads'(single   type:int  default:0)
      'fork'(   single   type:atom(sh rsh ssh virtual automatic) default:rsh)
      'verbose'(single   type:bool default:false)
      'help'(   single   type:bool default:false)]
   GlobalHelp
   =
   'Global Options\n'#
   '--host=HOST[:FORK]\n'#
   '\tspecifies a host (and an optional fork method) on which\n'#
   '\tto start a remote server.  This option may be repeated\n\n'#
   '--local=N\n'#
   '\tstart N remote servers on the local host\n\n'#
   '--threads=N\n'#
   '\ton every site, N additional threads will be started\n'#
   '\tto simulate concurrent activity\n\n'#
   '--fork=FORK\n'#
   '\tspecifies the default forking method (default is rsh)\n\n'#
   '--verbose\n'#
   '\tprints out a little bit more information\n\n'#
   '--help\n'#
   '\tprints out this help message\n'

   proc {Activity Until}
      if {IsDet Until} then skip else {Activity Until} end
   end
   proc {Bench Options Help What}
      Args = {Application.getArgs
	      {List.toTuple record {Append Options GlobalOptions}}}
      if Args.help then
	 {System.showInfo Help#GlobalHelp}
	 {Application.exit 0}
      end
      MSG = if Args.verbose
	    then System.showInfo
	    else proc {$ _} skip end end
      LocalDO RemoteFUNCTOR
      {What Args MSG LocalDO RemoteFUNCTOR}
      Threads = Args.threads
      proc {StartActivities Until}
	 {For 1 Threads 1 proc {$ _} thread {Activity Until} end end}
      end
      fun {StartRemoteManager HostFork}
	 Host0 Fork0 Host Fork
      in
	 {String.token HostFork &: Host0 Fork0}
	 Host = if Host0==nil then localhost else {StringToAtom Host0} end
	 Fork = if Fork0==nil then
		   if Host==localhost then
		      if Args.fork==rsh then sh else Args.fork end
		   else Args.fork end
		else {StringToAtom Fork0} end
	 {MSG 'Starting remote manager host='#Host#' fork='#Fork}
	 {New Remote.manager init(host:Host fork:Fork)}
      end
      RemoteHosts =
      {Append {CondSelect Args 'host' nil}
       local L = {List.make Args.'local'} in
	  {ForAll L proc {$ X} X="localhost" end}
	  L
       end}
      RemoteManagers =
      {Map if RemoteHosts==nil then ["localhost"] else RemoteHosts end
       StartRemoteManager}
      GlobalStart
      proc {StartRemoteProducer Manager Result Ready Done}
	 {MSG 'Starting remote producer'}
	 thread
	    {Manager apply(url:''
			   functor
			   import
			      Module
			   define
			      Until
			      [M] = {Module.apply [RemoteFUNCTOR]}
			      DO  = M.'do'
			      {StartActivities Until}
			      !Ready = unit
			      {Wait GlobalStart}
			      {DO Result}
			      !Until = unit
			      !Done  = unit
			   end)}
	 end
      end
      proc {StartLocalConsumer Result Ready Done}
	 {MSG 'Starting local consumer'}
	 thread
	    {Wait LocalDO}
	    Ready = unit
	    {Wait GlobalStart}
	    {LocalDO Result}
	    Done  = unit
	 end
      end
      Dones =
      {FoldL RemoteManagers
       fun {$ L Manager}
	  Result RemoteReady RemoteDone LocalReady LocalDone
       in
	  {StartRemoteProducer Manager Result RemoteReady RemoteDone}
	  {StartLocalConsumer          Result  LocalReady  LocalDone}
	  {Wait RemoteReady}
	  {Wait  LocalReady}
	  RemoteDone|LocalDone|L
       end nil}
      {MSG 'Starting local activities'}
      LocalUntil
      {StartActivities LocalUntil}
      {MSG 'Benchmark begins'}
      T1 = {Property.get 'time.total'}
      GlobalStart = unit
      {ForAll Dones Wait}
      LocalUntil  = unit
      T2 = {Property.get 'time.total'}
      {MSG 'Benchmark ends'}
      {System.showInfo 'Total time = '#(T2-T1)}
      {MSG 'Closing remote managers'}
      {ForAll RemoteManagers proc {$ M} {M close} end}
   in
      {Application.exit 0}
   end
end
