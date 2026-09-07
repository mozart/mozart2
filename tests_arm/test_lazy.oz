functor
import System Application
define
   %% Un generateur infini (qui ferait crasher le Mac s'il n'etait pas lazy !)
   fun lazy {Generate N}
      N | {Generate N+1}
   end
   
   fun {Take N Xs}
      if N == 0 then nil
      else
         case Xs of X|Xr then X | {Take N-1 Xr} end
      end
   end
   
   Stream = {Generate 1}
   Result = {Take 5 Stream}
in
   {System.showInfo "=== TEST EVALUATION PARESSEUSE (LAZY) ==="}
   {System.showInfo "Les 5 premiers elements du flux infini :"}
   {System.show Result}
   {Application.exit 0}
end