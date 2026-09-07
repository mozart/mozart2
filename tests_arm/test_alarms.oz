functor
import System Application OS
define
   {System.showInfo "=== TEST GESTIONNAIRE D'ALARMES ==="}
   {System.showInfo "Demarrage du chrono..."}
   
   %% Création d'une variable qui sera unifiée dans le futur
   AlarmVar
   thread 
      {Alarm 1000 AlarmVar} 
   end
   
   %% On bloque jusqu'à ce que l'alarme sonne
   {Wait AlarmVar}
   {System.showInfo "DRING ! 1 seconde exacte s'est ecoulee."}
   {Application.exit 0}
end