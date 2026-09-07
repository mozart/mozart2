%%%
%%% Authors:
%%%   Arthur Louette (UCLouvain)
%%%
%%% Copyright:
%%%   Arthur Louette, 2026
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

import
   Property

export
   Return

define
   Return =
   base([
      timerDrift(
         proc {$}
            NumThreads = 1000
            DelayTime = 1000 % 1000 millisecondes (1 seconde)
            
            Stream
            SyncPort = {NewPort Stream}
            
            % On relève le temps d'exécution total de la VM (en millisecondes)
            StartT = {Property.get 'time.total'}
            
            % Tâche : Dormir exactement 1 seconde
            proc {Worker}
               {Delay DelayTime}
               {Send SyncPort unit}
            end
            
            % Fonction de synchronisation
            proc {Consume S Cnt}
               if Cnt > 0 then
                  case S of _|T then
                     {Consume T Cnt - 1}
                  end
               end
            end
            
         in
            % 1. On lance 1000 threads qui vont tous s'endormir en parallèle.
            for I in 1..NumThreads do
               thread {Worker} end
            end
            
            % 2. On attend le réveil de TOUT LE MONDE
            {Consume Stream NumThreads}
            
            % 3. On relève l'heure d'arrivée
            local
               EndT = {Property.get 'time.total'}
               Diff = EndT - StartT
            in
               % VERDICT : Puisque les threads dorment en parallèle, l'exécution 
               % totale doit prendre un tout petit peu plus de 1000 millisecondes.
               % On tolère une dérive jusqu'à 4000 ms (4 secondes) à cause de macOS
               % qui déplace les threads sur les E-Cores.
               % Si Diff est supérieur à 4000, le scheduler est cassé sur ARM64.
               true = (Diff =< 4000)
            end
         end
         keys:[timer delay time scheduler 'thread' arm64]
      )
   ])
end