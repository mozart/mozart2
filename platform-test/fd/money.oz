functor

import

   FD

   Search

export
   Return
define

   proc {Money SOL}
      local
	 [S E N D M O R Y] = !SOL
	 C1 C2 C3 C4
      in
	 SOL = {FD.dom 0#9}
	 [C1 C2 C3 C4] = {FD.dom 0#1}
	 M\=:0 S\=:0
	 {FD.distinct SOL}
	 D+E     =: Y+10*C1
	 N+R+C1  =: E+10*C2
	 E+O+C2  =: N+10*C3
	 S+M+C3  =: O+10*C4
	 C4 = M 
      end
      {FD.distribute ff SOL}
   end
   
   MoneySol = [[9 5 6 7 1 0 8 2]]

   proc {Donald SOL}
      local
	 [D O N A L G E R B T] = !SOL
	 C1 C2 C3 C4 C5
      in
	 SOL = {FD.dom 0#9}
	 [C1 C2 C3 C4 C5] = {FD.dom 0#1}
	 {FD.distinct SOL}
	 D+D    =: T+10*C1
	 L+L+C1 =: R+10*C2
	 A+A+C2 =: E+10*C3
	 N+R+C3 =: B+10*C4
	 O+E+C4 =: O+10*C5
	 D+G+C5 =: R
      end
      {FD.distribute ff SOL}
   end

   DonaldSol = [[5 2 6 4 8 1 9 7 3 0]]
Return=
   fd([money([
	      one(equal(fun {$} {Search.base.one Money} end MoneySol)
		  keys: [fd])
	      all(equal(fun {$} {Search.base.all Money} end MoneySol)
		  keys: [fd])
	      one_entailed(entailed(proc {$} {Search.base.one Money _} end)
		  keys: [fd entailed])
	      all_entailed(entailed(proc {$} {Search.base.all Money _} end)
		  keys: [fd entailed])
	     ])
       donald([
	       one(equal(fun {$} {Search.base.one Donald} end DonaldSol)
		   keys: [fd])
	       all(equal(fun {$} {Search.base.all Donald} end DonaldSol)
		   keys: [fd])
	       one_entailed(entailed(proc {$} {Search.base.one Donald _} end)
			    keys: [fd entailed])
	       all_entailed(entailed(proc {$} {Search.base.all Donald _} end)
			    keys: [fd entailed])
	      ])
      ])
end
