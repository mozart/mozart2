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

declare
Base Standard
in

declare
\insert 'Base.env'
= Base
in

declare
\insert 'Standard.env'
= Standard
in

local
   Load = {`Builtin` load 2}
in
   Base     = {Load 'Base.ozc'}
   Standard = {Load 'Standard.ozc'}
end

\ifndef NEWCOMPILER
declare
   Dump
in

local
   SmartSave = {`Builtin` smartSave 3}

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
\endif
