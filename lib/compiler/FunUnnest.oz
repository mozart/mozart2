functor
import
   FD.is
   \insert Misc-new.env
   FlattenSequence
   Core
   Gump.{transformParser transformScanner}
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
