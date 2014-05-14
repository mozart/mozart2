%%
%% Author:
%%     Francois Fonteyn, 2014
%%
%% Sources:
%%     Thompson, S., "Haskell: The Craft of Functional Programming", Addison-Wesley, 1996.
%%     http://www.haskell.org/haskellwiki/List_comprehension
%%

functor

export
   Return

define
   Return =
   listComprehensions([
      haskell(proc{$}
         L = [2 4 7]
         Pairs = [2#3 2#1 7#8]
         fun {IsEven A} A mod 2 == 0 end
      in
         %% [2*a | a <- L]
         [2*A suchthat A in L] = [4 8 14]

         %% [isEven a | a <- L]
         [{IsEven A} suchthat A in L] = [true true false]

         %% [2*a | a <- L, isEven a, a>3]
         [2*A suchthat A in L if {IsEven A} andthen A>3] = [8]

         %% [a+b | (a,b) <- Pairs]
         [A+B suchthat A#B in Pairs] = [5 3 15]

         %% [a+b | (a,b) <- Pairs, a<b]
         [A+B suchthat A#B in Pairs if A<B] = [5 15]

         %% [(i,j) | i <- [1,2], j <- [1..4]]
         [[I J] suchthat I in [1 2] suchthat J in 1..4] = [[1 1] [1 2] [1 3] [1 4] [2 1] [2 2] [2 3] [2 4]]

         %% [[ (i,j) | i <- [1,2]] | j <- [3,4]]
         [[[I J] suchthat I in 1..2] suchthat J in 3..4] = [[[1 3] [2 3]] [[1 4] [2 4]]]

         %% take 5 [[ (i,j) | i <- [1,2]] | j <- [1...]]
         [[[I J] suchthat I in 1..2] suchthat J in 1 ; J+1 _ in 1..5] % '_ in 1..5' replaces 'take 5'
            = [[[1 1] [2 1]] [[1 2] [2 2]] [[1 3] [2 3]] [[1 4] [2 4]] [[1 5] [2 5]]]
      end
      keys:[listComprehensions haskell])
   ])
end
