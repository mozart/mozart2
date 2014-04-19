%%
%% Author:
%%     Francois Fonteyn, 2014
%%
%% Sources:
%%     http://www.erlang.org/doc/programming_examples/list_comprehensions.html
%%     Armstong, J., Virding, R., Wikstrom, C., "Concurrent programming in Erlang", Prentice Hall, 1996. 
%%

functor
import
   Application
   Tester at 'Tester.ozf'
define
   local
      N = 12
      fun {Fun X} 2*X end
      L = [1 2 3 4]
      LL = [[1 2] [3 4]]
      Tests = [
               %% [X || X <- [1,2,a,3,4], X > 3]
               [X for X in [1 2 &a 3 4] if X > 3]
               #[&a 4]

               %% [X || X <- [1,2,a,3,4], integer(X), X > 3]
               [X for X in [1 2 a 3 4] if {IsInt X} andthen X > 3]
               #[4]

               %% [X || X <- [1,5,2,7,3,6,4], X >= 4]
               [X for X in [1 5 2 7 3 6 4] if X >= 4]
               #[5 7 6 4]

               %% [{A,B,C} || A <- lists:seq(1,12), B <- lists:seq(1,12), C <- lists:seq(1,12), A+B+C =< 12, A*A+B*B == C*C]
               [A#B#C for A in 1..12 for B in 1..12 for C in 1..12 if A+B+C =< 12 andthen A*A+B*B == C*C]
               #[3#4#5 4#3#5]

               %% [{A,B,C} || A <- lists:seq(1,N-2), B <- lists:seq(A+1,N-1), C <- lists:seq(B+1,N), A+B+C =< N, A*A+B*B == C*C]
               [A#B#C for A in 1..N-2 for B in A+1..N-1 for C in B+1..N if A+B+C =< N andthen A*A+B*B == C*C]
               #[3#4#5]

               %% [Fun(X) || X <- L]
               [{Fun X} for X in L]
               #[2 4 6 8]

               %% [X || L1 <- LL, X <- L1]
               [X for L1 in LL for X in L1]
               #[1 2 3 4]

               %% [Y || {X, Y} <- LL, X == 1]
               [Y for [X Y] in LL if X == 1]#[2]
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end
