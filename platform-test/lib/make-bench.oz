%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Contributors:
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%   Michael Mehl, 1998
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
   TimeMap = [&t#total &r#run &g#gc &c#copy
	      &p#propagate &s#system]

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

   local
      fun {MakeInit As I}
	 case As of nil then nil
	 [] A|Ar then A#I|{MakeInit Ar I}
	 end
      end
   in
      fun {MakeRecordInit L As I}
	 {List.toRecord L {MakeInit As I}}
      end
   end

   % Vector Arithmetic
   fun {VectorOp V1 V2 Op}
      {Record.zip V1 V2 fun {$ I J} {Op I J} end}
   end
   fun {VectorAdd V1 V2} {VectorOp V1 V2 Number.'+'} end

   % format float as fixnum: I.ff
   fun {Truncate F}
      I={Float.toInt F}
   in
      if {Int.toFloat I}>F then I-1 else I end
   end
	 
   fun {Average Result}
      N = {Width Result}
      NF = {Int.toFloat N}
      Sum = {ForThread 1 {Width Result} 1
	     fun {$ Tmp I}
		{VectorAdd Result.I Tmp}
	     end
	     {MakeRecordInit time {Arity Result.1} 0.0}}
   in
      {Record.map Sum fun {$ I} I/NF end}
   end

   fun {Sqr X} X*X end

   %% The Variance of n measurements Xi is computed as
   %% square root of the sum of (Xi-Xav)^2 divided by (n-1)
   %% normalized to the average Xav
   fun {Variance Av Result}
      N = {Width Result}
      NF = {Int.toFloat N-1}
      Sum={ForThread 1 N 1
	   fun {$ Tmp I}
	      Delta={VectorOp Result.I Av
		     fun {$ I J} {Sqr I-J} end}
	   in
	      {VectorAdd Delta Tmp}
	   end
	   {MakeRecordInit time {Arity Av} 0.0}}
   in
      {Record.mapInd Sum fun {$ F I}
			    if Av.F > 1.0 then
			       {Sqrt I/NF}/Av.F
			    else
			       0.0
			    end
			 end}
   end

   % print float
   fun {PF F}
      I={Truncate F}
      Mat = {Truncate 100.0*(F-{Int.toFloat I})}
   in
      I#'.'#Mat
   end

   fun {MakeTestEngine AllKeys AllTests}

      functor

      import
	 Space
	 Property
	 System
	 Debug at 'x-oz://boot/Debug'
	 Module

      export
	 Run

      define
	 \insert 'engine.oz'
	 \insert 'compute-tests.oz'

	 fun {ComputeMinTime T0 TMin Test}
	    {Test _}
	    local
	       T1={Property.get time}
	    in
	       (TMin div (T1.total - T0.total)) + 1
	    end
	 end

	 fun {Run Argv}
	    if Argv.help then
	       {System.printInfo \insert 'help-bench.oz'
	       }
	       0
	    else
	       Repeat = Argv.repeat
	       ToRun={ComputeTests Argv}
	       proc {PI V}
		  {System.printInfo V}
	       end
	       proc {PV V}
		  if Argv.verbose then {PI V} end
	       end
	       fun {DiffTime T0 T1 N}
		  NF={Int.toFloat N}
	       in
		  {ForAll TimeMap
		   proc {$ C#F}
		      {PV ' '#[C]#':'#(T1.F-T0.F) div N#'ms'}
		   end}
		  {PV '\n'}
		  {Record.zip T0 T1
		   fun {$ I J}
		      if {IsInt J} then {Int.toFloat J-I}/NF
		      else 0.0 end end}
	       end
	       %% Start garbage collection thread, if requested
	       if Argv.gc > 0 then
		  proc {GcLoop}
		     {System.gcDo} {Delay Argv.gc} {GcLoop}
		  end
	       in
		  thread {GcLoop} end
	       end
	       %% Go for it
	       
	       {Property.put 'time.detailed' Argv.detailed}

	       % StartTime = {Property.get time}
	    in
	       {ForAll ToRun
		proc {$ T}
		   Result={MakeTuple time Repeat}
		   proc {Test _}
		      {For 1 T.repeat 1
		       proc {$ _}
			  {Wait {DoTest T.script}}
		       end}
		   end
		in
		   {PI {Label T}#':\n'}
		   local
		      {System.gcDo}
		      {System.gcDo}
		      {System.gcDo}
		      {System.gcDo}
		      T0 = {Property.get time}
		      N={ComputeMinTime T0 Argv.mintime Test}
		      {PV '(#'#N#')\n'}
		   in
		      {For 1 Repeat 1
		       proc {$ I}
			  {System.gcDo}
			  {System.gcDo}
			  {System.gcDo}
			  {System.gcDo}
			  T0={Property.get time}
			  {For 1 N 1 Test}
			  T1={Property.get time}
		       in
			  Result.I={DiffTime T0 T1 N*T.repeat}
		       end}
		   end
		   {PV '-------------------------\n'}
		   local
		      Av = {Average Result}
		      Var={Variance Av Result}
		   in
		      {PI ' times (ms):'}
		      {ForAll TimeMap
		       proc {$ C#F}
			  {PI ' '#[C]#':'#{PF Av.F}}
			  if Var.F > 0.1 then {PI '*'} end
		       end}
		      {PI '\n'}
		      if Argv.variance then
			 {PI '    var (%):'}
			 {ForAll TimeMap
			  proc {$ C#F}
			     {PI ' '#[C]#':'#{Truncate Var.F*100.0}}
			  end}
			 {PI '\n'}
		      end
		   end
		   {PV '=========================\n'}
		end}
	       0
	    end
	 end
      end
   end

   TestOptions =
   record(
      help(rightmost char: [&h &?] type: bool default: false)
      usage(alias: help)
      detailed(rightmost type:bool default:false)
      gc(rightmost type: int(min: 0) default: 0)
      ignores(multiple type: list(string) default: nil)
      keys(multiple type: list(string) default: nil)
      tests(multiple type: list(string) default: nil)
      repeat(rightmost type: int(min: 2) default: 5)
      mintime(rightmost type: int default: 2000)
      verbose(rightmost char: &v type: bool default: false)
      quiet(char: &q alias: verbose#false)
      variance(rightmost type: bool default: false)
      )
   
in
   functor

   import
      System
      Application
      Module
      Pickle
       
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
	 else
	    if {HasFeature S bench} then
	       [L # {Append Ids [LL]} # {CondSelect S keys nil} # S.bench]
	    else nil
	    end
	 end
      end

      ModMan = {New Module.manager init}
       
      Tests = {AppendAll
	       {Map Argv.1 fun {$ C}
			      S = {ModMan link(url:C $)}.return
			   in
			      {Map {GetAll S nil nil}
			       fun {$ T#Id#K#R}
				  L={String.toAtom T}
			       in
				  L(id:Id
				    keys:K
				    url:{String.toAtom C}
				    repeat:R
				   )
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
      in
	 {Pickle.saveWithHeader

	  functor
	  import Module Application
	  define

	     ModMan = {New Module.manager init}
	      
	     Args = {Application.getCmdArgs TestOptions}
	      
	     {Application.exit {{ModMan apply(url:'' Engine $)}.run Args}}
	  end
	  './ozbench'
	  '#!/bin/sh\nexec ozengine $0 "$@"\n'
	  9}

      end
       
      {Application.exit 0}

   end

end


