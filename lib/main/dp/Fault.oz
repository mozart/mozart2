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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor $ prop once

import
   Fault.{installHW
          deInstallHW
          getEntityCond
          setNetBufferSize
          getNetBufferSize
          tempSimulate}

      from 'x-oz://boot/Fault'

export
   install:           Install
   deinstall:         Deinstall

   getNetBufferSize:  GNBS
   setNetBufferSize:  SNBS

   getEntityCond:     GEC

   startNetPartition: BNP
   stopNetPartition:  ENP

body

   Install   = Fault.installHW
   Deinstall = Fault.deInstallHW

   GEC=Fault.getEntityCond

   GNBS=Fault.getNetBufferSize
   SNBS=Fault.setNetBufferSize

   local
      NP=Fault.tempSimulate
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
