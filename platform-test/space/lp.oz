%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Contributor:
%%%   Peter Van Roy <pvr@info.ucl.ac.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1999
%%%   Peter Van Roy, 1999
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

export
   Return

import
   Search

define

   proc {Skip} skip end

   proc {AppOr Xs Ys Zs}
      or Xs=nil Zs=Ys               then {Skip}
      [] X Xr Zr in Xs=X|Xr Zs=X|Zr then {AppOr Xr Ys Zr}
      end
   end

   proc {AppDis Xs Ys Zs}
      dis Xs=nil Zs=Ys               then {Skip}
      []  X Xr Zr in Xs=X|Xr Zs=X|Zr then {AppDis Xr Ys Zr}
      end
   end
   
   proc {AppDisDeep Xs Ys Zs}
      dis Xs=nil Zs=Ys               
      []  X Xr Zr in Xs=X|Xr Zs=X|Zr {AppDis Xr Ys Zr}
      end
   end
   
   Xs={List.number 1 1000 1}

   proc {DisInts N Xs}
      dis N = 0 Xs = nil
      [] Xr in  
	 N > 0 = true Xs = N|Xr then
	 {DisInts N-1 Xr}
      end  
   end 

   proc {OrInts N Xs}
      or N = 0 Xs = nil
      [] Xr in  
	 N > 0 = true Xs = N|Xr
	 {OrInts N-1 Xr}
      end  
   end 

   local  
      proc {Sum3 Xs N R}
	 or Xs = nil R = N
	 [] X|Xr = Xs in 
	    {Sum3 Xr X+N R}
	 end 
      end 
   in
      proc {OrSum Xs R}
	 {Sum3 Xs 0 R}
      end 
   end

   Return=
   lp([append(['dis'(entailed(proc {$}
				 {AppDis Xs nil _}
				 {AppDis _  nil Xs}
				 {AppDis Xs nil Xs}
			      end)
		     keys: [lp space 'dis'])
	       'deepdis'(equal(fun {$}
			          {Search.base.all 
                                   proc {$ A}
                                      X#Y=A 
                                   in 
                                      {AppDisDeep X Y [1 2 3 4]} 
                                   end}
                               end
                               [nil#[1 2 3 4] [1]#[2 3 4]
                                [1 2]#[3 4] [1 2 3]#[4]
                                [1 2 3 4]#nil])
                         keys: ['dis' 'bug' 'append' 'merge'])
	       'or'(entailed(proc {$}
				{AppOr Xs nil _}
				{AppOr _  nil Xs}
				{AppOr Xs nil Xs}
			     end)
		    keys: [lp space 'or'])])
       sum(['dis'(entailed(proc {$}
			      N S X
			   in
			      thread {DisInts N S} end 
			      thread {OrSum S X}  end
			      N=10
			      {Wait X}
			      X=55
			   end)
		     keys: [lp space 'dis'])
	    'or'(entailed(proc {$}
			     N S X
			  in
			     thread {OrInts N S} end 
			     thread {OrSum S X}  end
			     N=10
			     {Wait X}
			     X=55
			  end)
		    keys: [lp space 'or'])])])
end

