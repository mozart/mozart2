%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1997, 1998
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


   declare
   Types = [u simple future ext fd bool] % fs]% ofs]

   TTs = {FoldL Types
	  fun {$ TTs T1}
	     {FoldL Types
	      fun {$ TTs T2}
		 T1#T2|TTs
	      end TTs}
	  end nil}
   
   local
      ITs = [fd#fs fd#ofs bool#fs bool#ofs fs#ofs]
   in
      fun {Incompatible T1 T2}
	 {Member T1#T2 ITs} orelse {Member T2#T1 ITs}
      end
   end
   
   CTs = {Filter TTs fun {$ T1#T2}
			{Not {Incompatible T1 T2}}
		     end}
   
   ITs = {Filter TTs fun {$ T1#T2}
			{Incompatible T1 T2}
		     end}
   
   local
      fun {Deref S} case S of suspended(S) then {Deref S} else S end end
   in
      proc {AssertEntailed S}
	 {Deref {Space.askVerbose S}}=succeeded(entailed)
      end
      proc {AssertFailed S}
	 {Space.ask S failed}
      end
   end

% define
   
   fun {MakeVar Type}
      case Type
      of u      then _ 
      [] simple then X Y U in
	 thread {WaitOr X Y} U=unit end Y=unit {Wait U} X
      [] future then {ByNeedFuture proc {$ _} skip end}
      [] ext    then
	 if {System.onToplevel} then
	    X in {Connection.offer X _} X
	 else _
	 end
      [] fd     then {FD.decl}
      [] bool   then {FD.bool}
      [] fs     then {FS.var.bounds 10#20 0#30}
      [] ofs    then X in X^f=_ X    
      [] ct     then raise i_dont_know_how_to_test_this end
      end
   end

   
   {ForAll TTs
    proc {$ T1#T2}
       {Show T1#T2}
       if {Incompatible T1 T2} then
	  if
	     try
		{MakeVar T1}={MakeVar T2} true
	     catch _ then false
	     end
	  then raise failure end
	  end
       else
	  {MakeVar T1}={MakeVar T2}
       end
    end}
   
   {ForAll CTs
    proc {$ T1#T2}
       {Show T1#T2}
       X={MakeVar T1} Y
       S={Space.new proc {$ _} Y={MakeVar T2} X=Y end}
    in
       {AssertEntailed S}
    end}
   
   {ForAll ITs
    proc {$ T1#T2}
       {Show T1#T2}
       X={MakeVar T1} Y
       S={Space.new proc {$ _} Y={MakeVar T2} X=Y end}
    in
       {AssertFailed S}
    end}

   {ForAll CTs
    proc {$ T1#T2}
       {Show T1#T2}
       X={MakeVar T1} Y={MakeVar T2}
       S={Space.new proc {$ _} X=Y end}
    in
       skip
    end}

   {ForAll CTs
    proc {$ T1#T2}
       {Show T1#T2}
       X={MakeVar T1}
       S={Space.new proc {$ Y}
		       Y={MakeVar T2}
		       {Space.new proc {$ _} X=Y end _}
		    end}
    in
       {Delay 50}
       {Space.inject S proc {$ Y} X=Y end}
       {AssertEntailed S}
    end}
   

