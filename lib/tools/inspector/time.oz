local
   fun {GetTime}
      T={System.get time}
   in
      time(copy:      T.copy
           gc:        T.gc
           propagate: T.propagate
           run:       T.run
           total:     T.user+T.system
           wall:      T.total)
   end

   fun {TimeDiff T2 T1}
      {Record.zip T2 T1 Number.'-'}
   end

   fun {TakeTime P}
      T1 T2
   in
      {System.gcDo} {System.gcDo}
      {System.gcDo} {System.gcDo}
      T1={GetTime}
      {P}
      T2={GetTime}
      {TimeDiff T2 T1}
   end

   fun {TakeAll N P}
      case N==0 then nil else
         {TakeTime P}|{TakeAll N-1 P}
      end
   end

   local
      proc {Run N P}
         case N==0 then skip else {P} {Run N-1 P} end
      end
   in
      fun {TakeMultiDiff N P1 P2}
         proc {MP1}
            {Run N P1}
         end
         proc {MP2}
            {Run N P2}
         end
      in
         {TimeDiff {TakeTime MP1} {TakeTime MP2}}
      end
   end

   fun {TakeMultiAll N M P1 P2}
      case N==0 then nil else
         {TakeMultiDiff M P1 P2}|{TakeMultiAll N-1 M P1 P2}
      end
   end

in

   Timing = timing(take:    TakeTime
                   diff:    TimeDiff
                   all:     TakeAll
                   against: TakeMultiAll)

end
