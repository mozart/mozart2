%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
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

functor

export Return
define
   Return =
   type([basic(
	       proc {$}
		  Cases = [ atom(a IsAtom) int(1 IsInt) float(1.0 IsFloat)
			    tuple(a(1) IsTuple) record(a(a:1) IsRecord)
			  ]
	       in
		  {ForAll Cases
		   proc {$ C}
		      %% Type of
		      {Value.type C.1}={Label C}
		      %% IsT
		      {C.2 C.1}=true
		      %% IsT with thread
		      local
			 X
		      in
			 thread X=C.1 end
			 {C.2 X}=true
		      end
		   end
		  }
	       end
	       keys:[module type basic])

	 isString(proc {$}
		     {IsString a false}
		     {IsString [10 2378] false}
		     {IsString [a b c] false}
		  
		     {IsString "test" true}
		     {IsString nil true}
			   
		  end
		  keys:[module type string])

	 isStringSusp(proc {$}
			 X Y Sync in
			 thread {IsString [10 X] Y} Sync=unit end
			 {IsFree Y true} X=1 Y=true
			 {Wait Sync}
		      end
		      keys:[module type string])

	 isStringSuspInt(proc {$}
			    X Y Sync in
			    thread {IsString X Y} Sync=unit end
			    {IsFree Y true} X=1 Y=false
			    {Wait Sync}
			 end
			 keys:[module type type string])


	 isStringSuspAtom(proc {$}
			     X Y Sync in
			     thread {IsString [10 X] Y} Sync=unit end
			     {IsFree Y true} X=a Y=false
			     {Wait Sync}
			  end
			  keys:[module type type string])
	])
end
