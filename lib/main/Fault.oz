%%%
%%% Authors:
%%%   Per Brand (perbrand@sics.se)
%%%
%%% Copyright:
%%%   Per Brand, 1998
%%%
%%% Last change:
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.ps.uni-sb.de/mozart/
%%%
%%% See the file "LICENSE" or
%%%    http://www.ps.uni-sb.de/mozart/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


declare
local
   Ins={`Builtin` 'installHW' 3}
   Deins={`Builtin` 'deInstallHW' 3}
   GEC={`Builtin` 'getEntityCond' 2}
   GNBS={`Builtin` 'getNetBufferSize' 1}
   SNBS={`Builtin` 'setNetBufferSize' 1}
   NP={`Builtin` 'tempSimulate' 2}
   proc{Install Entity Control P}
      {Ins Entity Control P}
   end
   proc{Deinstall Entity Control P}
      {Deins Entity Control P}
   end
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
in
   Fault=fault(install:Install deinstall:Deinstall
               getNetBufferSize:GNBS setNetBufferSize:SNBS
               getEntityCond:GEC startNetPartition:BNP
               stopNetPartition:ENP)
end
