% From Hentenryck page 132
% In 5 houses live people from different nations with different professions...

functor

import

   FD

   Search

export
   Return
define

   Houses = 
   proc {$ Vars}
      local N1 N2 N3 N4 N5
	 C1 C2 C3 C4 C5
	 P1 P2 P3 P4 P5
	 A1 A2 A3 A4 A5
	 D1 D2 D3 D4 D5
      in
	 Vars = [N1 N2 N3 N4 N5
		 C1 C2 C3 C4 C5
		 P1 P2 P3 P4 P5
		 A1 A2 A3 A4 A5
		 D1 D2 D3 D4 D5]
	 Vars = {FD.dom  1#5}

	 {FD.distinct [N1 N2 N3 N4 N5]}
	 {FD.distinct [C1 C2 C3 C4 C5]}
	 {FD.distinct [P1 P2 P3 P4 P5]}
	 {FD.distinct [A1 A2 A3 A4 A5]}
	 {FD.distinct [D1 D2 D3 D4 D5]}

	 N1=C2   N2=A1   N3=P1   N4=D3   N5=1
	 D5=3    P3=D1   C1=D4   P5=A4   P2=C3

      % observe that eqpc is domain version!
	 C1 =: C5 + 1

	 thread or N5 =: C4-1 [] N5 =: C4+1 end end
	 thread or A3 =: P4-1 [] A3 =: P4+1 end end
	 thread or A4 =: P2-1 [] A4 =: P2+1 end end
      
	 {FD.distribute ff Vars}
      end
   end

   HousesSol =
   [[5 3 4 2 1 4 5 1 2 3 4 1 5 3 2 3 1 4 2 5 5 1 2 4 3] 
    [5 3 4 2 1 4 5 1 2 3 4 1 5 3 2 3 5 4 2 1 5 1 2 4 3] 
    [5 4 3 2 1 4 5 1 2 3 3 1 5 4 2 4 1 3 2 5 5 1 2 4 3] 
    [5 4 3 2 1 4 5 1 2 3 3 1 5 4 2 4 1 5 2 3 5 1 2 4 3] 
    [5 4 3 2 1 4 5 1 2 3 3 1 5 4 2 4 3 5 2 1 5 1 2 4 3] 
    [5 4 3 2 1 4 5 1 2 3 3 1 5 4 2 4 5 3 2 1 5 1 2 4 3]]

   Return=

   fd([houses([
	       all(equal(fun {$} {Search.base.all Houses} end
			 HousesSol)
		   keys: [fd])
	       all_entailed(entailed(proc {$} {Search.base.all Houses _} end)
		   keys: [fd entailed])
	      ])
      ])

end


