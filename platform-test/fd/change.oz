fun {$ IMPORT}
   \insert '../lib/import.oz'

   BillAndCoins = r(6#100  8#25  10#10  1#5  5#1)

   Change =
   {fun {$ BillAndCoins Amount}
       Available    = {Record.map BillAndCoins fun {$ A#D} A end}
       Denomination = {Record.map BillAndCoins fun {$ A#D} D end}
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
in

   fd([change([
               one(equal(fun {$}
                            {SearchOne Change}
                         end
                         ChangeSol)
                   keys: [fd])
               one_entailed(entailed(proc {$}
                                        {SearchOne Change _}
                                     end)
                   keys: [fd entailed])
              ])
      ])

end
