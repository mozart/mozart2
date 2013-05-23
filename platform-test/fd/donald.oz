functor

import

   FD

   Search

export
   Return
define

   Money = 
   proc {$ Root}
      S E N D M O R Y
   in
      Root = sol(s:S e:E n:N d:D m:M o:O r:R y:Y)
      Root ::: 0#9
      {FD.distinct Root}
      S \=: 0 
      M \=: 0
      1000*S + 100*E + 10*N + D
      +            1000*M + 100*O + 10*R + E
      =: 10000*M + 1000*O + 100*N + 10*E + Y
      {FD.distribute ff Root}
   end

   MoneySol = [sol(d:7 e:5 m:1 n:6 o:0 r:8 s:9 y:2)]
	  
   Donald =
   proc {$ Root}
      sol(a:A b:B d:D e:E g:G l:L n:N  o:O r:R t:T) = Root
   in
      Root ::: 0#9
      {FD.distinct Root}
      D\=:0  R\=:0  G\=:0
      100000*D + 10000*O + 1000*N + 100*A + 10*L + D
      +  100000*G + 10000*E + 1000*R + 100*A + 10*L + D
      =: 100000*R + 10000*O + 1000*B + 100*E + 10*R + T
      {FD.distribute ff Root}
   end

   DonaldSol =
   [sol(a:4 b:3 d:5 e:9 g:1 l:8 n:6 o:2 r:7 t:0)]
Return=
   fd([
       donald([all_one_equation(equal(fun {$}
					 {Search.base.all Donald}
				      end
				      DonaldSol)
				keys: [fd])
	      ])
       money([all_one_equation(equal(fun {$}
					{Search.base.all Money}
				     end
				     MoneySol)
			       keys: [fd])
	     ])
       donald_entailed([all_one_equation(entailed(proc {$}
					 {Search.base.all Donald _}
				      end)				keys: [fd entailed])
		       ])
       money_entailed([all_one_equation(entailed(proc {$}
						    {Search.base.all Money _}
						 end)
			       keys: [fd entailed])
	     ])
      ])
   
end
