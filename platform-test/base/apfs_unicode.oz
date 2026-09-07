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
      apfsUnicode(
         proc {$}
            % Un nom de fichier rempli de caractères accentués (UTF-8).
            % APFS va sournoisement modifier l'encodage binaire de ce nom 
            % lors de la création sur le disque (NFC -> NFD).
            FileName = "test_apfs_macOS_éèà_arm64.tmp"
            TestString = "Apple File System Test"
            
            OutFile InFile Data
         in
            % 1. Création et écriture
            % Si la VM gère mal les pointeurs de chaînes vers les API POSIX de macOS, ça plantera ici.
            OutFile = {New Open.file init(name:FileName flags:[write create truncate])}
            {OutFile write(vs:TestString)}
            {OutFile close}
            
            % 2. Lecture
            % On demande à rouvrir le fichier avec notre chaîne d'origine.
            % Si le moteur C++ n'est pas "Unicode-Aware" avec macOS, il dira que le fichier 
            % n'existe pas (File Not Found) car APFS a décomposé les accents sur le disque.
            InFile = {New Open.file init(name:FileName flags:[read])}
            {InFile read(list:Data size:22)} % On lit exactement les 22 caractères
            {InFile close}
            
            % 3. Validation de l'intégrité des données lues
            true = (Data == TestString)
         end
         keys:[apfs unicode filesystem os arm64 macos]
      )
   ])
end