%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1997
%%%   Christian Schulte, 1997
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
%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Denys Duchier, Christian Schulte
%%%  Email: duchier@ps.uni-sb.de, schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

\insert 'Base.oz'

declare
   Dump
in

local
   SmartSave = {`Builtin` smartSave          3}

   proc {ALL Xs P}
      case Xs of X|Xr then {P X} {ALL Xr P}
      [] nil then skip
      else skip
      end
   end
in
   proc {Dump X Name}
      {{`Builtin` 'SystemSetPrint'  1} print(depth: 100 width: 100)}
      {{`Builtin` 'SystemSetErrors' 1} print(depth: 100 width: 100)}

      ExtPATH = Name # '.ozc'
   in
      case {SmartSave X ExtPATH} of nil then skip
      elseof Xs then
         {ALL Xs {`Builtin` 'Wait' 1}}
         {SmartSave X ExtPATH nil}
      end
   end
end

local
   BASE = \insert 'Base.env'
in
   {Dump BASE 'Base'}
end

local
   STD = \insert 'Standard.env'
in
   {Dump STD 'Standard'}
end

local
   Delay = {`Builtin` 'Delay' 1}
in
   {Delay 1000}
end

{{`Builtin` 'shutdown' 1} 0}
