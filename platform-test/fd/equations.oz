functor

import

   FD

   Search

export
   Return
define


   EqSol1 = [3]
   EqSol2 = [7#5#2]

Return=
   fd([equations([
		  test1(equal(fun {$}
				 {Search.base.one proc{$ X} X :: 1#10 27 =: X*X*X
					       {FD.distribute ff [X]} end}
			      end
			      EqSol1)
			keys: [fd])
		  test2(equal(fun {$}
				 {Search.base.one proc{$ S} X Y Z in
					       S = X#Y#Z 
					       [X Y Z] = {FD.dom 1#10 }
					       176 =: X*X + Y*Y*Y + Z   
					       {FD.distribute split [X Y Z]} 
					    end}
			      end
			      EqSol2)
			keys: [fd])

		  test1_entailed(entailed(proc {$}
				 {Search.base.one proc{$ X} X :: 1#10 27 =: X*X*X
					       {FD.distribute ff [X]} end _}
			      end)
			keys: [fd entailed])
		  test2_entailed(entailed(proc {$}
				 {Search.base.one proc{$ S} X Y Z in
					       S = X#Y#Z 
					       [X Y Z] = {FD.dom 1#10 }
					       176 =: X*X + Y*Y*Y + Z   
					       {FD.distribute split [X Y Z]} 
					    end _}
			      
			      end)
			keys: [fd entailed])
		 ])
      ])
   
end
