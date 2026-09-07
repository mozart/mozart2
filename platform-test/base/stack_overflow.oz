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
      stackOverflow(
         proc {$}
            % Fonction récursive NON terminale.
            % L'addition "1 + ..." oblige la VM à conserver l'état de chaque 
            % appel dans la pile (Stack) de macOS, empêchant l'optimisation 
            % TCO (Tail-Call Optimization).
            fun {BlowStack N}
               1 + {BlowStack N + 1}
            end
         in
            try
               % On lance la boucle infinie de remplissage de pile.
               % Le 'if' sert juste à utiliser le résultat pour que le compilateur
               % ne lève aucun avertissement de type "variable non utilisée".
               if {BlowStack 1} > 0 then skip end
            catch _ then
               % INTERCEPTION RÉUSSIE !
               % Au lieu d'un hard-crash (Segmentation Fault macOS), 
               % la VM Oz a protégé sa mémoire ARM64, stoppé l'hémorragie 
               % et levé proprement une exception Oz system(kernel(stackoverflow ...))
               true = true
            end
         end
         keys:[stack overflow exception kernel arm64]
      )
   ])
end