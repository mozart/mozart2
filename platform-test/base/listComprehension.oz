%%% Copyright © 2014, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% * Redistributions of source code must retain the above copyright notice,
%%% this list of conditions and the following disclaimer.
%%% * Redistributions in binary form must reproduce the above copyright notice,
%%% this list of conditions and the following disclaimer in the documentation
%%% and/or other materials provided with the distribution.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%% POSSIBILITY OF SUCH DAMAGE.

functor

import
   System(showInfo:Info)

export
   Return

define
   Return =
   listComprehensions([

      oneLevelOneLayer(proc{$}
         fun {Get0} 0 end
         fun {Get A} A end
         fun {Cond1 A} A<11 end
         fun {Cond2 A} A mod 2 == 0 end
         fun {Plus2 A} A+2 end
         L = [0 1 2 3 4 5 6 7 8 9 10]
      in
         [A suchthat A in 0..10                                ] = [0 1 2 3 4 5 6 7 8 9 10]
         [A suchthat A in 0..10 if A mod 2 == 0                ] = [0 2 4 6 8 10]
         [A suchthat A in 0..10 ; {Get 2}                      ] = [0 2 4 6 8 10]
         [A suchthat A in 0..10 ; 2 if A > 3                   ] = [4 6 8 10]
         [A suchthat A in 0 ; A<11 ; A+1                       ] = [0 1 2 3 4 5 6 7 8 9 10]
         [A suchthat A in 0 ; A<11 ; A+1 if A mod 2 == 0       ] = [0 2 4 6 8 10]
         [A suchthat A in {Get0} ; {Cond1 A} ; {Plus2 A}       ] = [0 2 4 6 8 10]
         [A suchthat A in {Get0} ; {Cond1 A} ; A+1 if {Cond2 A}] = [0 2 4 6 8 10]
         [A suchthat A in L                                    ] = [0 1 2 3 4 5 6 7 8 9 10]
         [A suchthat A in L if A mod 2 == 0                    ] = [0 2 4 6 8 10]
         [A suchthat A in [0 2 4 6 8 10]                       ] = [0 2 4 6 8 10]
         [A suchthat A in [0 1 2 3 4 5 6 7 8 9 10] if {Cond2 A}] = [0 2 4 6 8 10]
      end
      keys:[listComprehensions oneLevelOneLayer])

      oneLevelNLayer(proc{$}
         fun {Fun} 1 end
         fun {Get A} A end
         L = [A suchthat A in 0..10]
      in
         [[A B] suchthat A in 0..9   B in 10..19]
            = [[0 10] [1 11] [2 12] [3 13] [4 14] [5 15] [6 16] [7 17] [8 18] [9 19]]

         [[A B] suchthat A in 0..9   B in 10..19   if A > 2 andthen B < 15]
            = [[3 13] [4 14]]

         [[A B C] suchthat A in 0..9   B in 10..19   C in 20..29]
            = [[0 10 20] [1 11 21] [2 12 22] [3 13 23] [4 14 24] [5 15 25] [6 16 26] [7 17 27] [8 18 28] [9 19 29]]

         [[A B C] suchthat A in 0..9   B in 10..19   C in 20..29   if A+B+C > 33]
            = [[2 12 22] [3 13 23] [4 14 24] [5 15 25] [6 16 26] [7 17 27] [8 18 28] [9 19 29]]

         [[A B C] suchthat A in L   B in {Get 10}..19 ; 4   C in 20 ; C<3*B ; C+A]
            = [[0 10 20] [1 14 20] [2 18 21]]

         [[A B C] suchthat A in 1 ; A<3 ; A+1   B from Fun   C in [4 5 6]]
            = [[1 1 4] [2 1 5]]

         [[A B C] suchthat A in [1 2]   B in [3 4 5]   C in [6 7 8 9]]
            = [[1 3 6] [2 4 7]]

         [[A B C D] suchthat A in [1 2]   B in [3 4 5]   C in [6 7 8 9]   D in L]
            = [[1 3 6 0] [2 4 7 1]]

         [1 suchthat _ in [1 2]   _ in [3 4 5]   _ in [6 7 8 9]   _ in L]
            = [1 1]

         [A+B suchthat A in 1 ; A<10 ; 1   B in 1..4 ; 2]
            = [2 4]

         [A suchthat A in 1 ; A+1   _ in [1 1 1 1]]
            = [1 2 3 4]

         [A suchthat A in 1 ; A+1   _ in [1 1 1 1] if A < 4]
            = [1 2 3]
      end
      keys:[listComprehensions oneLevelNLayer])

      nLevelOneLayer(proc{$}
         [[A B] suchthat A in 1..2 suchthat B in 3..4]
            = [[1 3] [1 4] [2 3] [2 4]]

         [A#B#C suchthat A in [0 2] suchthat B in 4 ; B<10 ; B+2 suchthat C in 8..10 ; 2 if B<7]
            = [0#4#8 0#4#10 0#6#8 0#6#10 2#4#8 2#4#10 2#6#8 2#6#10]

         [A#B#C suchthat A in [0 2] if A<10 suchthat B in [4 6 7] suchthat C in [8 10] if B<7]
            = [0#4#8 0#4#10 0#6#8 0#6#10 2#4#8 2#4#10 2#6#8 2#6#10]

         [A#B#C suchthat A in 0..2 ; 2 if A<10 suchthat B in 4..7 ; 2 suchthat C in 8..10 ; 2 if B<7]
            = [0#4#8 0#4#10 0#6#8 0#6#10 2#4#8 2#4#10 2#6#8 2#6#10]

         [A#B#C suchthat A in 0 ; A=<2 ; A+2 if A<10 suchthat B in 4 ; B<7 ; B+2 suchthat C in 8 ; C=<10 ; C+2 if B<7]
            = [0#4#8 0#4#10 0#6#8 0#6#10 2#4#8 2#4#10 2#6#8 2#6#10]

         [1 suchthat _ in 1..2 suchthat _ in 1..2 suchthat _ in 1..2]
            = [1 1 1 1 1 1 1 1]

         [A+B-C suchthat A in 1..10 if A < 3 suchthat B in [3 4] suchthat C in A ; C<10 ; C+1 if C < 4]
            = [3 2 1 4 3 2 3 2 4 3]
      end
      keys:[listComprehensions nLevelOneLayer])

      nLevelNLayer(proc{$}
         fun {Fun} 1 end
      in
         [A#B#C#D#E suchthat A in 1..4 B in 11..13 if A+B<16 suchthat C in 1 ; C<10 ; C+2 D in [1 2] E in 30..100 if A+B+C+D+E<100]
            = [1#11#1#1#30 1#11#3#2#31 2#12#1#1#30 2#12#3#2#31]

         [A#B#C#D#E#F suchthat A in 1..4 B in 11..13 if A+B<16 suchthat C in 1 ; C<10 ; C+2 D in [1 2] E in 30..100 if A+B+C+D+E<100 suchthat F in 1..1]
            = [1#11#1#1#30#1 1#11#3#2#31#1 2#12#1#1#30#1 2#12#3#2#31#1]

         [A#B#C#D#E#F suchthat A in 1..4 B in 11..13 if A+B<16 suchthat C in 1 ; C<10 ; C+2 D in [1 2] E in 30..100 if A+B+C+D+E<100 suchthat F from Fun _ in 1..1]
            = [1#11#1#1#30#1 1#11#3#2#31#1 2#12#1#1#30#1 2#12#3#2#31#1]

         [[A AA B] suchthat A in 1..100 AA in [1 0 3] if A == AA suchthat B in [f o l o] if B \= l]
            = [[1 1 f] [1 1 o] [1 1 o] [3 3 f] [3 3 o] [3 3 o]]
      end
      keys:[listComprehensions nLevelNLayer])

      'from'(proc{$}
         C = {NewCell 0}
         fun {Fun0} 0 end
         fun {Fun1} 2 end
         fun {Fun2} C := @C + 1 @C end
      in
         [I*A suchthat A in [1 2 3] I from Fun1] = [2 4 6] % Cell = 0

         [I*A suchthat A in [1 2 3] I from Fun2] = [1 4 9] % Cell = 4

         [I*A#J*B suchthat A in [1 2 3] I from Fun2 suchthat B in 1..2 J from Fun2] = [5#6 5#14 18#10 18#22 39#14 39#30]

         [A suchthat _ in 1..1 A from Fun1] = [2]

         [Z+Y suchthat Z from Fun0 _ in 1..2 suchthat _ in [1 2] Y from Fun1] = [2 2 2 2]

         [Z*Y suchthat Z from Fun0 A in 1..2 if A < 2 suchthat _ in [1 2] Y from Fun1] = [0 0]

         [Z+Y suchthat Z from Fun0 A in 1..2 if A < 2 suchthat _ in [1 2] Y from Fun1 if Y == 1] = nil

         [Z+Y suchthat Z from Fun0 A in 1..2 if A < 2 suchthat _ in [1 2] Y from Fun1 if Y == {Fun1}] = [2 2]

         [A suchthat A from fun{$} 1 end _ in 1..2] = [1 1]
      end
      keys:[listComprehensions 'from'])

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

      erlang(proc{$}
         N = 12
         fun {Fun X} 2*X end
         L  = [1 2 3 4]
         LL = [[1 2] [3 4]]
      in
         %% [X || X <- [1,2,a,3,4], X > 3]
         [X suchthat X in [1 2 &a 3 4] if X > 3]
            = [&a 4]

         %% [X || X <- [1,2,a,3,4], integer(X), X > 3]
         [X suchthat X in [1 2 a 3 4] if {IsInt X} andthen X > 3]
            = [4]

         %% [X || X <- [1,5,2,7,3,6,4], X >= 4]
         [X suchthat X in [1 5 2 7 3 6 4] if X >= 4]
            = [5 7 6 4]

         %% [{A,B,C} || A <- lists:seq(1,12), B <- lists:seq(1,12), C <- lists:seq(1,12), A+B+C =< 12, A*A+B*B == C*C]
         [A#B#C suchthat A in 1..12 suchthat B in 1..12 suchthat C in 1..12 if A+B+C =< 12 andthen A*A+B*B == C*C]
            = [3#4#5 4#3#5]

         %% [{A,B,C} || A <- lists:seq(1,N-2), B <- lists:seq(A+1,N-1), C <- lists:seq(B+1,N), A+B+C =< N, A*A+B*B == C*C]
         [A#B#C suchthat A in 1..N-2 suchthat B in A+1..N-1 suchthat C in B+1..N if A+B+C =< N andthen A*A+B*B == C*C]
            = [3#4#5]

         %% [Fun(X) || X <- L]
         [{Fun X} suchthat X in L]
            = [2 4 6 8]

         %% [X || L1 <- LL, X <- L1]
         [X suchthat L1 in LL suchthat X in L1]
            = [1 2 3 4]

         %% [Y || {X, Y} <- LL, X == 1]
         [Y suchthat [X Y] in LL if X == 1]
            = [2]
      end
      keys:[listComprehensions erlang])

      haskell(proc{$}
         L = [2 4 7]
         Pairs = [2#3 2#1 7#8]
         fun {IsEven A} A mod 2 == 0 end
      in
         %% [2*a | a <- L]
         [2*A suchthat A in L] = [4 8 14]

         %% [isEven a | a <- L]
         [{IsEven A} suchthat A in L] = [true true false]

         %% [2*a | a <- L, isEven a, a>3]
         [2*A suchthat A in L if {IsEven A} andthen A>3] = [8]

         %% [a+b | (a,b) <- Pairs]
         [A+B suchthat A#B in Pairs] = [5 3 15]

         %% [a+b | (a,b) <- Pairs, a<b]
         [A+B suchthat A#B in Pairs if A<B] = [5 15]

         %% [(i,j) | i <- [1,2], j <- [1..4]]
         [[I J] suchthat I in [1 2] suchthat J in 1..4] = [[1 1] [1 2] [1 3] [1 4] [2 1] [2 2] [2 3] [2 4]]

         %% [[ (i,j) | i <- [1,2]] | j <- [3,4]]
         [[[I J] suchthat I in 1..2] suchthat J in 3..4] = [[[1 3] [2 3]] [[1 4] [2 4]]]

         %% take 5 [[ (i,j) | i <- [1,2]] | j <- [1...]]
         [[[I J] suchthat I in 1..2] suchthat J in 1 ; J+1 _ in 1..5] % '_ in 1..5' replaces 'take 5'
            = [[[1 1] [2 1]] [[1 2] [2 2]] [[1 3] [2 3]] [[1 4] [2 4]] [[1 5] [2 5]]]
      end
      keys:[listComprehensions haskell])

      python(proc{$}
         Li = [~8 ~4 0 4 8]
         Vec = [[1 2 3] [4 5 6] [7 8 9]]
         Matrix = [[1 2 3 4] [5 6 7 8] [9 10 11 12]]
      in
         %% [x**2 suchthat x in range(10)]
         [{Pow X 2} suchthat X in 1..9]
            = [1 4 9 16 25 36 49 64 81]

         %% [x suchthat x in Li if x >= 0]
         [X suchthat X in Li if X >= 0]
            = [0 4 8]

         %% [abs(x) suchthat x in Li]
         [{Abs X} suchthat X in Li]
            = [8 4 0 4 8]

         %% [(x, x**2) suchthat x in range(6)]
         [[X {Pow X 2}] suchthat X in 0..5]
            = [[0 0] [1 1] [2 4] [3 9] [4 16] [5 25]]

         %% [x suchthat x in (1,2,3)]
         [X suchthat _:X in '#'(1 2 3)]
            = [1 2 3]

         %% [(x, y) suchthat x in [1,2,3] suchthat y in [3,1,4] if x != y]
         [[X Y] suchthat X in [1 2 3] suchthat Y in [3 1 4] if X \= Y]
            = [[1 3] [1 4] [2 3] [2 1] [2 4] [3 1] [3 4]]

         %% [num suchthat elem in Vec suchthat num in elem]
         [Num suchthat Elem in Vec suchthat Num in Elem]
            = [1 2 3 4 5 6 7 8 9]

         %% [[row[i] suchthat row in matrix] suchthat i in range(4)]
         [[{Nth Row I} suchthat Row in Matrix] suchthat I in 1..4]
            = [[1 5 9] [2 6 10] [3 7 11] [4 8 12]]

         %% [a suchthat a in (1,2,3)]
         [A suchthat _:A in tuple(1 2 3)]
            = [1 2 3]
      end
      keys:[listComprehensions python])

      multiOutput(proc{$}
         [A A+3 suchthat A in 1..3]
            = ([1 2 3]#[4 5 6])

         [A B suchthat A in 1..3 B in 4..6]
            = ([1 2 3]#[4 5 6])

         [A B suchthat A in 1..3 B in 4..6 if A+B<9]
            = ([1 2]#[4 5])

         [A B C suchthat A in 1..2 suchthat B in 3..4 suchthat C in 5..6]
            = ([1 1 1 1 2 2 2 2]#[3 3 4 4 3 3 4 4]#[5 6 5 6 5 6 5 6])

         [A B C suchthat A in 1..2 B in 3..4 C in 5..6]
            = ([1 2]#[3 4]#[5 6])

         [A B C D suchthat A in 1..2 B in 3..4 C in 5..6 D in 7..8]
            = ([1 2]#[3 4]#[5 6]#[7 8])

         [A B C suchthat A in 1..2 suchthat B in 3..4 C in 5..6]
            = ([1 1 2 2]#[3 4 3 4]#[5 6 5 6])
      end
      keys:[listComprehensions multiOutput])

      labeledOutput(proc{$}
         [A suchthat A in 0..10]
            = [0 1 2 3 4 5 6 7 8 9 10]

         [a:A suchthat A in 0..10]
            = '#'(a:[0 1 2 3 4 5 6 7 8 9 10])

         [whatever:A suchthat A in 0..10]
            = '#'(whatever:[0 1 2 3 4 5 6 7 8 9 10])

         [a:A 2*A suchthat A in 0 ; A<11 ; A+1]
            = '#'(1:[0 2 4 6 8 10 12 14 16 18 20] a:[0 1 2 3 4 5 6 7 8 9 10])

         [1:A 2*A suchthat A in 0 ; A<11 ; A+1]
            = '#'(1:[0 1 2 3 4 5 6 7 8 9 10] 2:[0 2 4 6 8 10 12 14 16 18 20])

         [A 2*A suchthat A in 0 ; A<11 ; A+1]
            = ([0 1 2 3 4 5 6 7 8 9 10]#[0 2 4 6 8 10 12 14 16 18 20])

         [a:A 2*A b:A suchthat A in 0 ; A<11 ; A+1]
            = '#'(1:[0 2 4 6 8 10 12 14 16 18 20] a:[0 1 2 3 4 5 6 7 8 9 10] b:[0 1 2 3 4 5 6 7 8 9 10])

         [3:A+1 1:2*A A suchthat A in [A suchthat A in 0..10]]
            = '#'(1:[0 2 4 6 8 10 12 14 16 18 20] 2:[0 1 2 3 4 5 6 7 8 9 10] 3:[1 2 3 4 5 6 7 8 9 10 11])
      end
      keys:[listComprehensions labeledOutput])

      outputCondition(proc{$}
         [X if X<3 suchthat X in [1 2 3 4]]
            = [1 2]

         [a:X if X<3 Y if Y>4 suchthat X in [1 2 3 4] Y in [5 6 7 8]]
            = ('#'(a:[1 2] 1:[5 6 7 8]))

         [X if X>3 Y if Y>7 suchthat X in [1 2] suchthat Y in [5 6 7 8]]
            = ('#'(1:nil 2:[8 8]))

         [smallerEqual:A if A=<4 bigger:A if A>4 suchthat A in [2 5 4 3 6 1 7]]
            = '#'(smallerEqual:[2 4 3 1] bigger:[5 6 7])

         [A if B>2 suchthat A in [so hello world] B in [2 3 4]]
            = [hello world]
      end
      keys:[listComprehensions outputCondition])

      lazy(proc{$}
         fun {LazyAssert TestResult Expected Batch}
            N = {Length Expected}
            NB = N div Batch
            Okay
         in
            for I in 1..NB break:B do
               if {IsDet {Nth TestResult I*Batch}} then
                  {Info 'Lazy error'}
                  Okay = unit
                  {B}
               end
               for J in 1+(I-1)*Batch..I*Batch do
                  Exp1 = {Nth TestResult J}
                  Exp2 = {Nth Expected J}
               in
                  Exp1 = Exp2
               end
            end
            {Not {IsDet Okay}}
         end
         fun {Fun} 1 end
         C = {NewCell _}
         CC = {NewCell _}
      in
         C := thread [A suchthat lazy A in 1..3] end {Delay 50}
         if {LazyAssert @C [1 2 3] 1} then C := 1 else C := 0 end @C = 1

         C := thread [A A+1 suchthat lazy A in 1..3] end {Delay 50}
         CC := @C.1
         if {LazyAssert @C.2 [2 3 4] 1} then C := 1 else C := 0 end @C = 1
         @CC = [1 2 3]

         C := thread [A+B suchthat lazy A in 1..2 suchthat B in [1 2 3]] end {Delay 50}
         if {LazyAssert @C [2 3 4 3 4 5] 3} then C := 1 else C := 0 end @C = 1

         C := thread [A+B suchthat A in 1..2 suchthat lazy B in [B suchthat A in 1..1 suchthat B in [A suchthat A in 1..3]]] end {Delay 50}
         if {LazyAssert @C [2 3 4 3 4 5] 1} then C := 1 else C := 0 end @C = 1

         C := thread [A+B suchthat lazy A in 1..2 suchthat lazy B in 1..3] end {Delay 50}
         if {LazyAssert @C [2 3 4 3 4 5] 1} then C := 1 else C := 0 end @C = 1

         C := thread [A+B suchthat A in 1..2 suchthat lazy B in 1..3 if A > 1] end {Delay 50}
         if {LazyAssert @C [3 4 5] 1} then C := 1 else C := 0 end @C = 1

         C := thread [A+B#C+D suchthat lazy A in 1..2 B in 3..4 suchthat C in [1 2 3 4] D in 3 ; D<6 ; D+1 if D<5] end {Delay 50}
         if {LazyAssert @C [4#4 4#6 6#4 6#6] 2} then C := 1 else C := 0 end @C = 1

         C := thread [A suchthat lazy A from Fun _ in 1..3] end {Delay 50}
         if {LazyAssert @C [1 1 1] 1} then C := 1 else C := 0 end @C = 1
      end
      keys:[listComprehensions lazy])

      body(proc{$}
         C = {NewCell _}
      in
         [@C suchthat A in 1..2 do C:=A] = [1 2]

         [@C suchthat A in 1..2 do C:=A C:=@C*A] = [1 4]

         [@C suchthat A in 1..2 if A > 1 do C:=A] = [2]

         [@C if @C > 1 suchthat A in 1..2 do C:=A] = [2]

         [@C-1 suchthat A in 1..2 do C:=A+1] = [1 2]

         [@C suchthat _ in 1..1 A from fun{$} 1 end do C:=A] = [1]

         [@C suchthat _:A in r(r(r(1) r(2))) do C:=A] = [r(r(1) r(2))]

         [@C suchthat A in 1..2 suchthat B in 1..2 do C:=A+B] = [2 3 3 4]
      end
      keys:[listComprehensions body])

      bodyLazy(proc{$}
         fun {LazyAssert TestResult Expected Batch}
            N = {Length Expected}
            NB = N div Batch
            Okay
         in
            for I in 1..NB break:B do
               if {IsDet {Nth TestResult I*Batch}} then
                  {Info 'Lazy error'}
                  Okay = unit
                  {B}
               end
               for J in 1+(I-1)*Batch..I*Batch do
                  Exp1 = {Nth TestResult J}
                  Exp2 = {Nth Expected J}
               in
                  Exp1 = Exp2
               end
            end
            {Not {IsDet Okay}}
         end
         C = {NewCell _}
         L1 = thread [@C suchthat lazy A in 1..2 do C:=A] end
         L2 = thread [@C suchthat lazy A in 1..2 do C:=A C:=@C*A] end
         L3 = thread [@C suchthat lazy A in 1..2 if A > 1 do C:=A] end
         L4 = thread [@C if @C > 1 suchthat lazy A in 1..2 do C:=A] end
         L5 = thread [@C suchthat lazy A in 1..2 suchthat B in 1..2 do C:=A+B] end
      in
         {Delay 50}
         if {LazyAssert L1 [1 2] 1} then C := 1 else C := 0 end @C = 1
         if {LazyAssert L2 [1 4] 1} then C := 1 else C := 0 end @C = 1
         if {LazyAssert L3 [2] 1} then C := 1 else C := 0 end @C = 1
         if {LazyAssert L4 [2] 1} then C := 1 else C := 0 end @C = 1
         if {LazyAssert L5 [2 3 3 4] 2} then C := 1 else C := 0 end @C = 1
      end
      keys:[listComprehensions bodyLazy])

      miscellaneous(proc{$}
         Cell = {NewCell 0}
         fun {Fun1} 2 end
         fun {Fun2} Cell := @Cell + {Fun1} @Cell end
         fun {Fun3 A} [A A+1 A+2] end
      in
         [A+B suchthat A#B in [1#2 3#4 5#6]]
            = [3 7 11]

         [A+B#C suchthat A#B in [1#2 3#4 5#6] suchthat C in 0 ; B+C<5 ; C+2]
            = [3#0 3#2 7#0]

         [A+B#C suchthat A#B in [1#2 3#4 5#6] suchthat C in 0 ; B+C<5 ; {Fun2}]
            = [3#0 3#2 7#0]

         [A+B#C suchthat A#B in [1#2 3#4 5#6] suchthat C in (Cell:=0 @Cell) ; B+@Cell<5 ; (Cell := @Cell + {Fun1} @Cell) ]
            = [3#0 3#2 7#0]

         [A#B suchthat A in 1..3 suchthat B in {Fun3 A}]
            = [1#1 1#2 1#3 2#2 2#3 2#4 3#3 3#4 3#5]

         [{Fun1} suchthat _ in [1 2 3 4 5]]
            = [2 2 2 2 2]

         [A suchthat A in [1 2 3] ; A\=nil ; A.2]
            = [[1 2 3] [2 3] [3]]

         [1 suchthat _ in (Cell:=0 @Cell) ; @Cell<5 ; (Cell:=@Cell+1 @Cell)]
            = [1 1 1 1 1]

         [{Fun1} suchthat _ in 1..5]
            = [2 2 2 2 2]

         [A suchthat A|_ in [[1 foo] [2 foo] [3 foo]]]
            = [1 2 3]

         [[A suchthat A in B ; A<10 ; A+1] suchthat B in 1..5]
            = [[1 2 3 4 5 6 7 8 9] [2 3 4 5 6 7 8 9] [3 4 5 6 7 8 9] [4 5 6 7 8 9] [5 6 7 8 9]]

         [a:[A suchthat A in B ; A<10 ; A+1] suchthat B in 1..5]
            = '#'(a:[[1 2 3 4 5 6 7 8 9] [2 3 4 5 6 7 8 9] [3 4 5 6 7 8 9] [4 5 6 7 8 9] [5 6 7 8 9]])

         [[A suchthat A in B ; A<10 ; A+1] [[C+A suchthat C in 1..2] suchthat A in B..B+3 ; 2] suchthat B in 1..5]
            = ([[1 2 3 4 5 6 7 8 9] [2 3 4 5 6 7 8 9] [3 4 5 6 7 8 9] [4 5 6 7 8 9] [5 6 7 8 9]]#[[[2 3] [4 5]] [[3 4] [5 6]] [[4 5] [6 7]] [[5 6] [7 8]] [[6 7] [8 9]]])

         ([A suchthat A in 1..2]#[A suchthat A in 3..4])
            = ([1 2]#[3 4])

         [A B suchthat A in 1..2 B in 3..4]
            = ([1 2]#[3 4])

         (1|[A suchthat A in 2..6])
            = [1 2 3 4 5 6]

         (1|2|[A suchthat A in 3..6])
            = [1 2 3 4 5 6]

         '|'(1:1 2:[A suchthat A in 2..6])
            = [1 2 3 4 5 6]
      end
      keys:[listComprehensions miscellaneous])

   ])
end
