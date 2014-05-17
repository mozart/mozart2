%%
%% Author:
%%     Francois Fonteyn, 2014
%%

functor

export
   Return

define
   Return =
   listComprehensions([
      recordGenerators(proc{$}
         Rec = rec(c:c b:b 1:a d:d)
      in
         [A suchthat _:A in 1#2#3              ] = [1 2 3]

         [A suchthat _:A in 1#2#3 if A > 1     ] = [2 3]

         [A suchthat _:A in Rec                ] = [a b c d]

         [A suchthat _:A in Rec if A \= c      ] = [a b d]

         [B#A suchthat _:A in Rec _:B in 1#2#3] = [1#a 2#b 3#c]

         [B#A suchthat _:A in Rec _:B in 1#2#3 if B > 1] = [2#b 3#c]

         [A#B suchthat _:A in Rec if A == a suchthat _:B in 1#2#3] = [a#1 a#2 a#3]

         [A#B#C suchthat _:A in Rec if A == a suchthat _:B in 1#2#3 _:C in 4#5] = [a#1#4 a#2#5]

         [A+B suchthat A in 1..2 _:B in 3#4] = [4 6]

         [A+B suchthat A in 1..2 suchthat _:B in 3#4] = [4 5 5 6]

         [A#F suchthat F:A in rec(a:1 b:2)] = [1#a 2#b]

         [F suchthat F:_ in 6#7#8] = [1 2 3]

         [A suchthat _:A in 1#2#(3#4#(5#6)#7)#8] = [1 2 3#4#(5#6)#7 8]
      end
      keys:[listComprehensions recordGenerators])
   ])
end
