functor $ prop once

import

   FD

   Search.{SearchOne  = 'SearchOne'
           SearchAll  = 'SearchAll'
           SearchBest = 'SearchBest'}

export
   Return
body

   Safe =
   proc {$ C}
      {FD.tuple code 9 1#9 C}
      {FD.distinct C}
      {For 1 9 1 proc {$ I} C.I \=: I end}
      C.4 - C.6 =: C.7
      C.1 * C.2 * C.3 =: C.8 + C.9
      C.2 + C.3 + C.6 <: C.8
      C.9 <: C.8
      {FD.distribute ff C}
   end

   SafeSol =
   [code(4 3 1 8 9 2 6 7 5)]

   Return=
   fd([safe([
             all(equal(fun {$} {SearchAll Safe} end
                       SafeSol)
                 keys: [fd])
             all_entailed(entailed(proc {$} {SearchAll Safe _} end)
                 keys: [fd entailed])
            ])
      ])

end
