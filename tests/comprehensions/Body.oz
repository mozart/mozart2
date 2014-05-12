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
      C = {NewCell _}
      Tests = [ %% each element is [listComprehension]#[expectedList]
                %% add tests from here...
                [@C suchthat A in 1..2 do C:=A]
                #[1 2]

                [@C suchthat A in 1..2 do C:=A C:=@C*A]
                #[1 4]

                [@C suchthat A in 1..2 if A > 1 do C:=A]
                #[2]

                [@C if @C > 1 suchthat A in 1..2 do C:=A]
                #[2]

                [@C-1 suchthat A in 1..2 do C:=A+1]
                #[1 2]

                [@C suchthat _ in 1..1 A from fun{$} 1 end do C:=A]
                #[1]

                [@C suchthat _:A in r(r(r(1) r(2))) do C:=A]
                #[1 2]

                [@C suchthat A in 1..2 suchthat B in 1..2 do C:=A+B]
                #[2 3 3 4]
              ]
      L1 = thread [@C suchthat lazy A in 1..2 do C:=A] end
      L2 = thread [@C suchthat lazy A in 1..2 do C:=A C:=@C*A] end
      L3 = thread [@C suchthat lazy A in 1..2 if A > 1 do C:=A] end
      L4 = thread [@C if @C > 1 suchthat lazy A in 1..2 do C:=A] end
      L5 = thread [@C suchthat lazy A in 1..2 suchthat B in 1..2 do C:=A+B] end
      TestsLazy = [ %%
                    L1#[1 2]#1
                    L2#[1 4]#1
                    L3#[2]#1
                    L4#[2]#1
                    L5#[2 3 3 4]#2
                  ]
   in
      {Tester.test Tests}
      {Tester.testLazy TestsLazy}
      {Application.exit 0}
   end
end
