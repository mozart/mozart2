%%
%% Author:
%%     Francois Fonteyn, 2014
%%
%% Source:
%%     http://docs.python.org/2/tutorial/datastructures.html#list-comprehensions
%%

functor
import
   Application
   Tester at 'Tester.ozf'
define
   local
      Li = [~8 ~4 0 4 8]
      Vec = [[1 2 3] [4 5 6] [7 8 9]]
      Matrix = [[1 2 3 4] [5 6 7 8] [9 10 11 12]]
      Tests = [
               %% [x**2 suchthat x in range(10)]
               [{Pow X 2} suchthat X in 1..9]
               #[1 4 9 16 25 36 49 64 81]

               %% [x suchthat x in Li if x >= 0]
               [X suchthat X in Li if X >= 0]
               #[0 4 8]

               %% [abs(x) suchthat x in Li]
               [{Abs X} suchthat X in Li]
               #[8 4 0 4 8]

               %% [(x, x**2) suchthat x in range(6)]
               [[X {Pow X 2}] suchthat X in 0..5]
               #[[0 0] [1 1] [2 4] [3 9] [4 16] [5 25]]

               %% [x suchthat x in (1,2,3)]
               [X suchthat _:X in '#'(1 2 3)]
               #[1 2 3]

               %% [(x, y) suchthat x in [1,2,3] suchthat y in [3,1,4] if x != y]
               [[X Y] suchthat X in [1 2 3] suchthat Y in [3 1 4] if X \= Y]
               #[[1 3] [1 4] [2 3] [2 1] [2 4] [3 1] [3 4]]

               %% [num suchthat elem in Vec suchthat num in elem]
               [Num suchthat Elem in Vec suchthat Num in Elem]
               #[1 2 3 4 5 6 7 8 9]

               %% [[row[i] suchthat row in matrix] suchthat i in range(4)]
               [[{Nth Row I} suchthat Row in Matrix] suchthat I in 1..4]
               #[[1 5 9] [2 6 10] [3 7 11] [4 8 12]]

               %% [a suchthat a in (1,2,3)]
               [A suchthat _:A in tuple(1 2 3)]
               #[1 2 3]
              ]
   in
      {Tester.test Tests}
      {Application.exit 0}
   end
end