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
      massiveThreads(
         proc {$}
            N = 1000000 % 1 million de micro-threads
            Stream
            MyPort = {NewPort Stream}
            
            % Fonction récursive pour consommer les messages du flux
            proc {Consume S Cnt}
               if Cnt > 0 then
                  case S of _|T then
                     {Consume T Cnt - 1}
                  end
               end
            end
         in
            % Création de la tempête de threads
            for I in 1..N do
               thread 
                  {Send MyPort unit} 
               end
            end
            
            % Vérification : on s'assure que le million de messages est bien passé
            {Consume Stream N}
            
            % Si on arrive ici sans crash de la VM, le scheduler a survécu
            true = true
         end
         % C'est ICI qu'il fallait quoter 'thread' car c'est un mot-clé du langage !
         keys:['thread' stress scheduler port arm64]
      )
   ])
end