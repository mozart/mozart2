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
      proc {PreLevel ?Result}
         local
            Next1 Next2
         in
            Result = '#'(1:Next1 a:Next2)
            {Level1 1 '#'(1:Next1 a:Next2)}
         end
      end
      %% level 1
      proc {Level1 A ?Result}
         if A<CA then
            if A>4 then
               {Level2 2*A A Result}
            else
               {Level1 A+1 Result}
            end
         else
            Result.1 = nil
            Result.a = nil
         end
      end
      %% level 2
      proc {Level2 B A ?Result}
         if B=<CB then
            if A+B>5 then
               local
                  Rec = 1#2#3#4#5#6#7#8#9#10
               in
                  {Level3 stacks({Arity Rec} {Record.toList Rec}) B A Result}
               end
            else
               {Level2 B+2 A Result}
            end
         else
            {Level1 A+1 Result}
         end
      end
      %% level 3
      proc {Level3 Stacks B A ?Result}
         if Stacks.1 \= nil then
            local
               _#C#NewStacks = {FindNext Stacks}
            in
               if C == 3 then
                  local
                     Next1 Next2
                  in
                     Result.1 = A+B|Next1
                     Result.a = A|Next2
                     {Level3 NewStacks B A '#'(1:Next1 a:Next2)}
                  end
               else
                  {Level3 NewStacks B A Result}
               end
            end
         else
            {Level2 B+2 A Result}
         end
      end
      CA = 2000
      CB = 2000
      fun {Measure LC}
         local T1 T2 L in
            if LC then
               %% LC
               T1 = {Time.time}
               L = [A+B a:A if A>0 suchthat A in 1 ; A<CA ; A+1 if A>4 suchthat B in 2*A..CB ; 2 if A+B>5 suchthat _:C in 1#2#3#4#5#6#7#8#9#10 if C == 3]
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

