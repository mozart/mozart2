%%
%% Author:
%%     Francois Fonteyn, 2014
%%

functor
import
   Application
   Tester at 'Tester.ozf'
define
   local
      fun {Fun} 1 end
      fun {Get A} A end
      L = [A suchthat A in 0..10]
      Tests = [ %% each element is [listComprehension]#[expectedList]
                %% Add tests from here...
                [[A B] suchthat A in 0..9   B in 10..19]
                #[[0 10] [1 11] [2 12] [3 13] [4 14] [5 15] [6 16] [7 17] [8 18] [9 19]]

                [[A B] suchthat A in 0..9   B in 10..19   if A > 2 andthen B < 15]
                #[[3 13] [4 14]]

                [[A B C] suchthat A in 0..9   B in 10..19   C in 20..29]
                #[[0 10 20] [1 11 21] [2 12 22] [3 13 23] [4 14 24] [5 15 25] [6 16 26] [7 17 27] [8 18 28] [9 19 29]]

                [[A B C] suchthat A in 0..9   B in 10..19   C in 20..29   if A+B+C > 33]
                #[[2 12 22] [3 13 23] [4 14 24] [5 15 25] [6 16 26] [7 17 27] [8 18 28] [9 19 29]]

                [[A B C] suchthat A in L   B in {Get 10}..19 ; 4   C in 20 ; C<3*B ; C+A]
                #[[0 10 20] [1 14 20] [2 18 21]]

                [[A B C] suchthat A in 1 ; A<3 ; A+1   B from Fun   C in [4 5 6]]
                #[[1 1 4] [2 1 5]]

                [[A B C] suchthat A in [1 2]   B in [3 4 5]   C in [6 7 8 9]]
                #[[1 3 6] [2 4 7]]

                [[A B C D] suchthat A in [1 2]   B in [3 4 5]   C in [6 7 8 9]   D in L]
                #[[1 3 6 0] [2 4 7 1]]

                [1 suchthat _ in [1 2]   _ in [3 4 5]   _ in [6 7 8 9]   _ in L]
                #[1 1]

                [A+B suchthat A in 1 ; A<10 ; 1   B in 1..4 ; 2]
                #[2 4]

                [A suchthat A in 1 ; A+1   _ in [1 1 1 1]]
                #[1 2 3 4]

                [A suchthat A in 1 ; A+1   _ in [1 1 1 1] if A < 4]
                #[1 2 3]
                %% ...to here.
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end