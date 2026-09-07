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
   Pickle

export
   Return

define
   Return =
   base([
      pickleAlignment(
         proc {$}
            Data Packed Unpacked
         in
            % 1. Construction d'une structure de données très hétérogène.
            % Le but est de forcer le sérialiseur C++ à mélanger des types 
            % de tailles différentes (1, 4, 8 octets) dans le buffer binaire.
            Data = complexRecord(
               % 8 octets (IEEE 754)
               floatValue: 3.141592653589793
               
               % Taille dynamique géante (GMP BigInt)
               bigIntValue: 123456789012345678901234567890
               
               % Chaîne (Liste d'entiers 32 bits)
               stringValue: "Test d'alignement sur ARM64 !"
               
               % Pointeurs imbriqués (Listes et Tuples)
               nestedValues: [1 2.5 3 [4.2 5 'six'] 7]
               
               % Atome avec encodage arbitraire
               atomValue: 'un_atome_très_bizarre_!@#$'
            )
            
            % 2. Sérialisation (Pack) en binaire.
            % Si le C++ est mal aligné en écriture, crash matériel (Bus Error).
            Packed = {Pickle.pack Data}
            
            % 3. Désérialisation (Unpack) depuis le binaire.
            % Si la lecture ne respecte pas l'alignement ARM64, 
            % soit on a un Bus Error, soit les pointeurs sont corrompus.
            Unpacked = {Pickle.unpack Packed}
            
            % 4. Vérification d'intégrité parfaite
            % On s'assure qu'absolument aucun bit n'a été altéré.
            true = (Data == Unpacked)
         end
         keys:[pickle serialization alignment memory arm64]
      )
   ])
end