fun {$ IMPORT}
   \insert '../lib/import.oz'

   Pythagoras =
   proc {$ Root}
      proc {Square X S}
         {FD.times X X S}     % exploits coreference
      end
      [A B C] = Root
      AA      = {Square A}
      BB      = {Square B}
      CC      = {Square C}
   in
      Root ::: 1#1000
      AA + BB =: CC           % A*A + B*B =: C*C propagates much worse
      A =<: B
      B =<: C
      2*BB >=: CC             % redundant constraint
      {FD.distribute ff Root}
   end

   PythagorasSol = [[3 4 5]]

in

   fd([pythagoras([
                   one(equal(fun {$} {SearchOne Pythagoras} end
                             PythagorasSol)
                       keys: [fd])
                   one_entailed(entailed(proc {$} {SearchOne Pythagoras _} end)
                                keys: [fd entailed])
                  ])
      ])

end
