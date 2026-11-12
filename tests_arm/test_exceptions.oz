functor
import System Application
define
   {System.showInfo "=== TEST GESTION DES EXCEPTIONS ==="}
   try
      {System.showInfo "Lancement d'une erreur provoquee..."}
      raise myError("Ceci est un crash controle et reussi !") end
   catch E then
      case E of myError(Msg) then
         {System.showInfo "Erreur attrapee avec succes : "#Msg}
      else
         {System.showInfo "Erreur inconnue attrapee."}
      end
   end
   {Application.exit 0}
end