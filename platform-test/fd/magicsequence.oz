functor

import

   FD

   Search

export
   Return
define

   MagicSequencePrimer =

   {fun {$ N}
       Cs = {List.number ~1 N-2 1}
    in
       proc {$ S}
	  {FD.tuple sequence N 0#N-1 S}
	  {For 0 N-1 1
	   proc {$ I} {FD.exactly S.(I+1) S I} end}
	  {FD.sum S '=:' N}   % redundant
      % redundant: sum (i-1)*X_i = 0 (since  sum i*X_i = sum X_i)
	  {FD.sumC Cs S '=:' 0}
      %
	  {FD.distribute ff S}
       end
    end
    17}
		

   MagicSequencePrimerSol =
   [sequence(13 2 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0)]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% See Hentenryck page 155
% A series is magic if there are s_i occurrences of i in the series.
% example S = 2|1|2|0|0|nil 


   proc {Occur Number L Val}
      local Equations = {FoldL L fun {$ I X} (X=:Val)|I end nil} in
	 {FD.sum Equations '=:' Number}  
      end
   end

   MagicSequence = 
   proc {$ N L}
      L = {List.make N+1}
      L = {FD.dom 0#N}
      {List.forAllInd L proc{$ Ind X} {Occur X L Ind-1} end}
      {FD.distribute ff L}
   end

   MagicSequenceSol = [[4 2 1 0 1 0 0 0]]

Return=

   fd([magicsequence([
		      primer(equal(fun {$}
				      {Search.base.all MagicSequencePrimer}
				   end
				   MagicSequencePrimerSol)
			     keys: [fd])
		      
		      one(equal(fun {$}
				   {Search.base.one
				    proc{$ X} {MagicSequence 7 X} end}
				end
				MagicSequenceSol)
			  keys: [fd])
		      primer_entailed(entailed(proc {$}
						  {Search.base.all MagicSequencePrimer _}
					       end)
				      keys: [fd entailed])
		      
		      one_entailed(entailed(proc {$}
					       {Search.base.one
						proc{$ X} {MagicSequence 7 X}
						end _}
					    end)
				   keys: [fd entailed])
		     ])
      ])
   
end
