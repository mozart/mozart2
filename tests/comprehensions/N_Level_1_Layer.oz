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
      Tests = [ %% each element is [listComprehension]#[expectedList]
                %% Add tests from here...
                [[A B] for A in 1..2 for B in 3..4]
                #[[1 3] [1 4] [2 3] [2 4]]

                [A#B#C for A in [0 2] for B in 4 ; B<10 ; B+2 for C in 8..10 ; 2 if B<7]
                #[0#4#8 0#4#10 0#6#8 0#6#10 2#4#8 2#4#10 2#6#8 2#6#10]

                [A#B#C for A in [0 2] if A<10 for B in [4 6 7] for C in [8 10] if B<7]
                #[0#4#8 0#4#10 0#6#8 0#6#10 2#4#8 2#4#10 2#6#8 2#6#10]

                [A#B#C for A in 0..2 ; 2 if A<10 for B in 4..7 ; 2 for C in 8..10 ; 2 if B<7]
                #[0#4#8 0#4#10 0#6#8 0#6#10 2#4#8 2#4#10 2#6#8 2#6#10]

                [A#B#C for A in 0 ; A=<2 ; A+2 if A<10 for B in 4 ; B<7 ; B+2 for C in 8 ; C=<10 ; C+2 if B<7]
                #[0#4#8 0#4#10 0#6#8 0#6#10 2#4#8 2#4#10 2#6#8 2#6#10]

                [1 for _ in 1..2 for _ in 1..2 for _ in 1..2]
                #[1 1 1 1 1 1 1 1]

                [A+B-C for A in 1..10 if A < 3 for B in [3 4] for C in A ; C<10 ; C+1 if C < 4]
                #[3 2 1 4 3 2 3 2 4 3]
                %% ...to here.
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end