%%
%% Author:
%%     Francois Fonteyn, 2014
%%
%% Sources:
%%     http://www.erlang.org/doc/programming_examples/list_comprehensions.html
%%     Armstong, J., Virding, R., Wikstrom, C., "Concurrent programming in Erlang", Prentice Hall, 1996.
%%

functor

export
   Return

define
   Return =
   listComprehensions([
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
   ])
end
