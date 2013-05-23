functor

import

   FD

   Search

export
   Return
define


   BillAndCoins = r(6#100  8#25  10#10  1#5  5#1)

   Change =
   {fun {$ BillAndCoins Amount}
       Available    = {Record.map BillAndCoins fun {$ A#_} A end}
       Denomination = {Record.map BillAndCoins fun {$ _#D} D end}
       NbDenoms     = {Width Denomination}
    in
       proc {$ Change}
	  {FD.tuple change NbDenoms 0#Amount Change}
	  {For 1 NbDenoms 1 proc {$ I} Change.I =<: Available.I end}
	  {FD.sumC Denomination Change '=:' Amount}
	  {FD.distribute generic(order:naive value:max) Change}
       end
    end
    BillAndCoins
    142
   }

   ChangeSol =
   [change(1 1 1 1 2)]

   Return=
   fd([change([
	       one(equal(fun {$}
			    {Search.base.one Change}
			 end
			 ChangeSol)
		   keys: [fd])
	       one_entailed(entailed(proc {$}
					{Search.base.one Change _}
				     end)
		   keys: [fd entailed])
	      ])
      ])
   
end


