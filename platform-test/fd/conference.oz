functor

import

   FD

   Search

export
   Return
define


   Data = data(
	       nbSessions: 11
	       nbParSessions: 3
	       constraints:
		  [ before(4 11)
		    before(5 10)
		    before(6 11)
		    disjoint(1 [2 3 5 7 8 10])
		    disjoint(2 [3 4 7 8 9 11])
		    disjoint(3 [5 6 8])
		    disjoint(4 [6 8 10])
		    disjoint(6 [7 10])
		    disjoint(7 [8 9])
		    disjoint(8 [10]) ]
	      )

   Conference =
   {fun {$ Data}
       NbSessions    = Data.nbSessions
       NbParSessions = Data.nbParSessions
       Constraints   = Data.constraints
       MinNbSlots    = NbSessions div NbParSessions
    in
       proc {$ Plan}
	  NbSlots  = {FD.int MinNbSlots#NbSessions}
       in
	  {FD.distribute naive [NbSlots]}
      % Plan: Session --> Slot
	  {FD.tuple plan NbSessions 1#NbSlots Plan} 
      % at most NbParSessions per slot
	  {For 1 NbSlots 1  
	   proc {$ Slot} {FD.atMost NbParSessions Plan Slot} end}
      % impose Constraints
	  {ForAll Constraints
	   proc {$ C}
	      case C
	      of before(X Y) then Plan.X <: Plan.Y
	      [] disjoint(X Ys) then
		 {ForAll Ys proc {$ Y} Plan.X \=: Plan.Y end}
	      end
	   end}
	  {FD.distribute ff Plan}
       end
    end
    Data}

   ConferenceSol =
   [plan(1 2 3 1 2 2 3 4 1 3 4)]


   Return=
   fd([conference([
		   one(equal(fun {$}
				{Search.base.one Conference}
			     end
			     ConferenceSol)
		       keys: [fd])
		   one_entailed(entailed(proc {$}
					    {Search.base.one Conference _}
					 end)
		       keys: [fd entailed])
		  ])
      ])
end
