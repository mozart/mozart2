functor
import
   DPB at 'x-oz://boot/DPB'
   C_DPMisc at 'x-oz://boot/DPMisc'
export
   SetDGC
   GetDGC
define
   %%
   %% Force linking of base library
   %%
   {Wait DPB}

   fun{SetDGC E Algs}
      case {GetDGC E} of local_entity then
         local_entity
      elseof persistent then
         persistent == persistent
      elseof A then
         Algs2 = if Algs == persistent then nil else Algs end
      in
         if {All Algs2 fun{$ M} {Member M A} end} then
            {ForAll
             {Filter A fun{$ M} {Not {Member M Algs2}} end}
             proc{$ Al}
                {C_DPMisc.setDGC  E Al _}
             end}
            true
         else
            false
         end
      end
   end
   fun{GetDGC E}
      case {C_DPMisc.getDGC E} of
         nil then persistent
      elseof local_entity then
         local_entity
      elseof A then
         {Map A fun{$ V} V.1 end}
      end
   end
end
