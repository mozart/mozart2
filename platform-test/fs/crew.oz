functor $ prop once

import

   FS

   FD

   Search.{SearchOne  = 'SearchOne'}

   System.{Show = show}

export
   Return
body


   MakeEnumeration =
   proc {$ Ps}
      {List.forAllInd Ps proc {$ I V#_} V=I end}
   end

   Crew =
   fun {$ Data}
      Es
      [Tom#tom David#david Jeremy#jeremy Ron#ron
       Joe#joe Bill#bill Fred#fred Bob#bob Mario#mario
       Ed#ed Carol#carol Janet#janet Tracy#tracy
       Marilyn#marilyn Carolyn#carolyn Cathy#cathy
       Inez#inez Jean#jean Heather#heather Juliet#juliet] = Es
      {MakeEnumeration Es}

      Employees       = {Map Es fun {$ N#_} N end}
      Stewards        = {FS.value.new [Tom David Jeremy Ron Joe
                                       Bill Fred Bob Mario Ed]}
      Hostesses       = {FS.value.new [Carol Janet Tracy Marilyn
                                       Carolyn Cathy Inez Jean
                                       Heather Juliet]}
      FrenchSpeaking  = {FS.value.new [Inez Bill Jean Juliet]}
      GermanSpeaking  = {FS.value.new [Tom Jeremy Mario Cathy Juliet]}
      SpanishSpeaking = {FS.value.new [Bill Fred Joe Mario
                                       Marilyn Inez Heather]}

      TeamConstraint =
      proc {$ Team Flight}
         flight(_ N NStew NHost NFrench NSpanish NGerman) = Flight
      in
         {FS.card Team  N}
         {FS.card {FS.intersect Team Stewards}} >=: NStew
         {FS.card {FS.intersect Team Hostesses}} >=: NHost
         {FS.card {FS.intersect Team SpanishSpeaking}} >=: NSpanish
         {FS.card {FS.intersect Team FrenchSpeaking}} >=: NFrench
         {FS.card {FS.intersect Team GermanSpeaking}} >=: NGerman
      end

      SequencedDisjoint =
      proc {$ H L}
         case L
         of A|B|C|T then
            {FS.disjoint A B}
            {FS.disjoint A C}
            {SequencedDisjoint H B|C|T}
         elseof A|B|nil then
            {FS.disjoint A B}
            {FS.disjoint A H}
         else
            {Show 'Ooops'}
         end
      end

   in
      proc {$ Root}
         Flights = {MakeList {Length Data}}
      in
         Root = {List.zip Flights Data fun {$ A B} A#B end}

         {ForAll Flights
          proc {$ F} F = {FS.var.upperBound Employees} end}

         {ForAll
          {List.zip Flights Data fun {$ F D} F#D end}
          proc {$ F#D} {TeamConstraint F D} end}

         {SequencedDisjoint Flights.1 Flights}
         {FS.distribute naive Flights}
      end
   end % Crew

   Flights = [
             %flight(no crew stewards hostesses french spanish german
              flight(1  4    1        1         1      1       1)
              flight(2  5    1        1         1      1       1)
              flight(3  5    1        1         1      1       1)
              flight(4  6    2        2         1      1       1)
              flight(5  7    3        3         1      1       1)
              flight(6  4    1        1         1      1       1)
              flight(7  5    1        1         1      1       1)
              flight(8  6    1        1         1      1       1)
              flight(9  6    2        2         1      1       1)
              flight(10 7    3        3         1      1       1)
             ]

   CrewSol = [[
               {FS.value.new [1#3 17]}#flight(1 4 1 1 1 1 1)
               {FS.value.new [4#7 16]}#flight(2 5 1 1 1 1 1)
               {FS.value.new [8#11 18]}#flight(3 5 1 1 1 1 1)
               {FS.value.new [1#3 12#13 17]}#flight(4 6 2 2 1 1 1)
               {FS.value.new [4#7 14#16]}#flight(5 7 3 3 1 1 1)
               {FS.value.new [8#10 18]}#flight(6 4 1 1 1 1 1)
               {FS.value.new [1#3 11 17]}#flight(7 5 1 1 1 1 1)
               {FS.value.new [4#7 12 16]}#flight(8 6 1 1 1 1 1)
               {FS.value.new [8#10 13#14 18]}#flight(9 6 2 2 1 1 1)
               {FS.value.new [1#3 11 15 17 19]}#flight(10 7 3 3 1 1 1)
              ]]
   Return=
   fs([crew([
             one(equal(fun {$} {SearchOne {Crew Flights}} end CrewSol)
                 keys: [fs])
             one_entailed(entailed(proc {$} {SearchOne {Crew Flights} _} end)
                 keys: [fs entailed])
            ]
           )
      ]
     )
end
