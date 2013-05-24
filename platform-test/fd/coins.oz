functor

import
   FD
   Search

export
   Return

define

   fun {CoinsTotal PocketCoins Total}
      Coins coins(1:P 2:Tw 5:Fv 10:Te 20:Twe 50:Ff) = Coins 
   in
      Coins ::: 0#99
      P + 2*Tw + 5*Fv + 10*Te + 20*Twe + 50*Ff =: Total
      {Record.map Coins proc {$ A B}  A =<: B end PocketCoins}
      Total#Coins
   end
   
   proc {Coins Sol}
      PocketCoins coins(1:_ 2:_ 5:_ 10:_ 20:_ 50:_) = PocketCoins
      Min L = {MakeList 100}
   in
      Sol = sol(min: Min pocketcoins: PocketCoins sols: L)
      PocketCoins ::: 0#99
      Min :: 0#99
      {FD.sum PocketCoins '=:' Min}
      {List.forAllInd L fun {$ I} {CoinsTotal PocketCoins I} end}
      {FD.distribute naive PocketCoins}
      {ForAll L proc {$ _#Cs}
		   {FD.distribute naive Cs}
		end}
   end

   CoinsSol =
   [sol(min:8 pocketcoins:coins(1 2 5:1 10:1 20:2 50:1)
	sols:[1#coins(1 0 5:0 10:0 20:0 50:0)
	      2#coins(0 1 5:0 10:0 20:0 50:0)
	      3#coins(1 1 5:0 10:0 20:0 50:0)
	      4#coins(0 2 5:0 10:0 20:0 50:0)
	      5#coins(0 0 5:1 10:0 20:0 50:0)
	      6#coins(1 0 5:1 10:0 20:0 50:0)
	      7#coins(0 1 5:1 10:0 20:0 50:0)
	      8#coins(1 1 5:1 10:0 20:0 50:0)
	      9#coins(0 2 5:1 10:0 20:0 50:0)
	      10#coins(0 0 5:0 10:1 20:0 50:0)
	      11#coins(1 0 5:0 10:1 20:0 50:0)
	      12#coins(0 1 5:0 10:1 20:0 50:0)
	      13#coins(1 1 5:0 10:1 20:0 50:0)
	      14#coins(0 2 5:0 10:1 20:0 50:0)
	      15#coins(0 0 5:1 10:1 20:0 50:0)
	      16#coins(1 0 5:1 10:1 20:0 50:0)
	      17#coins(0 1 5:1 10:1 20:0 50:0)
	      18#coins(1 1 5:1 10:1 20:0 50:0)
	      19#coins(0 2 5:1 10:1 20:0 50:0)
	      20#coins(0 0 5:0 10:0 20:1 50:0)
	      21#coins(1 0 5:0 10:0 20:1 50:0)
	      22#coins(0 1 5:0 10:0 20:1 50:0)
	      23#coins(1 1 5:0 10:0 20:1 50:0)
	      24#coins(0 2 5:0 10:0 20:1 50:0)
	      25#coins(0 0 5:1 10:0 20:1 50:0)
	      26#coins(1 0 5:1 10:0 20:1 50:0)
	      27#coins(0 1 5:1 10:0 20:1 50:0)
	      28#coins(1 1 5:1 10:0 20:1 50:0)
	      29#coins(0 2 5:1 10:0 20:1 50:0)
	      30#coins(0 0 5:0 10:1 20:1 50:0)
	      31#coins(1 0 5:0 10:1 20:1 50:0)
	      32#coins(0 1 5:0 10:1 20:1 50:0)
	      33#coins(1 1 5:0 10:1 20:1 50:0)
	      34#coins(0 2 5:0 10:1 20:1 50:0)
	      35#coins(0 0 5:1 10:1 20:1 50:0)
	      36#coins(1 0 5:1 10:1 20:1 50:0)
	      37#coins(0 1 5:1 10:1 20:1 50:0)
	      38#coins(1 1 5:1 10:1 20:1 50:0)
	      39#coins(0 2 5:1 10:1 20:1 50:0)
	      40#coins(0 0 5:0 10:0 20:2 50:0)
	      41#coins(1 0 5:0 10:0 20:2 50:0)
	      42#coins(0 1 5:0 10:0 20:2 50:0)
	      43#coins(1 1 5:0 10:0 20:2 50:0)
	      44#coins(0 2 5:0 10:0 20:2 50:0)
	      45#coins(0 0 5:1 10:0 20:2 50:0)
	      46#coins(1 0 5:1 10:0 20:2 50:0)
	      47#coins(0 1 5:1 10:0 20:2 50:0)
	      48#coins(1 1 5:1 10:0 20:2 50:0)
	      49#coins(0 2 5:1 10:0 20:2 50:0)
	      50#coins(0 0 5:0 10:0 20:0 50:1)
	      51#coins(1 0 5:0 10:0 20:0 50:1)
	      52#coins(0 1 5:0 10:0 20:0 50:1)
	      53#coins(1 1 5:0 10:0 20:0 50:1)
	      54#coins(0 2 5:0 10:0 20:0 50:1)
	      55#coins(0 0 5:1 10:0 20:0 50:1)
	      56#coins(1 0 5:1 10:0 20:0 50:1)
	      57#coins(0 1 5:1 10:0 20:0 50:1)
	      58#coins(1 1 5:1 10:0 20:0 50:1)
	      59#coins(0 2 5:1 10:0 20:0 50:1)
	      60#coins(0 0 5:0 10:1 20:0 50:1)
	      61#coins(1 0 5:0 10:1 20:0 50:1)
	      62#coins(0 1 5:0 10:1 20:0 50:1)
	      63#coins(1 1 5:0 10:1 20:0 50:1)
	      64#coins(0 2 5:0 10:1 20:0 50:1)
	      65#coins(0 0 5:1 10:1 20:0 50:1)
	      66#coins(1 0 5:1 10:1 20:0 50:1)
	      67#coins(0 1 5:1 10:1 20:0 50:1)
	      68#coins(1 1 5:1 10:1 20:0 50:1)
	      69#coins(0 2 5:1 10:1 20:0 50:1)
	      70#coins(0 0 5:0 10:0 20:1 50:1)
	      71#coins(1 0 5:0 10:0 20:1 50:1)
	      72#coins(0 1 5:0 10:0 20:1 50:1)
	      73#coins(1 1 5:0 10:0 20:1 50:1)
	      74#coins(0 2 5:0 10:0 20:1 50:1)
	      75#coins(0 0 5:1 10:0 20:1 50:1)
	      76#coins(1 0 5:1 10:0 20:1 50:1)
	      77#coins(0 1 5:1 10:0 20:1 50:1)
	      78#coins(1 1 5:1 10:0 20:1 50:1)
	      79#coins(0 2 5:1 10:0 20:1 50:1)
	      80#coins(0 0 5:0 10:1 20:1 50:1)
	      81#coins(1 0 5:0 10:1 20:1 50:1)
	      82#coins(0 1 5:0 10:1 20:1 50:1)
	      83#coins(1 1 5:0 10:1 20:1 50:1)
	      84#coins(0 2 5:0 10:1 20:1 50:1)
	      85#coins(0 0 5:1 10:1 20:1 50:1)
	      86#coins(1 0 5:1 10:1 20:1 50:1)
	      87#coins(0 1 5:1 10:1 20:1 50:1)
	      88#coins(1 1 5:1 10:1 20:1 50:1)
	      89#coins(0 2 5:1 10:1 20:1 50:1)
	      90#coins(0 0 5:0 10:0 20:2 50:1)
	      91#coins(1 0 5:0 10:0 20:2 50:1)
	      92#coins(0 1 5:0 10:0 20:2 50:1)
	      93#coins(1 1 5:0 10:0 20:2 50:1)
	      94#coins(0 2 5:0 10:0 20:2 50:1)
	      95#coins(0 0 5:1 10:0 20:2 50:1)
	      96#coins(1 0 5:1 10:0 20:2 50:1)
	      97#coins(0 1 5:1 10:0 20:2 50:1)
	      98#coins(1 1 5:1 10:0 20:2 50:1)
	      99#coins(0 2 5:1 10:0 20:2 50:1)
	      100#coins(0 0 5:0 10:1 20:2 50:1)])]

   
   Return=
   fd([coins([
	      one(equal(fun {$} {Search.base.one Coins} end CoinsSol)
		  keys: [fd])
	      one_entailed(entailed(proc {$} {Search.base.one Coins _} end)
			   keys: [fd entailed])
	     ]
	    )
      ]
     )

end
