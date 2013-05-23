functor

import

   FD

   Search

export
   Return
define

   Line =
   proc {$ X S N Sq} {For 1 S 1 proc {$ I} X.I = {Nth Sq (N-1)*S+I} end}
   end
   
   Row =
   proc {$ X S N Sq} {For 1 S 1 proc {$ I} X.I = {Nth Sq (I-1)*S+N} end}
   end

   SumUp =
   fun {$ Square S N F}
      X = {MakeTuple x S} 
   in
      {F X S N Square}
      {FD.sum X '=:' }
   end
   
   Desc =
   proc {$ X S Sq} {For 1 S 1 proc {$ I} X.I = {Nth Sq (I-1)*S+I} end}
   end

   Asc =
   proc {$ X S Sq} {For 1 S 1 proc {$ I} X.I = {Nth Sq (I-1)*S+S+1-I} end}
   end

   SumUpDiag =
   fun {$ Square S F}
      X = {MakeTuple x S}
   in
      {F X S Square}
      {FD.sum  X '=:' }
   end

   MagicSquare =
   proc {$ S Sum Square}
      Square = {FD.list S*S 1#S*S}
      Sum = S*(S*S+1) div 2 = {SumUpDiag Square S Asc}
      = {SumUpDiag Square S Desc}
      
      {For 1 S 1 proc {$ I} Sum = {SumUp Square S I Line} end}
      {For 1 S 1 proc {$ I} Sum = {SumUp Square S I Row} end}
      Square = {FD.distinct} = {FD.distribute split}
   end

   MagicSquareSol = [34#[1 2 15 16 12 14 3 5 13 7 10 4 8 11 6 9]]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   MagicSquarePrimer = 
   {fun {$ N}
       NN  = N*N
       L1N = {List.number 1 N 1}  % [1 2 3 ... N]
    in
       proc {$ Square}
	  fun {Field I J}
	     Square.((I-1)*N + J)
	  end
	  proc {Assert F}
         % {F 1} + {F 2} + ... + {F N} =: Sum
	     {FD.sum {Map L1N F} '=:' Sum}
	  end
	  Sum = {FD.decl} 
       in
	  {FD.tuple square NN 1#NN Square}
	  {FD.distinct Square}
      % Diagonals
	  {Assert fun {$ I} {Field I I} end}
	  {Assert fun {$ I} {Field I N+1-I} end}
      % Columns
	  {For 1 N 1
	   proc {$ I} {Assert fun {$ J} {Field I J} end} end}
      % Rows
	  {For 1 N 1
	   proc {$ J} {Assert fun {$ I} {Field I J} end} end}
      % Eliminate symmetries
	  /* {Field 1 1} <: {Field N N}
	  {Field N 1} <: {Field 1 N}
	  {Field 1 1} <: {Field N 1} */
      % Redundant: sum of all fields = (number rows) * Sum
	  NN*(NN+1) div 2 =: N*Sum
      %
	  {FD.distribute split Square}
       end
    end 3}
   MagicSquarePrimerSol =  [square(2 7 6 9 5 1 4 3 8)]    

Return=

   fd([magicsquare([
		    one(equal(fun {$}
				 {Search.base.one proc {$ Sol}
					       Size Square
					    in
					       {MagicSquare 4
						Size Square}
					       Sol = Size#Square
					    end}
				 
			      end
			      MagicSquareSol)
			keys: [fd])

		    primer(equal(fun {$}
				    {Search.base.one MagicSquarePrimer}
				    
				 end
				 MagicSquarePrimerSol)
			   keys: [fd])
		    one_entailed(entailed(proc {$}
					     {Search.base.one proc {$ Sol}
							   Size Square
							in
							   {MagicSquare 4
							    Size Square}
							   Sol = Size#Square
							end _}
					     
					  end)
				 keys: [fd entailed])
		    
		    primer_entailed(entailed(proc {$}
						{Search.base.one MagicSquarePrimer _}
					     end)
				    keys: [fd entailed])
		   ])
      ])
   
end
