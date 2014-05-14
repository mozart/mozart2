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
   ])
end
