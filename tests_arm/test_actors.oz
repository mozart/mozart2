functor
import System Application
define
   Port Stream
   
   %% Création du port et de son flux de lecture
   {NewPort Stream Port}
   
   %% L'Acteur (un thread qui écoute son flux)
   thread
      for Msg in Stream do
         {System.showInfo "L'acteur a recu le message : "#Msg}
      end
   end
   
   {System.showInfo "=== TEST MODELE ACTEUR (PORTS) ==="}
   {Send Port "Bonjour"}
   {Send Port "Apple"}
   {Send Port "Silicon"}
   
   {Delay 500} %% Laisse le temps à l'acteur de traiter
   {Application.exit 0}
end