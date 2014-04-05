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
      Rec = rec(c:c b:b 1:a d:d)
      Tests = [ %% each element is [listComprehension]#[expectedList]
                %% add tests form here...
                [A for _:A in 1#2#3              ]#[1 2 3]
                [A for _:A in 1#2#3 if A > 1     ]#[2 3]
                [A for _:A in Rec                ]#[a b c d]
                [A for _:A in Rec if A \= c      ]#[a b d]

                [B#A for _:A in Rec _:B in 1#2#3]
                #[1#a 2#b 3#c]

                [B#A for _:A in Rec _:B in 1#2#3 if B > 1]
                #[2#b 3#c]

                [A#B for _:A in Rec if A == a for _:B in 1#2#3]
                #[a#1 a#2 a#3]

                [A#B#C for _:A in Rec if A == a for _:B in 1#2#3 _:C in 4#5]
                #[a#1#4 a#2#5]

                [A+B for A in 1..2 _:B in 3#4]
                #[4 6]

                [A+B for A in 1..2 for _:B in 3#4]
                #[4 5 5 6]

                [A#F for F:A in rec(a:1 b:2)]
                #[1#a 2#b]

                [F for F:_ in 6#7#8]
                #[1 2 3]

                [A for _:A in 1#2#(3#4#(5#6)#7)#8]
                #[1 2 3 4 5 6 7 8]

                [A for _:A in [1 [2] [3 [4] 5] 6 [[7 [8]]]] if A \= nil]
                #[1 2 3 4 5 6 7 8]

                [F#A for F:A in r(a:1 b:2 cc:r(c:3 d:4 ee:r(e:5)))]
                #[a#1 b#2 c#3 d#4 e#5]

                [F#A for F:A in r(a:1 b:2 cc:r(c:3 d:4 ee:r(e:5))) if A \= 1]
                #[b#2 c#3 d#4 e#5]

                [F#A if F\= b for F:A in r(a:1 b:2 cc:r(c:3 d:4 ee:r(e:5))) if A \= 1]
                #[c#3 d#4 e#5]

                [A#B for _:A in 1#2#(3#4) for _:B in 10#r(20)]
                #[1#10 1#20 2#10 2#20 3#10 3#20 4#10 4#20]

                [1#A for _:A in r(1 2 a(3 4)) of fun{$ _ V} {Label V}\=a end]
                #[1#1 1#2 1#a(3 4)]

                [A for _:_ in r(1 r(2 3)) of fun{$ F _} F == 1 end A in 1..10]
                #[1 2]
                %% ...to here
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end
