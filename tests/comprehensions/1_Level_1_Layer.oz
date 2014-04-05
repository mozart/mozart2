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
      fun {Get0} 0 end
      fun {Get A} A end
      fun {Cond1 A} A<11 end
      fun {Cond2 A} A mod 2 == 0 end
      fun {Plus2 A} A+2 end
      L = [A for A in 0..10]
      Tests = [ %% each element is [listComprehension]#[expectedList]
                %% Add tests from here...
                [A for A in 0..10                                ]#[0 1 2 3 4 5 6 7 8 9 10]
                [A for A in 0..10 if A mod 2 == 0                ]#[0 2 4 6 8 10]
                [A for A in 0..10 ; {Get 2}                      ]#[0 2 4 6 8 10]
                [A for A in 0..10 ; 2 if A > 3                   ]#[4 6 8 10]
                [A for A in 0 ; A<11 ; A+1                       ]#[0 1 2 3 4 5 6 7 8 9 10]
                [A for A in 0 ; A<11 ; A+1 if A mod 2 == 0       ]#[0 2 4 6 8 10]
                [A for A in {Get0} ; {Cond1 A} ; {Plus2 A}       ]#[0 2 4 6 8 10]
                [A for A in {Get0} ; {Cond1 A} ; A+1 if {Cond2 A}]#[0 2 4 6 8 10]
                [A for A in L                                    ]#[0 1 2 3 4 5 6 7 8 9 10]
                [A for A in L if A mod 2 == 0                    ]#[0 2 4 6 8 10]
                [A for A in [0 2 4 6 8 10]                       ]#[0 2 4 6 8 10]
                [A for A in [0 1 2 3 4 5 6 7 8 9 10] if {Cond2 A}]#[0 2 4 6 8 10]
                %% ...to here.
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end