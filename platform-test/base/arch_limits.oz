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
   % Fonction factorielle pour forcer le basculement vers les grands entiers (GMP)
   fun {Factorial N}
      if N == 0 then 1 else N * {Factorial N - 1} end
   end

   Return =
   base([
      bigIntGMP(
         proc {$}
            Res = {Factorial 100}
         in
            true = (Res > 0)
         end
         keys:[math bigint gmp limits]
      )

      floatZeroAndNaN(
         proc {$}
            % Test de division par zéro sur les flottants.
            try
               local X Y in
                  X = 1.0 / 0.0
                  Y = 0.0 / 0.0
               end
            catch _ then
               % L'exception est levée et attrapée avec succès, pas de crash !
               true = true
            end
         end
         keys:[math float nan zero limits]
      )
   ])
end