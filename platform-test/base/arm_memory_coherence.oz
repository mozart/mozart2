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
      armMemoryCoherence(
         proc {$}
            NumThreads = 50
            NumIters = 10000
            Expected = NumThreads * NumIters
            
            % État partagé entre tous les threads
            SharedCell = {NewCell 0}
            
            Stream
            SyncPort = {NewPort Stream}
            
            % Le travailleur : modifie la cellule de manière "atomique"
            proc {Worker N}
               if N > 0 then
                  Old New
               in
                  % L'opération Exchange est la primitive d'accès concurrent en Oz.
                  % Sous le capot (en C++), cela doit déclencher un verrou mémoire strict.
                  % Sur ARM64, si ce verrou est mal implémenté, des données seront perdues.
                  {Exchange SharedCell Old New}
                  New = Old + 1
                  {Worker N - 1}
               end
            end
            
            % Synchronisation finale
            proc {Consume S Cnt}
               if Cnt > 0 then
                  case S of _|T then
                     {Consume T Cnt - 1}
                  end
               end
            end
            
         in
            % 1. On lâche les 50 threads en même temps sur la même cellule
            for I in 1..NumThreads do
               thread 
                  {Worker NumIters}
                  {Send SyncPort unit} 
               end
            end
            
            % 2. On attend la fin du massacre
            {Consume Stream NumThreads}
            
            % 3. Vérification de la cohérence de la mémoire cache L1/L2 d'Apple Silicon
            % Si ça vaut Expected (500 000), le moteur C++ gère parfaitement ARM64 !
            true = (@SharedCell == Expected)
         end
         keys:[memory coherence arm64 'thread' cell]
      )
   ])
end