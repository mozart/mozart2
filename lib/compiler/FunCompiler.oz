functor
import
   \insert SP-new.env
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
      \insert FormatStrings
      \insert Reporter
      \insert ParseOz
      \insert Interface
   in
      \insert CompilerClass
      \insert GenericInterface
      \insert QuietInterface
      \insert Abstractions
   end
end
