functor

import

   FD

   Search

export
   Return
define

   Data = [ belgium     # [france netherlands germany luxemburg]
	    germany     # [austria france luxemburg netherlands]
	    switzerland # [italy france germany austria]	 
	    austria     # [italy switzerland germany]
	    france      # [spain luxemburg italy]
	    spain       # [portugal] ]

   Once =
   fun {$ L A}
      case L
      of H|T then {Once T if {Member H A} then A else H|A end}
      else A
      end
   end

   MapColoring =
   {fun {$ Data}
       Countries = {FoldR Data fun {$ C#Cs A} {Append Cs C|A} end nil}
    in
       proc {$ Color}
	  NbColors  = {FD.decl}
       in
      % Color: Countries --> 1#NbColors
	  thread
	     {FD.record color {Once Countries nil} 1#NbColors Color}
	  end
	  {ForAll Data
	   proc {$ A#Bs}
	      {ForAll Bs proc {$ B} thread Color.A \=: Color.B end end}
	   end}
	  {FD.distribute naive [NbColors]}
	  {FD.distribute ff Color}
       end
    end
    Data}

   MapColoringSol =
   [color(
	  austria:1 
	  belgium:3 
	  france:1 
	  germany:2 
	  italy:2 
	  luxemburg:4 
	  netherlands:1 
	  portugal:1 
	  spain:2 
	  switzerland:3)]

   Return=
   fd([mapcoloring([
 		    one(equal(fun {$}
				 {Search.base.one MapColoring}
			      end
			      MapColoringSol)
			keys: [fd])
		    one_entailed(entailed(proc {$}
					     {Search.base.one MapColoring _}
					  end)
			keys: [fd entailed])
		   ])
      ])
   
end
