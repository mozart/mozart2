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
      aapcs64Arguments(
         proc {$}
            % 1. On crée une procédure avec 16 arguments (15 entrées, 1 sortie).
            % Cela va littéralement saturer les 8 registres (x0-x7) du processeur M3/M4 
            % et forcer le moteur C++ à déborder sur la Pile (Stack) pour les arguments 9 à 16.
            proc {Sum15 A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 A12 A13 A14 A15 ?Res}
               Res = A1 + A2 + A3 + A4 + A5 + A6 + A7 + A8 + A9 + A10 + A11 + A12 + A13 + A14 + A15
            end
            
            % Un gros Tuple pour vérifier l'allocation interne des tableaux de nœuds C++
            BigTuple = tuple(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)
            
            TotalSum
         in
            % 2. On exécute l'appel massif. 
            % Si la convention AAPCS64 est mal gérée, ça va planter avec un "Segmentation Fault" 
            % ou TotalSum contiendra des "garbage data" (valeurs poubelles).
            {Sum15 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 TotalSum}
            
            % La somme de 1 à 15 fait exactement 120.
            true = (TotalSum == 120)
            
            % 3. On vérifie que la VM Oz accède bien aux adresses "lointaines" de la Pile
            % (au-delà de la frontière des 8 premiers arguments)
            true = (BigTuple.9 == 9)
            true = (BigTuple.15 == 15)
         end
         keys:[ffi arguments aapcs64 registers stack arm64]
      )
   ])
end