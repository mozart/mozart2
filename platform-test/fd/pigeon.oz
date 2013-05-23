functor

import

   FD

   Search

export
   Return
define
% N pigeons have to fit into M pigeon holes.
% In each hole is at most one pigeon allowed.
% Each pigeon must be in a hole.


   proc {StateDomains Pigeons Holes A}
      A = {MakeTuple f Pigeons*Holes}
      {Record.forAll A proc {$ X} X :: 0#1 end}
   end

   proc {StateConstraints Pigeons Holes A}
      % At most one pigeon in a hole
      {For 1 Holes 1 
       proc{$ I} 
	  {Loop.forThread 1 Pigeons 1 
	   proc{$ In Index Out}
	      Out :: 0#FD.sup
	      Out=:In+ A.((Index-1)*Holes+I) end 0}=<: 1
       end}
      % Each pigeon in exactly one hole
      {For 1 Pigeons 1
       proc{$ I}
	  {Loop.forThread 1 Holes 1 
	   proc{$ In Index Out}
	      Out :: 0#FD.sup
	      Out=:In+A.((I-1)*Holes+Index) end 0 }=1
       end}
   end

   proc {Pigeon Pigeons Holes A}
      {StateDomains Pigeons Holes A}
      {StateConstraints Pigeons Holes A}
      {FD.distribute ff A}
   end

   PigeonSol =
   [f(0 0 1 0 1 0) f(0 0 1 1 0 0) f(0 1 0 0 0 1) 
    f(0 1 0 1 0 0) f(1 0 0 0 0 1) f(1 0 0 0 1 0)]

   Return=
   fd([pigeon([
	       all(equal(fun {$} {Search.base.all proc{$ X} {Pigeon 2 3 X} end} end
			 PigeonSol)
		   keys: [fd])
	       all_entailed(entailed(proc {$} {Search.base.all proc{$ X} {Pigeon 2 3 X} end _} end)
			    keys: [fd entailed])
	      ])
      ])
   
end


