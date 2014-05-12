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
      Cell = {NewCell 0}
      fun {Fun1} 2 end
      fun {Fun2} Cell := @Cell + {Fun1} @Cell end
      fun {Fun3 A} [A A+1 A+2] end
      Tests = [ %% each element is [listComprehension]#[expectedList]
                [A+B suchthat A#B in [1#2 3#4 5#6]]
                #[3 7 11]

                [A+B#C suchthat A#B in [1#2 3#4 5#6] suchthat C in 0 ; B+C<5 ; C+2]
                #[3#0 3#2 7#0]

                [A+B#C suchthat A#B in [1#2 3#4 5#6] suchthat C in 0 ; B+C<5 ; {Fun2}]
                #[3#0 3#2 7#0]

                [A+B#C suchthat A#B in [1#2 3#4 5#6] suchthat C in (Cell:=0 @Cell) ; B+@Cell<5 ; (Cell := @Cell + {Fun1} @Cell) ]
                #[3#0 3#2 7#0]

                [A#B suchthat A in 1..3 suchthat B in {Fun3 A}]
                #[1#1 1#2 1#3 2#2 2#3 2#4 3#3 3#4 3#5]

                [{Fun1} suchthat _ in [1 2 3 4 5]]
                #[2 2 2 2 2]

                [A suchthat A in [1 2 3] ; A\=nil ; A.2]
                #[[1 2 3] [2 3] [3]]

                [1 suchthat _ in (Cell:=0 @Cell) ; @Cell<5 ; (Cell:=@Cell+1 @Cell)]
                #[1 1 1 1 1]

                [{Fun1} suchthat _ in 1..5]
                #[2 2 2 2 2]

                [A suchthat A|_ in [[1 foo] [2 foo] [3 foo]]]
                #[1 2 3]

                [[A suchthat A in B ; A<10 ; A+1] suchthat B in 1..5]
                #[[1 2 3 4 5 6 7 8 9] [2 3 4 5 6 7 8 9] [3 4 5 6 7 8 9] [4 5 6 7 8 9] [5 6 7 8 9]]

                [a:[A suchthat A in B ; A<10 ; A+1] suchthat B in 1..5]
                #'#'(a:[[1 2 3 4 5 6 7 8 9] [2 3 4 5 6 7 8 9] [3 4 5 6 7 8 9] [4 5 6 7 8 9] [5 6 7 8 9]])

                [[A suchthat A in B ; A<10 ; A+1] [[C+A suchthat C in 1..2] suchthat A in B..B+3 ; 2] suchthat B in 1..5]
                #([[1 2 3 4 5 6 7 8 9] [2 3 4 5 6 7 8 9] [3 4 5 6 7 8 9] [4 5 6 7 8 9] [5 6 7 8 9]]
                  #[[[2 3] [4 5]] [[3 4] [5 6]] [[4 5] [6 7]] [[5 6] [7 8]] [[6 7] [8 9]]])

                ([A suchthat A in 1..2]#[A suchthat A in 3..4])
                #([1 2]#[3 4])

                [A B suchthat A in 1..2 B in 3..4]
                #([1 2]#[3 4])

                (1|[A suchthat A in 2..6])
                #[1 2 3 4 5 6]

                (1|2|[A suchthat A in 3..6])
                #[1 2 3 4 5 6]

                '|'(1:1 2:[A suchthat A in 2..6])
                #[1 2 3 4 5 6]
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end
