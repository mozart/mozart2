functor
import
   System.{property get gcDo printError}
   Error.{formatPos msg formatLine formatExc dispatch format formatGeneric}
   ErrorRegistry.put
   Foreign.staticLoad
   \insert Misc-new.env
   Core
   JoinQueries
   MakeExpressionQuery
   UnnestQuery
   Gump.makeProductionTemplates
   Assemble
export
   CompilerEngine
   GenericInterface
   QuietInterface
   EvalExpression
   VirtualStringToValue
body
   local
      StandardEnv = \insert compiler-Env
      \insert FormatStrings
      \insert Reporter
      \insert ParseOz
      \insert Interface
   in
      \insert CompilerClass
      \insert GenericInterface
      \insert QuietInterface
      \insert Abstractions
      \insert Errors
   end
end
