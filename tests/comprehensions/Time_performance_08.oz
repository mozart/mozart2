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
      proc {PreLevel ?Result}
         local
            Next1 Next2 Next3
         in
            Result = '#'(2:Next1 1:Next2 3:Next3)
            local
               Record = Rec
            in
               {Level {Arity Record}#Record '#'(2:Next1 1:Next2 3:Next3)}
            end
         end
      end
      %% for2
      proc {For2 Ari Rec Result AriBool}
         if Ari \= nil then
            if AriBool.1 then
               local
                  Feat = Ari.1
                  Field = Rec.Feat
               in
                  if {IsRecord Field} then
                     {Level {Arity Field}#Field '#'(2:Result.2.Feat 1:Result.1.Feat 3:Result.3.Feat)}
                  else
                     Result.2.Feat = Field + 2
                     Result.1.Feat = Field + 1
                     Result.3.Feat = Field + 3
                  end
               end
               {For2 Ari.2 Rec Result AriBool.2}
            else
               {For2 Ari Rec Result AriBool.2}
            end
         end
      end
      %% for1
      proc {For1 Ari Rec AriFull AriBool}
         if Ari \= nil then
            local
               Feat = Ari.1
               Field = Rec.Feat
               NextFull
               NextBool
            in
               AriBool = ({Not {IsRecord Field}} orelse {Label Field} \= r1)|NextBool
               AriFull = if AriBool.1 then Feat|NextFull else NextFull end
               {For1 Ari.2 Rec NextFull NextBool}
            end
         else
            AriFull = nil
            AriBool = nil
         end
      end
      %% level
      proc {Level Ari#Rec ?Result}
         local
            Lbl = {Label Rec}
            AriFull
            AriBool
         in
            {For1 Ari Rec AriFull AriBool}
            Result.2 = {Record.make Lbl AriFull}
            Result.1 = {Record.make Lbl AriFull}
            Result.3 = {Record.make Lbl AriFull}
            {For2 AriFull Rec Result AriBool}
         end
      end
      Lim = 500000 
      Rec = {Record.make label [A for A in 1..Lim]}
      for I in 1..Lim do
         Rec.I = I
      end
      fun {Measure LC}
         local T1 T2 L in
            if LC then
               %% LC
               T1 = {Time.time}
               L = [2:A+2 1:A+1 3:A+3 for F:A through Rec if F > 0]
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

