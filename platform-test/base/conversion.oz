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

import
   System
export
   Return
define
   Return=
   conversion([

	       stringToFloat(
			     proc {$}
				D1 = ["0.1" "0.1e1" "~0.1" "~1." "0.1E5"]
				D2 = [0.1 0.1e1 ~0.1 ~1. 0.1E5]
				D3 = ['0.1' '0.1e1' '~0.1' '~1.' '0.1E5']
			     in
				case {Map D1 String.toFloat}
				of !D2 then skip end
				case {Map D1 String.toAtom}
				of !D3 then skip end
			     end
			     keys:[module conversion string float])


	       stringToAtom(
			    proc {$}
			       Sync
			       X Y in
			       thread {String.toAtom X Y} Sync=unit end
			       X="aa" Y='aa'
			       {Wait Sync}
			    end
			    keys:[module conversion string atom])
	       stringToAtom(
			    proc {$}
			       Sync X Y in
			       thread {String.toAtom [65 X] Y} Sync=unit end
			       X=65 Y='AA'
			       {Wait Sync}
			    end
			    keys:[module conversion string atom])
		  
	       stringToInt(proc {$}
			      D1 = [ "1" "0" "~1"
				     "10000000000000000"
				     "~10000000000000000" ]
			      D2 = [ 1 0 ~1 10000000000000000
				     ~10000000000000000 ]
			   in
			      case {Map D1 String.toInt} of !D2 then skip end
			   end
			   keys:[module conversion string int])

	       floatToString(proc {$}
				D3 = [ 1. 1.0 ~1.0 1.0e3 1.0e~4]
			     in
				{Map D3 Float.toString _}
			     end
			     keys:[module conversion float string])

	       noFloat(proc {$}
			  D2 = [ "0" "0e0" "0.0e0.0" "-0.0" "+0.0" "0.1e+1"
				 "0.1e" ".0" "0.1e-1" "a" ]
		       in
			  {ForAll D2 proc {$ X}
					try
					   {String.toFloat X _}
					catch
					   error(kernel(stringNoFloat _) ...)
					then skip
					end
				     end}
			  {Map D2 String.toAtom _}
		       end
		       keys:[module conversion float])

	       noFloatType(proc {$}
			 D4 = [ ~1 a {NewName} f(a) f(a:b) System.show]
		      in
			 {ForAll D4 proc {$ X}
				       try
					  {Float.toString X _}
				       catch error(kernel(type ...) ...) then
					  skip
				       end
				    end}
		      end
		       keys:[module conversion float type])

	      ])
end

