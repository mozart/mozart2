functor
import System Application
define
   Liste = [1 2 3 4 5]
   
   %% Une fonction qui prend une autre fonction (F) en paramètre
   fun {Map L F}
      case L
      of nil then nil
      [] H|T then {F H} | {Map T F}
      end
   end
   
   Resultat = {Map Liste fun {$ X} X * X end}
in
   {System.showInfo "=== TEST FONCTIONS D'ORDRE SUPERIEUR ==="}
   {System.showInfo "Carres de 1 a 5 :"}
   {System.show Resultat}
   {Application.exit 0}
end