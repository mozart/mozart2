functor

import

   FS
   Search

export
   Return
define

   Bits = 7     % maximal domain (7 bit, ie, 128 codes)
   Dist = 2     % minimal hamming distance
   Num  = 16    % number of variables
   
   Top  = {FS.value.make [1#Bits]}

   proc {MinDist X Y}      
      Common1s = {FS.intersect X Y}
      Common0s = {FS.complIn {FS.union X Y} Top}
   in
      {FS.card Common1s} + {FS.card Common0s} =<: Bits-Dist
   end

   %
   % Num set variables below {1,...,Bits}
   % with minimal hamming distance Dist
   %
   proc {Hamming Xs}
      Xs = {MakeList Num}

      {ForAll Xs
       fun {$} {FS.var.upperBound [1#Bits]} end}
   
      {ForAllTail Xs
       proc {$ Ys}
	  Y|Yr = Ys
       in
	  {ForAll Yr
	   proc {$ Z} {MinDist Y Z} end}
       end}

      {FS.distribute naive Xs}
   end

   HammingSol =
   [[{FS.value.make [1#7]}
     {FS.value.make [1#5]}
     {FS.value.make [1#4 6]}
     {FS.value.make [1#4 7]}
     {FS.value.make [1#3 5#6]} 
     {FS.value.make [1#3 5 7]}
     {FS.value.make [1#3 6#7]}
     {FS.value.make [1#3]}
     {FS.value.make [1#2 4#6]} 
     {FS.value.make [1#2 4#5 7]}
     {FS.value.make [1#2 4 6#7]}
     {FS.value.make [1#2 4]}
     {FS.value.make [1#2 5#7]} 
     {FS.value.make [1#2 5]}
     {FS.value.make [1#2 6]}
     {FS.value.make [1#2 7]}
    ]]

   Return=
   fs([hamming([
		one(equal(fun {$} {Search.base.one Hamming} end HammingSol)
		    keys: [fs])
		one_entailed(entailed(proc {$}
					 {Search.base.one Hamming _}
				      end)
		    keys: [fs entailed])
	       ]
	      )
      ]
     )
end
