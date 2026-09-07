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

export
   Return

define
   Return =
   base([
      gcStress(
         proc {$}
            NumThreads = 50
            NumIters = 2000
            
            Stream
            SyncPort = {NewPort Stream}

            % Fonction pour générer une grosse liste temporaire
            fun {BuildList M}
               if M == 0 then nil else M | {BuildList M - 1} end
            end

            % Fonction qui alloue massivement de la mémoire éphémère
            proc {AllocateGarbage N}
               if N > 0 then
                  local
                     % Allocation d'une liste de 1000 entiers
                     L = {BuildList 1000}
                     % L'underscore (_) permet de créer l'enregistrement en mémoire 
                     % sans déclencher le warning "variable used only once"
                     _ = giantRecord(a:1 b:2 c:3 d:4 e:5 f:6 g:7 h:8 i:9 j:10 nested:L)
                  in
                     % On ne fait rien avec la liste et l'enregistrement, 
                     % ils deviennent immédiatement des déchets (garbage)
                     {AllocateGarbage N - 1}
                  end
               end
            end

            % Fonction pour synchroniser le thread principal
            proc {Consume S Cnt}
               if Cnt > 0 then
                  case S of _|T then
                     {Consume T Cnt - 1}
                  end
               end
            end

         in
            % Lancement des threads qui vont stresser le GC
            for I in 1..NumThreads do
               thread 
                  {AllocateGarbage NumIters}
                  {Send SyncPort unit} 
               end
            end
            
            % On attend que tous les threads aient terminé leurs allocations
            {Consume Stream NumThreads}
            
            % Si la VM n'a pas fait de SegFault à cause d'une corruption mémoire du GC, le test est validé
            true = true
         end
         keys:[gc stress memory 'thread' arm64]
      )
   ])
end