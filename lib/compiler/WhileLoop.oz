functor
export
   Compile
define
   fun{Compile fWhile(COND BODY COORDS)}
      fFOR([forFeature(fAtom('while' unit) COND)] BODY COORDS)
   end
end
