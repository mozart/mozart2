functor prop once
import
   Foreign.pointer
   \insert Misc-new.env
   GetBuiltinInfo
   ImAVariableOccurrence
   Core
export
   CodeGen
body
   local
      \insert CodeEmitter
      \insert CodeStore
   in
      \insert CodeGen
   end
end
