functor

import

   FS
   Search

export
   Return
define


   CartProd =
   proc {$ L P}
      {ForAllTail L proc {$ H|T} {ForAll T proc {$ E} {P H E} end} end}
   end

   fun {Steiner N}
      N1 = N + 1
      N1N1 = N1 * N1
   in
      proc {$ Root} 
	 if N mod 6 == 1 orelse N mod 6 == 3 then
	    Len = (N * (N-1)) div 6 
	 in
	    Root = {MakeList Len}
	    {ForAll Root proc {$ E}
			    {FS.var.upperBound [1#N] E}
			    {FS.cardRange 3 3 E}
			 end}
	    
	    {CartProd Root proc {$ X Y} S in 
				{FS.var.decl S}
				{FS.cardRange 0 1 S}
				{FS.intersect X Y S}
			     end
	    } 
	    {ForAllTail Root proc{$ S1|Tr}
				{ForAll Tr proc{$ S2} X1 X2 X3 Y1 Y2 Y3 in
					      [X1 X2 X3 Y1 Y2 Y3] ::: 1#N
					      {FS.int.match S1 [X1 X2 X3]}
					      {FS.int.match S2 [Y1 Y2 Y3]}
					      N1N1 * X1 + N1 * X2 + X3 <:
				              N1N1 * Y1 + N1 * Y2 + Y3
					   end}
			  end}
	    {FS.distribute naive Root}
	 else 
	    Root = ['Problem not define for such N=' N]
	 end % if
      end % proc
   end % fun

   SteinerSol =
   [[
     {FS.value.make [1#3]}
     {FS.value.make [1 4#5]}
     {FS.value.make [1 6#7]}
     {FS.value.make [1 8#9]}
     {FS.value.make [2 4 6]}
     {FS.value.make [2 5 8]}
     {FS.value.make [2 7 9]}
     {FS.value.make [3#4 9]}
     {FS.value.make [3 5 7]}
     {FS.value.make [3 6 8]}
     {FS.value.make [4 7#8]}
     {FS.value.make [5#6 9]}
    ]]
Return=
   fs([steiner([
		one(equal(fun {$} {Search.base.one {Steiner 9}} end SteinerSol)
		    keys: [fs])
		one_entailed(entailed(proc {$} {Search.base.one {Steiner 9} _} end)
			     keys: [fs entailed])
	       ]
	      )
      ]
     )
end
