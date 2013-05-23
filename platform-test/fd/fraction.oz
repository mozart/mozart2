functor

import

   FD

   Search

export
   Return
define



   Fraction = 
   proc {$ Root}
      sol(a:A b:B c:C d:D e:E f:F g:G h:H i:I) = !Root
      BC = {FD.decl}
      EF = {FD.decl}
      HI = {FD.decl}
   in
      Root ::: 1#9
      {FD.distinct Root}
      BC =: 10*B + C
      EF =: 10*E + F
      HI =: 10*H + I 
      A*EF*HI + D*BC*HI + G*BC*EF =: BC*EF*HI
   % impose order
      A*EF >=: D*BC    
      D*HI >=: G*EF
   % redundant constraints
%   3*A >=: BC
%   3*G =<: HI

      {FD.distribute split Root}
   end
   FractionSol =
   [sol(a:9 b:1 c:2 d:5 e:3 f:4 g:7 h:6 i:8)]
Return=
   fd([fraction([
		 all(equal(fun {$} {Search.base.all Fraction} end
			   FractionSol)
		     keys: [fd])
		 all_entailed(entailed(proc {$} {Search.base.all Fraction _} end)
		     keys: [fd scheduling])
		])
      ])
   
end
