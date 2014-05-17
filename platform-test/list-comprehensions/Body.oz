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
   ])
end
