%%
%% Author:
%%     Francois Fonteyn, 2014
%%

functor
import
   Application
   Tester at 'Tester.ozf'
   OS
define
   local
      %% EQtimeuivalent
      proc {PreLevel ?Result}
         local
            Next1
         in
            Result = '#'(1:Next1)
            {Level1 1 {Fun} '#'(1:Next1)}
         end
      end
      proc {Level1 B A ?Result}
         if B =< H then
            if B > 0 then
               local
                  Next1
               in
                  Result.1 = A|Next1
                  {Level1 B+1 {Fun} '#'(1:Next1)}
               end
            else
               {Level1 B+1 {Fun} Result}
            end
         else
            Result.1 = nil
         end
      end
      fun {Fun} 1 end
      H = 10000000
      fun {Measure LC}
         local T1 T2 L in
            if LC then
               %% LC
               T1 = {Time.time}
               L = [A for A from Fun B in 1..H if B > 0]
               T2 = {Time.time}
               {Browse {VirtualString.toAtom 'List comprehension took '#T2-T1#' seconds'}}
            else
               %% EQtime
               T1 = {Time.time}
               L = {PreLevel}
               T2 = {Time.time}
               {Browse {VirtualString.toAtom 'Equivalent         took '#T2-T1#' seconds'}}
            end
            T2-T1
         end
      end
      proc {Apply}
         if @EQnocc == 10 then
            LCnocc := @LCnocc + 1
            LCtime := @LCtime + {Measure true}
         elseif @LCnocc == 10 then
            EQnocc := @EQnocc + 1
            EQtime := @EQtime + {Measure false}
         else
            if {OS.rand} mod 2 == 0 then
               LCnocc := @LCnocc + 1
               LCtime := @LCtime + {Measure true}
            else
               EQnocc := @EQnocc + 1
               EQtime := @EQtime + {Measure false}
            end
         end
      end
      LCtime = {NewCell 0}
      LCnocc = {NewCell 0}
      EQtime = {NewCell 0}
      EQnocc = {NewCell 0}
      Browse = Tester.browse
   in
      {Browse 'Each technique will be tried 10 times in a random order'}
      for _ in 1..20 do {Apply} end
      {Browse {VirtualString.toAtom 'List comprehensions took '#@LCtime#' seconds in total'}}
      {Browse {VirtualString.toAtom 'Equivalents         took '#@EQtime#' seconds in total'}}
      {Application.exit 0}
   end
end

