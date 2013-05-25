functor

import

   FD

   Search

export
   Return
define

Knights =
fun {$ N}
   NN = N*N
   % The fields of the board are numbered from 1..NN
   % according to their lexicographic order, that is,
   % (1,1), (1,2), ..., (2,1), (2,2), ..., (N,N)
   %
   % Field: X x Y --> Field
   fun {Field X Y}
      (X-1)*N + Y
   end
   % Neighbours: Field --> List of fields
   fun {Neighbours F}
      X  = (F-1) mod N + 1
      Y  = (F-1) div N + 1
   in
      {FoldR [~2#~1 ~2#1 ~1#~2 ~1#2  1#~2 1#2 2#~1 2#1]
       fun {$ U#V In}
	  A = X+U
	  B = Y+V
       in
	  if A>=1 andthen A=<N andthen B>=1 andthen B=<N
	  then A + (B-1)*N | In else In end
       end
       nil}
   end
in
   proc {$ Solution}
      Pred  = {FD.tuple pred NN 1#NN}   % field --> field
      Succ  = {FD.tuple succ NN 1#NN}   % field --> field
      Jump  = {FD.tuple jump NN 1#NN}   % field --> jump
            = {FD.distinct}
   in
      Solution = Jump#Succ#Pred
      % there are no solutions for odd N
      N mod 2 = 0
      % tour starts as follows: (1,1), (2,3), ... 
      Jump.{Field 1 1} = 1            
      Jump.{Field 2 3} = 2
      % for every field F
      {For 1 NN 1
       proc {$ F}
	  Nbs   = {Neighbours F}
       in
	  Pred.F :: Nbs
	  Succ.F :: Nbs
	  % redundant constraint: avoid trivial cycles
	  Succ.F \=: Pred.F
          % for every neighbour G of F
	  {ForAll Nbs
	   proc {$ G}
	      (Succ.F=:G)
	      = (F=:Pred.G)
	      = (Jump.G =: {FD.modI Jump.F NN}+1)
	   end}
       end}
      {FD.distribute naive Succ} % better than ff
   end
end

KnightsSol =
[jump(1 8 15 24 3 10 13 22 16 25 2 9 14 23 4 11 7 64 
    17 26 5 12 21 38 18 27 6 63 20 39 54 59 47 62 19 
    28 55 60 37 40 32 29 48 61 44 41 58 53 49 46 31 
    34 51 56 43 36 30 33 50 45 42 35 52 57)#
 succ(11 12 9 10 15 16 13 14 19 20 5 6 3 4 21 22 2 1 
    25 26 27 7 8 30 35 36 17 18 23 40 37 38 43 28 29 
    42 54 44 24 46 58 57 49 34 60 61 32 31 59 33 41 
    62 63 64 45 39 51 52 53 50 55 56 48 47)#
 pred(18 17 13 14 11 12 22 23 3 4 1 2 7 8 5 6 27 28 
    9 10 15 16 29 39 19 20 21 34 35 24 48 47 50 44 
    25 26 31 32 56 30 51 36 33 38 55 40 64 63 43 60 
      57 58 59 37 61 62 42 41 49 45 46 52 53 54)]

Return =

   fd([knights([
		one(equal(fun {$} {Search.base.one {Knights 8}} end
			  KnightsSol)
		    keys: [fd])
		one_entailed(entailed(proc {$} {Search.base.one {Knights 8} _} end)
		    keys: [fd entailed])
	       ])
      ])

end
