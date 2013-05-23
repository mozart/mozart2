%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
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
%%%

local
   fun {AppendAll Xss}
      {FoldR Xss Append nil}
   end

   fun {IsIn Is Js}
      %% Is is contained in Js
      case Js of nil then false
      [] _|Jr then
	 {List.isPrefix Is Js} orelse {IsIn Is Jr}
      end
   end

   fun {IsNotIn Is Js}
      {Not {IsIn Is Js}}
   end

   fun {MakeTestEngine AllKeys AllTests}

      functor

      import
	 Property
	 System
	 Debug at 'x-oz://boot/Debug'
	 Module
	 Space
	 OS(getPID)
	 Open(file)

      export
	 Run

      define
	 fun {X2V X}
	    {Value.toVirtualString X 100 100}
	 end

	 \insert 'engine.oz'
	 \insert 'compute-tests.oz'

	 fun {Run Argv}
	    if Argv.help then
	       {System.printInfo \insert 'help-string.oz'
	       }
	       0
	    else
	       ToRun={ComputeTests Argv}
	       proc {PV V}
		  if Argv.verbose then {System.printInfo V}
		  else skip end
	       end

	       proc {PT Ts}
		  if Argv.verbose then
		     {ForAll Ts
		      proc {$ T}
			 {System.printInfo
			  ({X2V {Label T}} # ':\n     file: ' #
			   {X2V T.file} # ':' #
			   {X2V T.line} # ')\n')}
		      end}
		  else
		     fun {ChunkUp Xs}
			Ys Zs
		     in
			{List.takeDrop Xs 3 ?Ys ?Zs}
			Ys|if Zs==nil then nil else {ChunkUp Zs} end
		     end
		  in
		     {ForAll {ChunkUp Ts}
		      proc {$ Ts}
			 {System.printInfo '   '}
			 {ForAll Ts
			  proc {$ T}
			     {System.printInfo {X2V {Label T}} # ', '}
			  end}
			 {System.showInfo ''}
		      end}
		  end
	       end

	       %%
	       ProcStat =
	       if Argv.memory \= nil then
		  try
		     Fn = "/proc/"#{Int.toString {OS.getPID}}#"/stat"
		  in
		     {New Open.file init(name:Fn flags:[read])}
		  catch _ then
		     unit
		  end
	       else unit
	       end

	       %%
	       fun {InitProfData}
		  Acc = {Cell.new nil}
		  proc {PrintField FieldSet Units Then Now Factor C#F}
		     if {Member C FieldSet} then
			{PV ' '#[C]#':'#((Now.F-Then.F) div Factor)#Units}
		     else skip
		     end
		  end
	       in
		  %% time;
		  if Argv.time \= nil then
		     C
		     TimeStart = {Cell.new unit}
		     TimeStop = {Cell.new unit}
		     MeasureFun = fun {$} {Property.get time} end
		     TimeRec =
		     time(start: proc{$}
				    {Cell.assign TimeStart {MeasureFun}}
				 end
			  stop:  proc{$}
				    {Cell.assign TimeStop {MeasureFun}}
				 end
			  print: proc {$}
				    B = {Cell.access TimeStart}
				    E = {Cell.access TimeStop}
				    proc {PrintTimeField Arg}
				       {PrintField Argv.time ' ms' B E 1 Arg}
				    end
				 in
				    {PV ' ('}
				    {ForAll
				     [&r#run &g#gc &s#system &c#copy
				      &p#propagate &t#total]
				     PrintTimeField}
				    {PV ' )'}
				 end)
		  in
		     {Cell.exchange Acc C time#TimeRec|C}
		     {Property.put 'time.detailed' true}
		  else skip
		  end

		  %% memory;
		  if Argv.memory \= nil then
		     C
		     MemoryStart = {Cell.new unit}
		     MemoryStop = {Cell.new unit}
		     MeasureFun = fun {$}
				     {For 1 {Property.get 'gc'}.codeCycles 1
				      proc {$ _} {System.gcDo} end}
				     %%
				     {List.foldL
				      [{Property.get 'gc'}
				       {Property.get 'memory'}
				       if ProcStat \= unit then
					  {ProcStat seek()}
					  PStat = {ProcStat read(list:$)}
					  VMem =
					  {String.toInt
					   {List.nth
					    {String.tokens PStat & } 23}}
				       in
					  vmem(vmem: VMem)
				       else
					  vmem
				       end]
				      fun {$ I E} {Record.adjoin E I} end
				      memory}
				  end
		     MemoryRec =
		     memory(start: proc {$}
				      {Cell.assign MemoryStart {MeasureFun}}
				   end
			    stop:  proc {$}
				      {Cell.assign MemoryStop {MeasureFun}}
				   end
			    print: proc {$}
				      B = {Cell.access MemoryStart}
				      E = {Cell.access MemoryStop}
				      proc {PrintMemoryField Arg}
					 {PrintField
					  Argv.memory ' kb' B E 1024 Arg}
				      end
				      VLetter =
				      if ProcStat \= unit then &v
				      else 0
				      end
				   in
				      {PV ' ('}
				      {ForAll
				       [VLetter#vmem &h#active &a#atoms
					&c#code &f#freelist &n#names]
				       PrintMemoryField}
				      {PV ' )'}
				   end)
		  in
		     {Cell.exchange Acc C memory#MemoryRec|C}
		  else skip
		  end

		  %%
		  {Record.adjoinList profInfo {Cell.access Acc}}
	       end

	       proc {StartProfiling ProfData}
		  {Record.forAll ProfData proc {$ E} {E.start} end}
	       end
	       proc {StopProfiling ProfData}
		  {Record.forAll ProfData proc {$ E} {E.stop} end}
	       end

	       proc {PrintProfData ProfData}
		  {Record.forAll ProfData proc {$ E} {E.print} end}
	       end

	    in
	       if Argv.'do' then
		  %% Start garbage collection thread, if requested
		  StopGcThread
		  if Argv.gc > 0 then
		     proc {GcLoop}
			if {Value.isDet StopGcThread} then skip
			else {System.gcDo} {Delay Argv.gc} {GcLoop}
			end
		     end
		  in
		     thread {GcLoop} end
		  else skip
		  end

		  %%
		  GlobalProfile = {InitProfData}
		  {StartProfiling GlobalProfile}
		  %%
		  LocalProfile = {InitProfData}

		  %% go for it;
		  Results = {Map ToRun
			     fun {$ T}
				Bs Bs1 Bs2 B
			     in
				{StartProfiling LocalProfile}

				%%
				if Argv.memory \= nil then
				   %%
				   {PV '>' # {Label T} # ': '}
				   Bs1 =
				   [thread B1 in %% just one iteration;
				       B1 = {DoTest T.script}
				       {PV if B1 then '+' else '-' end}
				       B1
				    end]
				   {Wait Bs1.1}
				   %%
				   {StopProfiling LocalProfile}
				   {PrintProfData LocalProfile}
				   {PV '\n:'}
				   %%
				   {StartProfiling LocalProfile}
				else
				   Bs1 = nil
				end

				{PV {Label T} # ': '}
				Bs2 =
				{Map {MakeList Argv.threads}
				 fun {$ _}
				    thread
				       {ForThread 1 Argv.repeat 1
					fun {$ B _}
					   if B then B1 in
					      B1 = {DoTest T.script}
					      {PV if B1 then '+' else '-' end}
					      {Time.delay Argv.delay}
					      B1
					   else false
					   end
					end true}
				    end
				 end}

				%%
				Bs = {Append Bs1 Bs2}
				B = {FoldL Bs And true}
				{Wait B}

				%%
				{StopProfiling LocalProfile}
				{PrintProfData LocalProfile}

				%%
				{PV '\n'}
				{AdjoinAt T result B}
			     end}
		  Goofed = {Filter Results fun {$ T}
					      {Not T.result}
					   end}
	       in
		  {Wait Goofed}
		  StopGcThread = unit

		  %%
		  {StopProfiling GlobalProfile}
		  {PV 'Total: '}
		  {PrintProfData GlobalProfile}
		  {PV '\n'}

		  %%
		  if Goofed==nil then
		     if Argv.verbose then
			{System.showInfo \insert 'passed.oz'
			}
		     else
			{System.showInfo 'PASSED'}
		     end
		     0
		  else
		     if Argv.verbose then
			{System.showInfo \insert 'failed.oz'
			}
		     else
			{System.showInfo 'FAILED'}
		     end
		     {System.showInfo ''}
		     {System.showInfo 'The following test failed:'}
		     {PT Goofed}
		     1
		  end
	       else
		  %% Only print tests to be performed
		  {System.showInfo 'TESTS FOUND:'}
		  {PT ToRun}
		  {System.showInfo ''}
		  0
	       end
	    end
	 end
	 
      end
   end

   TestOptions =
   record('do'(rightmost type: bool default: true)
	  help(rightmost char: [&h &?] type: bool default: false)
	  usage(alias: help)
	  verbose(rightmost char: &v type: bool default: false)
	  quiet(char: &q alias: verbose#false)
	  gc(rightmost type: int(min: 0) default: 0)
	  ignores(multiple type: list(string) default: nil)
	  keys(multiple type: list(string) default: nil)
	  tests(multiple type: list(string) default: nil)
	  time(single type: string default: "")
	  memory(single type: string default: "")
	  threads(rightmost type: int(min: 1) default: 1)
	  repeat(rightmost type: int(min: 1) default: 1)
	  delay(rightmost type: int(min: 0) default: 0))

in
   functor

   import
      System
      Application
      Module
      Pickle
      OS(getEnv putEnv)

   define

      Argv = {Application.getCmdArgs
	      record(verbose(rightmost type: bool default: false))}
       
      fun {X2V X}
	 {Value.toVirtualString X 100 100}
      end

      fun {GetAll S Ids Ls}
	 LL = {Label S}
	 LS = {Atom.toString LL}
	 L  = if Ls==nil then LS else {Append Ls &_|LS} end
      in
	 if {Width S}==1 andthen {IsList S.1} then
	    {AppendAll
	     {Map S.1 fun {$ S}
			 {GetAll S {Append Ids [LL]} L}
		      end}}
	 else [L # {Append Ids [LL]} # {CondSelect S keys nil}]
	 end
      end

      ModMan = {New Module.manager init}
       
      Tests = {AppendAll
	       {Map Argv.1 fun {$ C}
			      S = {ModMan link(url:C $)}.return
			   in
			      {Map {GetAll S nil nil}
			       fun {$ T#Id#K}
				  L={String.toAtom T}
			       in
				  L(id:Id keys:K url:{String.toAtom C})
			       end}
			   end}}
       
      Keys = {Sort {FoldL Tests
		    fun {$ Ks T}
		       {FoldL T.keys
			fun {$ Ks K}
			   if {Member K Ks} then Ks else K|Ks end
			end Ks}
		    end nil}
	      Value.'<'}
       
      fun {ChunkUp Xs}
	 Ys Zs
      in
	 {List.takeDrop Xs 6 ?Ys ?Zs}
	 Ys|if Zs==nil then nil else {ChunkUp Zs} end
      end
       
   in
      if Argv.verbose then
	 {System.showInfo 'TESTS FOUND:'}
	 {ForAll Tests proc {$ T}
			  {System.showInfo
			   ({X2V {Label T}} # ':\n' #
			    '   keys:  ' # {X2V T.keys} # '\n')}
		       end}
	 {System.showInfo '\n\nKEYS FOUND:'}
	 {ForAll {ChunkUp Keys}
	  proc {$ Ks}
	     {System.printInfo '   '}
	     {ForAll Ks
	      proc {$ K}
		 {System.printInfo {X2V K} # ', '}
	      end}
	     {System.showInfo ''}
	  end}
      end
       
      local
	 Engine = {MakeTestEngine Keys Tests}
	 OZPATH = {OS.getEnv 'OZPATH'}
      in
	 {Pickle.saveWithHeader
	  functor
	  import
	     Module(manager)
	     Application(getCmdArgs exit)
	     OS(getEnv putEnv)
	  define
	     ModMan = {New Module.manager init}
	     Args = {Application.getCmdArgs TestOptions}
	     {OS.putEnv 'OZPATH' {OS.getEnv 'OZPATH'}#OZPATH}
	     {Application.exit {{ModMan apply(url:'' Engine $)}.run
				Args}}
	  end
	  './oztest'

	  '#!/bin/sh\nexec ozengine $0 "$@"\n'
	  9}
	  
	 {Pickle.save
	  Engine
	  './te.ozf'}
      end
       
      {Application.exit 0}

   end

end
