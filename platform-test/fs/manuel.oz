functor

import

   FS

export
   Return

define

   \insert 'manuel_constr.oz'

   ManuelTest =
   fun {$ N T}
      L = {StringToAtom {VirtualString.toString N}}
   in
      L(equal(T 1) keys: [fs])
   end

   ManuelTestFnct =
   fun {$ Off}
      Vs = {FS.var.list.decl 308}
   in
      fun {$}
	 {ManuelConstr Vs Off}
	 thread
	    cond {List.forAllInd Vs
		  proc {$ I V} if I =< 77
			       then V = {FS.value.make I+Off}
			       else skip
			       end
		  end}
	    then 1 else 0 end
	 end
      end
   end

   Return=
   fs([manuel([
	       {ManuelTest 1 {ManuelTestFnct 0}}
	       {ManuelTest 2 {ManuelTestFnct 64}}
	       {ManuelTest 3 {ManuelTestFnct 1024}}
	      ])
      ])

end
