functor prop once
import
   FD.is
   Misc.downcasePrintName
   Core
   CompilerSupport
\ifndef OZM
   Gump.{transformParser transformScanner}
\endif
   RunTime.procs
   Debug
export
   JoinQueries
   MakeExpressionQuery
   UnnestQuery
body
   local
      \insert TupleSyntax
      \insert BindingAnalysis
      \insert UnnestFD
   in
      \insert Unnester
   end
end
