%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
   local
      fun {Deref A}
	 case A of suspended(A) then {Deref A} else A end
      end
   in
      fun {Ask S}
	 {Deref {Space.askVerbose S}}
      end
   end

   fun {RawTest P1 P2}
      thread
	 try E={P1} in {P2 E}
	 catch _ then false
	 end
      end
   end
   
in
   
   fun {DoTest T}
      case T
      of test(P1 P2) then
	 {RawTest P1 P2}
      [] equal(P1 X) then
	 {RawTest P1 fun {$ E} E==X end}
      [] entailed(P0) then
	 {RawTest
	  fun {$}
	     S={Space.new proc {$ _}
			     try {P0}
			     catch _ then fail
			     end
			  end}
	  in
	     {Ask S}
	  end
	  fun {$ X} X==succeeded(entailed) end}
      [] failed(P0) then
	 {RawTest
	  fun {$}
	     S={Space.new proc {$ _}
			     try {P0}
			     catch _ then skip
			     end
			  end}
	  in
	     {Ask S}
	  end
	  fun {$ X} X==failed end}
      [] stuck(P0) then
	 {RawTest
	  fun {$}
	     S={Space.new proc {$ _}
			     try {P0}
			     catch _ then fail
			     end
			  end}
	  in
	     {Ask S}
	  end
	  fun {$ X} X==succeeded(stuck) end}
      elsecase {Procedure.arity T}
      of 0 then
	 {RawTest fun {$} {T} true end fun {$ X} X end}
      [] 1 then
	 {RawTest T fun {$ X} X end}
      end
   end
   
end
