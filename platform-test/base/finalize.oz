functor
import
   System(gcDo)
   Finalize
export
   Return
define
   proc{RunGC Stop It}
      if It>0 then
         if {Not {IsDet Stop}} then
            {System.gcDo}
            {Delay 10}
            {RunGC Stop It-1}
         end
      else
         raise timeout end
      end
   end

   proc{EveryGC}
      V
      proc{T} V=unit end
   in
      {Finalize.everyGC T}
      thread {RunGC V 100} end
      {Wait V}
   end

   proc {Postmortem}
      class Dummy
         attr foo
         meth init() skip end
      end
      S P={NewPort S}
      Roots={NewDictionary}     % keeps entities alive
      State={NewDictionary}     % keeps track of which are/should be dead
      Check={NewDictionary}     % what State should be eventually
      proc {Add I X}
         Roots.I := X
         State.I := alive
         Check.I := alive
      end
      proc {Drop I}
         alive = State.I := dying     % atomic transition: alive -> dying
         alive = Check.I := dead      % what it should be after finalization
         {Dictionary.remove Roots I}
      end
      proc {Final I}
         dying = State.I := dead     % atomic transition: dying -> dead
      end
   in
      thread {ForAll S Final} end
      %% fill in dictionary, all objects must be alive
      for I in 1..10 do X={New Dummy init} in
         {Add I X} {Finalize.postmortem X P I}
      end
      {System.gcDo} {System.gcDo} {System.gcDo} {Delay 100}
      {Dictionary.toRecord foo State} = {Dictionary.toRecord foo Check}
      %% remove one element
      {Drop 7}
      {System.gcDo} {Delay 100}
      {IsDet S true} S=7|_
      {Dictionary.toRecord foo State} = {Dictionary.toRecord foo Check}
      %% remove another element
      {Drop 2}
      {System.gcDo} {Delay 100}
      {IsDet S.2 true} S=7|2|_
      {Dictionary.toRecord foo State} = {Dictionary.toRecord foo Check}
      %% remove a bunch of other objects
      {ForAll [3 5 6 10] Drop}
      {System.gcDo} {Delay 100}
      {Dictionary.toRecord foo State} = {Dictionary.toRecord foo Check}
      %% add some new ones
      for I in 11..15 do X={New Dummy init} in
         {Add I X} {Finalize.postmortem X P I}
      end
      %% remove some more
      {ForAll [1 8 12 14] Drop}
      {System.gcDo} {Delay 100}
      {Dictionary.toRecord foo State} = {Dictionary.toRecord foo Check}
      %% remove the remaining ones
      {ForAll [4 9 11 13 15] Drop}
      {System.gcDo} {Delay 100}
      {Dictionary.toRecord foo State} = {Dictionary.toRecord foo Check}
   end

   Return = finalize([everyGC(EveryGC keys:[finalize])
                      postmortem(Postmortem keys:[finalize])
                     ])
end
