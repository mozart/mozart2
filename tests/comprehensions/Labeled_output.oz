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
                [A suchthat A in 0..10]
                #[0 1 2 3 4 5 6 7 8 9 10]

                [a:A suchthat A in 0..10]
                #'#'(a:[0 1 2 3 4 5 6 7 8 9 10])

                [whatever:A suchthat A in 0..10]
                #'#'(whatever:[0 1 2 3 4 5 6 7 8 9 10])

                [a:A 2*A suchthat A in 0 ; A<11 ; A+1]
                #'#'(1:[0 2 4 6 8 10 12 14 16 18 20] a:[0 1 2 3 4 5 6 7 8 9 10])

                [1:A 2*A suchthat A in 0 ; A<11 ; A+1]
                #'#'(1:[0 1 2 3 4 5 6 7 8 9 10] 2:[0 2 4 6 8 10 12 14 16 18 20])

                [A 2*A suchthat A in 0 ; A<11 ; A+1]
                #([0 1 2 3 4 5 6 7 8 9 10]#[0 2 4 6 8 10 12 14 16 18 20])

                [a:A 2*A b:A suchthat A in 0 ; A<11 ; A+1]
                #'#'(1:[0 2 4 6 8 10 12 14 16 18 20] a:[0 1 2 3 4 5 6 7 8 9 10] b:[0 1 2 3 4 5 6 7 8 9 10])

                [3:A+1 1:2*A A suchthat A in [A suchthat A in 0..10]]
                #'#'(1:[0 2 4 6 8 10 12 14 16 18 20] 2:[0 1 2 3 4 5 6 7 8 9 10] 3:[1 2 3 4 5 6 7 8 9 10 11])
                %% ...to here.
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end