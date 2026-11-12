functor
import System Application
define
   fun {ProcessTree T}
      case T
      of leaf(X) then X
      [] node(left:L right:R) then {ProcessTree L} + {ProcessTree R}
      else 0 end
   end
   
   MyTree = node(left:leaf(10) right:node(left:leaf(20) right:leaf(12)))
   Result
in
   {System.showInfo "=== TEST PATTERN MATCHING & ARBRES ==="}
   Result = {ProcessTree MyTree}
   {System.showInfo "Somme des feuilles de l'arbre (attendu: 42) : "#Result}
   {Application.exit 0}
end