functor
require
   QTkImageLibBoot(
      makeImageLibraryBuilder : MakeImageLibraryBuilder)
   at 'QTkImageLibBoot.ozf'
prepare
   BuildLibrary =
   {MakeImageLibraryBuilder
    [newBitmap(file:"mini-inc.xbm")
     newBitmap(file:"mini-dec.xbm")]}
export
   BuildLibrary
end
