functor
import
   ForLoop
export
   Compile
define
   fun{Compile fWhile(COND BODY COORDS)}
      fFOR([forFeature('while' COND)] BODY COORDS)
   end
end
