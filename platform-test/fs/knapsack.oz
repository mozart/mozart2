functor $ prop once

import

   FD FS

   Search.{SearchOne  = 'SearchOne'
           SearchAll  = 'SearchAll'
           SearchBest = 'SearchBest'}

export
   Return
body

   KnapSack =
   fun {$ Weights Capacity}
      LB = {FoldL Weights Number.'+' 0} div Capacity
      UB = {Length Weights}
      ItemList = {List.number 0 UB-1 1}
      AllItems = {FS.value.new ItemList}
   in
      proc {$ Root}
         Len
      in
         Len :: LB#UB

         thread
            Root = {FS.var.list.upperBound Len ItemList}

            {FS.partition Root AllItems}

            {ForAll Root
             proc {$ SV}
                {FD.sumC Weights {FS.reified.areIn ItemList SV} '=<:' Capacity}
             end}
         end

         {FD.distribute naive [Len]}
         {FS.distribute naive Root}
      end
   end

   Weights =
   [ 5 4 3 5 7 3 6 3 2 1]
   Capacity = 10

   KnapSackSol =
   [[
     {FS.value.new [0#1 9]}
     {FS.value.new [2#3 8]}
     {FS.value.new [4#5]}
     {FS.value.new [6#7]}
    ]]

   Return=
   fs([knapsack([
                 one(equal(fun {$} {SearchOne {KnapSack Weights Capacity}} end
                           KnapSackSol)
                     keys: [fs])
                 one_entailed(entailed(proc {$}
                                          {SearchOne {KnapSack Weights Capacity} _}
                                       end)
                              keys: [fs entailed])
                ]
               )
      ]
     )

end
