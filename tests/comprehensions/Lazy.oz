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
      Tests = [ %% each element is thread [lazyListComprehension] end#[expectedList]#numberOfOutputsCreatedForEachMakeNeeded
                thread [A for lazy A in 1..3] end
                #[1 2 3]#1

                thread [A+B for lazy A in 1..2 for B in [1 2 3]] end
                #[2 3 4 3 4 5]#3
        
                thread [A+B for A in 1..2 for lazy B in [B for A in 1..1 for B in [A for A in 1..3]]] end
                #[2 3 4 3 4 5]#1

                thread [A+B for lazy A in 1..2 for lazy B in 1..3] end
                #[2 3 4 3 4 5]#1

                thread [A+B for A in 1..2 for lazy B in 1..3 if A > 1] end
                #[3 4 5]#1

                thread [A+B#C+D for lazy A in 1..2 B in 3..4 for C in [1 2 3 4] D in 3 ; D<6 ; D+1 if D<5] end
                #[4#4 4#6 6#4 6#6]#2

                thread [A for lazy A from Fun _ in 1..3] end
                #[1 1 1]#1
              ]
   in
      {Tester.testLazy Tests}
      {Application.exit 0}
   end
end
