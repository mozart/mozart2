functor
import
   System
   Application
define
   X Y Z
in
   {System.showInfo "=== TEST DE MULTITHREADING ARM64 ==="}
   
   %% Thread 1 : Calcul lent de X
   thread 
      {System.showInfo "Thread 1 : Début du calcul de X (Pause de 1s)..."}
      {Delay 1000}
      X = 15 
      {System.showInfo "Thread 1 : X est lié à 15 !"}
   end
   
   %% Thread 2 : Calcul lent de Y
   thread 
      {System.showInfo "Thread 2 : Début du calcul de Y (Pause de 2s)..."}
      {Delay 2000}
      Y = 27
      {System.showInfo "Thread 2 : Y est lié à 27 !"}
   end

   %% Thread 3 : Le synchroniseur (Dataflow)
   thread
      {System.showInfo "Thread 3 : En attente de X et Y pour calculer Z..."}
      %% L'exécution va se bloquer ici naturellement jusqu'à ce que X et Y existent
      Z = X + Y
      {System.showInfo "Thread 3 : Succès ! Le résultat Z (15+27) est "#Z}
      {Application.exit 0}
   end
end