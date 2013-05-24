functor

import

   FD

   Search

export
   Return
define



   Grocery =

   proc {$ Root}
      A#B#C#D = Root
      S       = 711
   in
      Root ::: 0#711
      A*B*C*D =: S*100*100*100
	       
      A+B+C+D =: S
           % eliminate symmetries
      D =: 79*{FD.decl}  % 79 is prime factor of S=711
      B =<: C
      C =<: D 
      A =<: B
      {FD.distribute generic(value:splitMax) Root}
	       
   end

   GrocerySol =
   [120#125#150#316]

Return=

   fd([grocery([
		one(equal(fun {$} {Search.base.one Grocery} end
			  GrocerySol)
		    keys: [fd])
		one_entailed(entailed(proc {$} {Search.base.one Grocery _} end)
		    keys: [fd entailed])
	       ])
      ])

end



