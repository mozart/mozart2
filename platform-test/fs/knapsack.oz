functor

import

   FD FS

   Search

export
   Return
define

   KnapSack =
   fun {$ Weights Capacity}
      LB = {FoldL Weights Number.'+' 0} div Capacity
      UB = {Length Weights}
      ItemList = {List.number 0 UB-1 1} 
      AllItems = {FS.value.make ItemList}
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
     {FS.value.make [0#1 9]}
     {FS.value.make [2#3 8]}
     {FS.value.make [4#5]}
     {FS.value.make [6#7]}
    ]]

   Return=
   fs([knapsack([
		 one(equal(fun {$} {Search.base.one {KnapSack Weights Capacity}} end
			   KnapSackSol)
		     keys: [fs])
		 one_entailed(entailed(proc {$}
					  {Search.base.one {KnapSack Weights Capacity} _}
				       end)
			      keys: [fs entailed])
		]
	       )
      ]
     )

end
