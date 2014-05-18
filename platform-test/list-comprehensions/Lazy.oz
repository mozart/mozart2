%%
%% Author:
%%     Francois Fonteyn, 2014
%%

functor

import
   System(showInfo:Info)

export
   Return

define
   Return =
   listComprehensions([
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
   ])
end
