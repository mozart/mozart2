%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1999
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.


%%% dp-speed benchmarks the speed of a distributed application.  It
%%% acts as a consumer for multiple remote producers. It takes the
%%% following options:
%%%
%%%	--host=HOST
%%%		specifies a host on which to start a remote server
%%%		this option may be repeated
%%%
%%%	--local=N
%%%		start N remote servers on the local host
%%%
%%%	--width=N
%%%		controls the width of records in the message
%%%
%%%	--depth=N
%%%		controls the nesting depth of records in the message
%%%
%%%	--messages=N
%%%		N messages will be produced
%%%
%%%	--threads=N
%%%		on every site, N additional threads will be started
%%%		to simulate concurrent activity
%%%
%%%	--fork=FORK
%%%		use FORK as the forking method, default is sh

functor
import
   Application(exit getArgs)
   Remote(manager)
   System(showInfo:MSG)
   Property(get)
define
   Args = {Application.getArgs
	   record('host'(    multiple char:&h type:string)
		  'local'(   single   char:&l type:int  default:0)
		  'width'(   single   char:&w type:int  default:2)
		  'depth'(   single   char:&d type:int  default:0)
		  'messages'(single   char:&m type:int  default:1)
		  'threads'( single   char:&t type:int  default:0)
		  'fork'(    single   char:&f type:atom default:sh)
		  'verbose'( single   char:&v type:bool default:false)
		  'help'(    single           type:bool default:false))}
   if Args.'help' then
      {MSG
       'This application benchmarks the speed of a distributed application\n'#
       'it takes the following options:\n\n' #
       '--host=HOST\n'#
       '\tspecifies a host on which to start a remote server\n'#
       '\tthis option may be repeated\n\n'#
       '--local=N\n'#
       '\tstart N remote servers on the local host\n\n'#
       '--width=N\n'#
       '\tcontrols the width of records in the message\n\n'#
       '--depth=N\n'#
       '\tcontrols the nesting depth of records in the message\n\n'#
       '--messages=N\n'#
       '\tN messages will be produced\n\n'#
       '--threads=N\n'#
       '\ton every site, N additional threads will be started\n'#
       '\tto simulate concurrent activity\n\n'#
       '--fork=FORK\n'#
       '\tspecifies the forking method (default is sh)\n\n'#
       '--verbose\n'#
       '\tprints out a little bit more information\n\n'#
       '--help\n'#
       '\tprints out this help message\n'}
      {Application.exit 0}
   end

   if Args.verbose then {MSG 'Computing message value'} end
   local
      Dummy = {List.number 1 Args.width 1}
      fun {MakeValue Depth}
	 if Depth==0 then unit else
	    {List.toTuple msg
	     {Map Dummy fun {$ _} {MakeValue Depth-1} end}}
	 end
      end
   in
      Message = {MakeValue Args.width}
   end

   proc {Producer L}
      {ForAll L proc {$ X} X=Message end}
   end

   proc {Consumer N L}
      if N>0 then H T in
	 L = H|T
	 {Wait H}
	 {Consumer N-1 T}
      else
	 L=nil
      end
   end

   proc {Activity Until}
      if {IsDet Until} then skip else {Activity Until} end
   end

   Threads = Args.'threads'

   proc {StartActivities Until}
      {For 1 Threads 1 proc {$ _} thread {Activity Until} end end}
   end

   fun {StartRemoteManager Host}
      if Args.verbose then {MSG 'Starting remote manager on '#Host} end
      {New Remote.manager init(host:Host fork:Args.'fork')}
   end

   RemoteHosts =
   {Append {CondSelect Args 'host' nil}
    local L = {List.make Args.'local'} in
       {ForAll L proc {$ X} X=localhost end}
       L
    end}

   RemoteManagers =
   {Map if RemoteHosts==nil then [localhost] else RemoteHosts end
    StartRemoteManager}

   GlobalStart
   
   proc {StartRemoteProducer Manager Stream Ready Done}
      if Args.verbose then {MSG 'Starting remote producer'} end
      thread
	 {Manager apply(url:''
			functor
			define
			   Until
			   {StartActivities Until}
			   !Ready=unit
			   {Wait GlobalStart}
			   {Producer Stream}
			   Until =unit
			   !Done =unit
			end)}
      end
   end

   proc {StartLocalConsumer Stream Ready Done}
      if Args.verbose then {MSG 'Starting local consumer'} end
      thread
	 Ready=unit
	 {Wait GlobalStart}
	 {Consumer Args.'messages' Stream}
	 Done = unit
      end
   end

   AllDone =
   {FoldL RemoteManagers
    fun {$ L Manager}
       Stream RemoteReady RemoteDone LocalReady LocalDone
    in
       {StartRemoteProducer Manager Stream RemoteReady RemoteDone}
       {StartLocalConsumer          Stream  LocalReady  LocalDone}
       {Wait RemoteReady}
       {Wait LocalReady}
       RemoteDone|LocalDone|L
    end nil}

   if Args.verbose then {MSG 'Starting local activities'} end
   LocalUntil
   {StartActivities LocalUntil}

   if Args.verbose then {MSG 'Benchmark begins'} end
   T1 = {Property.get 'time.total'}
   GlobalStart = unit
   {ForAll AllDone Wait}
   LocalUntil  = unit
   T2 = {Property.get 'time.total'}
   if Args.verbose then {MSG 'Benchmark ends'} end

   {MSG 'Total Time = '#(T2-T1)}

   if Args.verbose then {MSG 'Closing remote managers'} end
   {ForAll RemoteManagers proc {$ M} {M close} end}
   
   {Application.exit 0}
end
