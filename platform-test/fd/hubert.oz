% crypto arithmetic
% A/BC + D/EF + G/HI = 1
% A/BC >= D/EF >= G/HI
% all letters are digits between 1 and 9

% redundant constraints (logic consequences)
% 3(A/BC) >= 1,  3(G/HI) =< 1

% Solution: 9/12 + 5/34 + 7/68 = 1
% i.e. sol( a: 9 b: 1 c: 2 d: 5 e: 3 f: 4 g: 7 h: 6 i: 8 )

functor

import

   FD

   Search

export
   Return
define



Hubert =
proc {$ X}
   A B C D E F G H I
   BC = {FD.int 12#98}
   EF = {FD.int 12#98}
   HI = {FD.int 12#98}
in
   X = sol(a:A b:B c:C d:D e:E f:F g:G h:H i:I)
   = {FD.dom 1#9}
   = {FD.distinct}
   BC =: 10*B + C
   EF =: 10*E + F
   HI =: 10*H + I
   A*EF*HI + D*BC*HI + G*BC*EF =: BC*EF*HI
   A*EF >=: D*BC    
   D*HI >=: G*EF

   3*A >=: BC
   3*G =<: HI

   {FD.distribute ff X}
end

HubertSol = [sol(a:9 b:1 c:2 d:5 e:3 f:4 g:7 h:6 i:8)]

Return=

   fd([hubert([
	       one(equal(fun {$} {Search.base.one Hubert} end
			 HubertSol)
		   keys: [fd])
	       all(equal(fun {$} {Search.base.all Hubert} end
			HubertSol)
		  keys: [fd])
	       one_entailed(entailed(proc {$} {Search.base.one Hubert _} end)
		   keys: [fd entailed])
	       all_entailed(entailed(proc {$} {Search.base.all Hubert _} end)
		  keys: [fd entailed])
	      ])
      ])

end
