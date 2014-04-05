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
      %% Equivalent
      Cell1 = {NewCell _}
      Cell2 = {NewCell _}
      %%
      proc {C1 X} N in {Exchange Cell1 X|N N} end
      proc {C2 X} N in {Exchange Cell2 X|N N} end
      %% pre level
      proc {PreLevel ?Result}
         Result = '#'(1:@Cell1 2:@Cell2)
         {Level1 1 '#'()}
      end
      %% level 1
      proc {Level1 A ?Result}
         if A =< Lim then
            {C1 A}{C1 A+1}{C2 yes}{C2 no}
            {Level1 A+1 '#'()}
         else
            {Exchange Cell1 nil _}
            {Exchange Cell2 nil _}
         end
      end
      Lim = 4000000
      fun {Measure LC}
         local T1 T2 L in
            if LC then
               %% LC
               T1 = {Time.time}
               L =  [1:collect:C1 2:collect:C2 for A in 1..Lim body {C1 A}{C1 A+1}{C2 yes}{C2 no}]
               T2 = {Time.time}
               {Browse {VirtualString.toAtom 'List comprehension took '#T2-T1#' seconds'}}
            else
               %% Eq
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
   in
      {Browse 'Each technique will be tried 10 times in a random order'}
      for _ in 1..20 do {Apply} end
      {Browse {VirtualString.toAtom 'List comprehensions took '#@LCtime#' seconds in total'}}
      {Browse {VirtualString.toAtom 'Equivalents         took '#@EQtime#' seconds in total'}}
      {Application.exit 0}
   end
end

