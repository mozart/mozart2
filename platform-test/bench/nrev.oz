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
   Property(get)
export
   Return

define

   proc {Nrev L L1}
      case L of
	 H|R then {App {Nrev R} H|nil L1}
      [] nil then L1=nil
      end
   end

   proc {App X Y Z}
      case X of
	 H|R then local Z1 in Z=H|Z1 {App R Y Z1} end
      [] nil then  Y=Z
      end
   end

   proc {NList N L}
      case N of
	 0  then L=nil
      else  L=N|{NList N-1}
      end
   end

   Data = {NList 30}


   proc {RepeatBench N}
      case N of
	 0 then skip
      else {Nrev Data _}
	 {RepeatBench N-1}
      end
   end


   proc {Dummy N}
      case N of
	 0 then skip
      else {Dummy N-1}
      end
   end

   fun {Dobench Count}
      T1 = {Property.get time}.user
      {Dummy Count} 
      T2 = {Property.get time}.user
      {RepeatBench Count}
      T3 = ({Property.get time}.user - T2) - ( T2 - T1)
      Lips = (496000*Count) div T3
   in
      Lips
   end

   Return = nrev(proc {$}
		    _={Dobench 10000}
		 end
		 keys:[bench naive reverse nrev]
		 bench:1)
end
