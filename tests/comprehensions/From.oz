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
      C = {NewCell 0}
      fun {Fun0} 0 end
      fun {Fun1} 2 end
      fun {Fun2} C := @C + 1 @C end
      Tests = [ %% each element is [listComprehension]#[expectedList]
                %% add tests from here...
                [I*A suchthat A in [1 2 3] I from Fun1]#[2 4 6] % Cell = 0

                [I*A suchthat A in [1 2 3] I from Fun2]#[1 4 9] % Cell = 4

                [I*A#J*B suchthat A in [1 2 3] I from Fun2 suchthat B in 1..2 J from Fun2]
                #[5#6 5#14 18#10 18#22 39#14 39#30]

                [A suchthat _ in 1..1 A from Fun1]#[2]

                [Z+Y suchthat Z from Fun0 _ in 1..2 suchthat _ in [1 2] Y from Fun1]
                #[2 2 2 2]

                [Z*Y suchthat Z from Fun0 A in 1..2 if A < 2 suchthat _ in [1 2] Y from Fun1]
                #[0 0]

                [Z+Y suchthat Z from Fun0 A in 1..2 if A < 2 suchthat _ in [1 2] Y from Fun1 if Y == 1]
                #nil

                [Z+Y suchthat Z from Fun0 A in 1..2 if A < 2 suchthat _ in [1 2] Y from Fun1 if Y == {Fun1}]
                #[2 2]

                [A suchthat A from fun{$} 1 end _ in 1..2]
                #[1 1]
                %% ...to here
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end
