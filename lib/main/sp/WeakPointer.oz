functor
import WD at 'x-oz://boot/WeakDictionary'
export
   make  : MakeWeakPointer
   is    : IsWeakPointer
   deref : DerefWeakPointer
define
   Table = {WD.new _} {WD.close Table}
   Tag   = {NewName}
   fun {MakeWeakPointer V}
      N = {NewName}
   in
      {WD.put Table N V}
      {Chunk.new weakPointer(Tag:N)}
   end
   fun {IsWeakPointer X}
      {HasFeature X Tag}
   end
   fun {DerefWeakPointer X}
      {WD.get Table X.Tag}
   end
end
