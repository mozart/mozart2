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
   Open

export
   Return

define
   Return =
   base([
      tcpNetworkStress(
         proc {$}
            Server = {New Open.socket init}
            PortNum
         in
            % 1. On demande à macOS d'allouer un port TCP libre de manière dynamique
            {Server bind(takePort:PortNum)}
            {Server listen}
            
            % 2. Lancement du thread "Serveur" qui attend une connexion
            thread
               local
                  % Accepte la connexion et crée un objet socket pour le client
                  Client = {Server accept($)}
               in
                  % On envoie un payload de 18 caractères sur le réseau
                  {Client write(vs:"Test_ARM64_Network")}
                  {Client close}
               end
            end
            
            % 3. Lancement du "Client" qui traverse la pile TCP/IP locale de macOS
            local
               ClientConnection = {New Open.socket client(host:localhost port:PortNum)}
               Data
            in
               % On lit exactement les 18 octets
               {ClientConnection read(list:Data size:18)}
               {ClientConnection close}
               
               % 4. Le test réussit si aucune donnée n'a été corrompue en mémoire ARM64
               true = (Data == "Test_ARM64_Network")
            end
            
            % On ferme le serveur proprement
            {Server close}
            
            true = true
         end
         keys:[network socket tcp ip arm64]
      )
   ])
end