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

   Return = finalize([everyGC(EveryGC keys:[finalize])
                     ])
end
