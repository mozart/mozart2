functor

import

   FD

   Search

export
   Return
define


   proc {Color ?EC}
      Germany
      France
      Belgium
      Netherlands
      Spain
      Portugal
      Luxemburg
      Denmark
      Italy
   in
      map(germany:     Germany
	  france:      France
	  belgium:     Belgium
	  netherlands: Netherlands
	  spain:       Spain
	  portugal:    Portugal
	  luxemburg:   Luxemburg
	  denmark:     Denmark
	  italy:       Italy
	  england:     _
	  greece:      _) = EC
      {Record.forAll EC proc {$ Country} Country :: 0#3 end}
      Netherlands \=: Germany
      France   \=:    Germany
      Belgium  \=:    Germany
      Luxemburg \=:   Germany
      Denmark   \=:   Germany
      Belgium   \=:   France
      Luxemburg \=:   France
      Spain     \=:   France
      Italy     \=:   France
      Netherlands\=:  Belgium
      Portugal   \=:  Spain
      {FD.distribute ff EC}
   end

   ColorSol =
   [map(
	belgium:0 
	denmark:0 
	england:0 
	france:1 
	germany:2 
	greece:0 
	italy:0 
	luxemburg:0 
	netherlands:1 
	portugal:1 
	spain:0)]

   Return=

   fd([color([
	      one(equal(fun {$}
			   {Search.base.one Color}
			end
			ColorSol)
		  keys: [fd])
	      one_entailed(entailed(proc {$}
			   {Search.base.one Color _}
				    end)
		  keys: [fd entailed])
	     ])
      ])
   
end
