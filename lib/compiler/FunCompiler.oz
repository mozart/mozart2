functor prop once
import
   Property.{get}
   System   %--**.{gcDo printError}
   Error   %--**.{formatPos msg formatLine formatExc dispatch format formatGeneric}
   ErrorRegistry.put
   Foreign   %--**.staticLoad
   \insert Misc-new.env
   Core
   JoinQueries
   MakeExpressionQuery
   UnnestQuery
   Gump.makeProductionTemplates
   Assemble
export
   CompilerEngine
   ParseOzFile
   ParseOzVirtualString
   GenericInterface
   QuietInterface
   EvalExpression
   VirtualStringToValue
body
   local
      StandardEnv = \insert compiler-Env
      \insert FormatStrings
      \insert Reporter
   in
      \insert CompilerClass
      \insert ParseOz
      \insert GenericInterface
      \insert QuietInterface
      \insert Abstractions
      \insert Errors
   end
end
