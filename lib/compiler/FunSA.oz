functor prop once
import
   FD.{int is less distinct distribute}
   FS.{include var subset value reflect isIn}
   Search.{SearchOne='SearchOne'}
   Foreign.pointer
   System.{eq valueToVirtualString printName}
   \insert Misc-new.env
   ImAConstruction
   ImAValueNode
   ImAVariableOccurrence
   ImAToken
   Core
   TrueToken
   FalseToken
   GetBuiltinInfo
   CompilerSupport
export
   SA
body
   local
      \insert POTypes
   in
      \insert StaticAnalysis
   end
end
