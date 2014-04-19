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
      fun {Ext C B} {C 1} B end
      Tests = [ %% each element is [listComprehension]#[expectedList]
                %% add tests form here...
                [c:collect:C for A in 1..2 do {C A}]
                #'#'(c:[1 2])

                [c:collect:C for A in 1..2 if A == 1 do {C A}{C A+1}]
                #'#'(c:[1 2])

                [c:collect:C for _ in 1..1 A from fun{$}1 end do {C A}{C A+1}]
                #'#'(c:[1 2])

                [c:collect:C for _:A in r(r(r(1) r(2))) do {C A}]
                #'#'(c:[1 2])

                [c:collect:C for A in 1..2 for B in 3..4 do {C A+B}{C A*B}]
                #'#'(c:[4 3 5 4 5 6 6 8])

                [1:collect:C1 2:collect:C2 for A in 1..2 do {C1 A}{C1 A*A}{C2 A+1}]
                #([1 1 2 4]#[2 3])

                [1:collect:C1 2:A+1 for A in 1..2 do {C1 A}{C1 A*A}]
                #([1 1 2 4]#[2 3])

                [c:collect:C for A in 1..3 if local skip in {C A} 0 == 1 end]
                #'#'(c:[1 2 3])

                [c:collect:C for A in 1..3 if {Ext C false} do {C A}]
                #'#'(c:[1 1 1])

                [c:collect:C for A in 1..3 if {Ext C true} do {C A}]
                #'#'(c:[1 1 1 2 1 3])
                %% ...to here
              ]
      L1 = thread [c:collect:C for lazy A in 1..2 do {C A}] end
      L2 = thread [c:collect:C for lazy A in 1..2 do {C A}{C A+1}] end
      L3a = thread [1:collect:C1 2:collect:C2 for lazy A in 1..2 do {C1 A}{C2 A+1}] end
      L3b = thread [1:collect:C1 2:collect:C2 for lazy A in 1..2 do {C1 A}{C2 A+1}] end
      L4 = thread [c:collect:C for lazy A in 1..2 for B in 3..4 do {C A+B}] end
      L5 = thread [c:collect:C for A in 1..2 for lazy B in 3..4 do {C A+B}] end
      L6a = thread [1:collect:C1 2:collect:C2 for lazy A in 1..2 for B in 3..4 do {C1 A}{C2 B}] end
      L6b = thread [1:collect:C1 2:collect:C2 for lazy A in 1..2 for B in 3..4 do {C1 A}{C2 B}] end
      L7a = thread [1:collect:C1 2:collect:C2 for lazy A in 1..2 for lazy B in 3..4 do {C1 A}{C2 B}] end
      L7b = thread [1:collect:C1 2:collect:C2 for lazy A in 1..2 for lazy B in 3..4 do {C1 A}{C2 B}] end
      TestsLazy = [ %%
                    L1.c#[1 2]#1
                    L2.c#[1 2 2 3]#2
                    L3a.1#[1 2]#1
                    L3b.2#[2 3]#1
                    L4.c#[4 5 5 6]#2
                    L5.c#[4 5 5 6]#1
                    L6a.1#[1 1 2 2]#2
                    L6b.2#[3 4 3 4]#2
                    L7a.1#[1 1 2 2]#1
                    L7b.2#[3 4 3 4]#1
                  ]
   in
      {Tester.test Tests}
      {Tester.testLazy TestsLazy}
      {Application.exit 0}
   end
end
