%%
%% Author:
%%     Francois Fonteyn, 2014
%%

functor
import
   Application
   OS
   Tester at 'Tester.ozf'
define
   local
      Browse = Tester.browse
      Pid = {OS.getPID}
      proc {PreLevel ?Result}
         local
            Next1 Next2
         in
            Result = '#'(a:Next1 b:Next2)
            {Level1 1 '#'(a:Next1 b:Next2)}
         end
      end
      proc {Level1 A ?Result}
         if A =< HA then
            {Level2 1 A Result}
         else
            Result.a = nil
            Result.b = nil
         end
      end
      proc {Level2 B A ?Result}
         if B =< HB then
            local
               Next1 Next2
            in
               Result.a = A|Next1
               Result.b = B|Next2
               {Level2 B+1 A '#'(a:Next1 b:Next2)}
            end
         else
            {Level1 A+1 Result}
         end
      end
      HA = 1000
      HB = 650
      fun {Measure LC}
         local M1 M2 L in
            if LC then
               %% LC
               M1 = {Tester.memory Pid} div 1000000
               L = [a:A b:B for A in 1..HA for B in 1..HB]
               M2 = {Tester.memory Pid} div 1000000
               {Browse {VirtualString.toAtom 'List comprehension added '#M2-M1#' extra MB'}}
            else
               %% Eq
               M1 = {Tester.memory Pid} div 1000000
               L = {PreLevel}
               M2 = {Tester.memory Pid} div 1000000
               {Browse {VirtualString.toAtom 'Equivalent         added '#M2-M1#' extra MB'}}
            end
            M2-M1
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
   in
      {Browse 'Each technique will be tried 10 times in a random order'}
      for _ in 1..20 do {Apply} end
      {Browse {VirtualString.toAtom 'List comprehensions added '#@LCtime#' extra MB in total'}}
      {Browse {VirtualString.toAtom 'Equivalents         added '#@EQtime#' extra MB in total'}}
      {Browse {VirtualString.toAtom 'The total memory taken at the end is '
               #{Tester.memory Pid} div 1000000#' MB'}}
      {Application.exit 0}
   end
end

