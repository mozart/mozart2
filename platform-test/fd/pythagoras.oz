functor

import

   FD

   Search

export
   Return
define

   Pythagoras = 
   proc {$ Root}
      proc {Square X S}
	 {FD.times X X S}     % exploits coreference
      end
      [A B C] = Root
      AA BB CC
   in
      Root ::: 1#1000
AA	     = {Square A}
      BB      = {Square B}
      CC      = {Square C}
      AA + BB =: CC           % A*A + B*B =: C*C propagates much worse
      A =<: B
      B =<: C
      2*BB >=: CC             % redundant constraint
      {FD.distribute ff Root}
   end

   PythagorasSol = [[3 4 5]]

   Return=
   fd([pythagoras([
		   one(equal(fun {$} {Search.base.one Pythagoras} end
			     PythagorasSol)
		       keys: [fd])
		   one_entailed(entailed(proc {$} {Search.base.one Pythagoras _} end)
				keys: [fd entailed])
		  ])
      ])

end
