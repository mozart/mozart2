functor
import
   System(gcDo)
export
   Return
define
   proc{RunGC Stop}
      if {Not {IsDet Stop}} then
         {System.gcDo}
         {Delay 10}
         {RunGC Stop}
      end
   end

   % Checks for bugs 593 & 596
   proc{Appear}
      S WD={NewWeakDictionary S}
      StopGC
   in
      thread {RunGC StopGC} end
      WD.gc:={NewName}
      case S of (gc#_)|_ then skip end
      StopGC=unit
   end

   proc{Key}
      S WD={NewWeakDictionary S}
      D={NewDictionary}
      Key={NewName}
      StopGC
   in
      thread {RunGC StopGC} end
      D.Key:=proc{$} skip end
      WD.Key:={NewName}
      case S of (_#_)|_ then skip end
      StopGC=unit
   end

   Return = weakdictionary([appear(Appear keys:[dictionary])
                            key(Key keys:[dictionary])
                           ])
end
