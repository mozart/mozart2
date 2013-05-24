functor

import

   FD

   Search

export
   Return
define

   proc {ModDivProb S}
      X3 Y3 Z3 X4 Y4
   in
      S = [X3 Y3 Z3 X4 Y4]
      [X3 Y3 Z3]:::1#100
      thread {FD.modI X3 Y3 Z3} end
      Z3=3
      Y3=10
%	 {Show X3#Y3#Z3}

      [X4 Y4]:::1#100
      thread {FD.divI X4 2 Y4} end
%	 {Show X4#Y4}
      Y4\=:36
      Y4>:2

   end

   Return=
   fd([divmod([
	       one(equal(fun {$}
			    S = {Search.base.one ModDivProb}
			    T = S.1
			 in			    
			    cond {Map T fun {$ E} {FD.reflect.dom E} end}  = 
			       [
				[3#93]
				[10] [3] [6#100]
				[3#35 37#50]
			       ]
			    then 1  else 0 end
			 end
			 1)
		   keys: [fd])
	      ])
      ])
   
end




