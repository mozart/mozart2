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
                [X if X<3 suchthat X in [1 2 3 4]]
                #[1 2]

                [a:X if X<3 Y if Y>4 suchthat X in [1 2 3 4] Y in [5 6 7 8]]
                #('#'(a:[1 2] 1:[5 6 7 8]))

                [X if X>3 Y if Y>7 suchthat X in [1 2] suchthat Y in [5 6 7 8]]
                #('#'(1:nil 2:[8 8]))

                [smallerEqual:A if A=<4 bigger:A if A>4 suchthat A in [2 5 4 3 6 1 7]]
                #'#'(smallerEqual:[2 4 3 1] bigger:[5 6 7])

                [A if B>2 suchthat A in [so hello world] B in [2 3 4]]
                #[hello world]

                %% ...to here
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end




