functor
import Macro(defmacro listToSequence:Sequify)
export BackquoteExpander
define
   fun {BackquoteExpander fMacro(_|L _) _}
      {Expand {Sequify L} 1}
   end
   fun {Expand E N}
      case E
      of fMacro(fAtom('`' _)|_ _) then {Quote E N+1}
      [] fMacro(fAtom(',' _)|L _) then
         if N==1 then {Sequify L} else {Quote E N-1} end
      else {Quote E N} end
   end
   fun {Quote E N}
      case E
      of unit then fAtom(unit unit)
      [] true then fAtom(true unit)
      [] false then fAtom(false unit)
      [] I andthen {IsInt I} then fInt(I unit)
      [] F andthen {IsFloat F} then fFloat(F unit)
      [] A andthen {IsAtom A} then fAtom(A unit)
      [] T andthen {IsTuple T} then
         fRecord(fAtom({Label T} unit)
                 {Map {Record.toList T} fun {$ E} {Expand E N} end})
      [] R andthen {IsRecord R} then
         fRecord(fAtom({Label R} unit)
                 {Map {Record.toListInd R}
                  fun {$ I E}
                     fColon(
                        if {IsInt I} then fInt(I unit)
                        else fAtom(I unit) end
                        {Expand E N})
                  end})
      end
   end
end
