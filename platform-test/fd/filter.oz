functor
export
   Return
prepare
   %% This test checks that the "filter" option of "distribute"
   %% maintains variables in their original order.  We check
   %% this by computing a record accurately representing the
   %% search tree and comparing it to what we expect it to be.
   CORRECT_SEARCH_TREE=
   alt([[1#3] [1#3] [1#3]] 
       alt([[1] [1#3] [1#3]] alt([[1] [1] [1#3]] [[1] [1] [1]] alt([[1] [1] [2#3]] [[1] [1] [2]] [[1] [1] [3]])) 
	   alt([[1] [2#3] [1#3]] alt([[1] [2] [1#3]] [[1] [2] [1]] alt([[1] [2] [2#3]] [[1] [2] [2]] [[1] [2] [3]])) 
	       alt([[1] [3] [1#3]] [[1] [3] [1]] alt([[1] [3] [2#3]] [[1] [3] [2]] [[1] [3] [3]])))) 
       alt([[2#3] [1#3] [1#3]] 
	   alt([[2] [1#3] [1#3]] alt([[2] [1] [1#3]] [[2] [1] [1]] alt([[2] [1] [2#3]] [[2] [1] [2]] [[2] [1] [3]])) 
	       alt([[2] [2#3] [1#3]] alt([[2] [2] [1#3]] [[2] [2] [1]] alt([[2] [2] [2#3]] [[2] [2] [2]] [[2] [2] [3]])) 
		   alt([[2] [3] [1#3]] [[2] [3] [1]] alt([[2] [3] [2#3]] [[2] [3] [2]] [[2] [3] [3]])))) 
	   alt([[3] [1#3] [1#3]] alt([[3] [1] [1#3]] [[3] [1] [1]] alt([[3] [1] [2#3]] [[3] [1] [2]] [[3] [1] [3]])) 
	       alt([[3] [2#3] [1#3]] alt([[3] [2] [1#3]] [[3] [2] [1]] alt([[3] [2] [2#3]] [[3] [2] [2]] [[3] [2] [3]])) 
		   alt([[3] [3] [1#3]] [[3] [3] [1]] alt([[3] [3] [2#3]] [[3] [3] [2]] [[3] [3] [3]]))))))
import
   FD Space
define
   fun {ToTree Pred Snap}
      fun {DF S}
	 case {Space.ask S}
	 of failed then false
	 [] succeeded then {Snap S}
	 [] alternatives(N) then
	    IM={Snap S}
	    S2={Space.clone S}
	 in
	    {Space.commit S 1}
	    {Space.commit S2 2#N}
	    alt(IM {DF S} {DF S2})
	 end
      end
   in
      {DF {Space.new Pred}}
   end

   Return =
   fd([filter(
	  equal(
	     fun {$}
		{ToTree
		 proc {$ L} L=[_ _ _] L:::1#3
		    {FD.distribute generic(order:naive
					   filter:fun {$ V} {Not {IsDet V}} end) L} end
		 fun {$ S} {Map {Space.merge {Space.clone S}}
			    FD.reflect.dom}
		 end}
	     end
	     CORRECT_SEARCH_TREE)
	  keys : [fd search])])
end