functor prop once
import
   FD(is)
   Misc(downcasePrintName)
   Core
   CompilerSupport
\ifndef OZM
   Gump(transformParser transformScanner)
   Debug
\endif
   RunTime(procs)
export
   JoinQueries
   MakeExpressionQuery
   UnnestQuery
define
   local
      \insert TupleSyntax
      \insert BindingAnalysis
      \insert UnnestFD
   in
      \insert Unnester
   end
end
