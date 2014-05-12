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
      %% Equivalent
      proc {FindNext stacks(FeatStack ValueStack) ?Result}
         local
            Feat = FeatStack.1
            Value = ValueStack.1
            PoppedFeatStack = FeatStack.2
            PoppedValueStack = ValueStack.2
         in
            if {IsRecord Value} andthen {Arity Value} \= nil then
               {FindNext stacks({Append {Arity Value} PoppedFeatStack} {Append {Record.toList Value} PoppedValueStack}) Result}
            else
               Result = Feat#Value#stacks(PoppedFeatStack PoppedValueStack)
            end
         end
      end
      %% pre level
      proc {PreLevel ?Result}
         local
            Next1 Next2 Next3
         in
            Result = '#'(2:Next1 1:Next2 3:Next3)
            local
               Record1At1 = 10#20
            in
               {Level1 stacks({Arity Record1At1} {Record.toList Record1At1}) '#'(2:Next1 1:Next2 3:Next3)}
            end
         end
      end
      %% level 1
      proc {Level1 Stacks1At1 ?Result}
         if Stacks1At1.1 \= nil then
            local
               FA#A#NewStacks1At1 = {FindNext Stacks1At1}
            in
               local
                  Record1At2 = Rec
               in
                  {Level2 stacks({Arity Record1At2} {Record.toList Record1At2}) FA A NewStacks1At1 Result}
               end
            end
         else
            Result.2 = nil
            Result.1 = nil
            Result.3 = nil
         end
      end
      %% level 2
      proc {Level2 Stacks1At2 FA A Stacks1At1 ?Result}
         if Stacks1At2.1 \= nil then
            local
               _#B#NewStacks1At2 = {FindNext Stacks1At2}
            in
               local
                  Next1 Next2 Next3
               in
                  Result.2 = if A>10 then (FA#A)|Next1 else Next1 end
                  Result.1 = B|Next2
                  Result.3 = A#B|Next3
                  {Level2 NewStacks1At2 FA A Stacks1At1 '#'(2:Next1 1:Next2 3:Next3)}
               end
            end
         else
            {Level1 Stacks1At1 Result}
         end
      end
      Lim = 1500000
      Rec = {Record.make label [A suchthat A in 1..Lim]}
      for I in 1..Lim do
         Rec.I = I
      end
      fun {Measure LC}
         local T1 T2 L in
            if LC then
               %% LC
               T1 = {Time.time}
               L = [FA#A if A>10 1:B A#B suchthat FA:A in 10#20 suchthat _:B in Rec]
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

