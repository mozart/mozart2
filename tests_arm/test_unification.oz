functor
import System Application
define
   X Y Z
   Arbre1 = record(a: 10 b: Z c: 30)
   Arbre2 = record(a: X b: 20 c: Y)
in
   {System.showInfo "=== TEST UNIFICATION LOGIQUE ==="}
   %% Le miracle de l'unification : on fusionne les deux arbres
   Arbre1 = Arbre2
   
   {System.showInfo "X vaut : "#X#" (Attendu: 10)"}
   {System.showInfo "Z vaut : "#Z#" (Attendu: 20)"}
   {System.showInfo "Y vaut : "#Y#" (Attendu: 30)"}
   {Application.exit 0}
end