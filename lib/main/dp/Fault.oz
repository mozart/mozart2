%%%
%%% Authors:
%%%   Per Brand (perbrand@sics.se)
%%%
%%% Copyright:
%%%   Per Brand, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor $ prop once

export
   install:           Install
   deinstall:         Deinstall

   getNetBufferSize:  GNBS
   setNetBufferSize:  SNBS

   getEntityCond:     GEC

   startNetPartition: BNP
   stopNetPartition:  ENP

body

   Install   = {`Builtin` 'installHW' 3}
   Deinstall = {`Builtin` 'deInstallHW' 3}

   GEC={`Builtin` 'getEntityCond' 2}

   GNBS={`Builtin` 'getNetBufferSize' 1}
   SNBS={`Builtin` 'setNetBufferSize' 1}

   local
      NP={`Builtin` 'tempSimulate' 2}
   in
      proc{BNP}
         Cur in
         {NP 0 Cur}
         case Cur of 0 then
            {NP 1 _}
         else
            skip
         end
      end
      proc{ENP}
         Cur in
         {NP 0 Cur}
         case Cur of 1 then
            {NP 1 _}
         else
            skip
         end
      end
   end

end
