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

\insert 'Standard.oz'

declare
   Dump
in

local
   BISave      = {`Builtin` save          2}
   PutProperty = {`Builtin` 'PutProperty' 2}

   proc {ALL Xs P}
      case Xs of X|Xr then {P X} {ALL Xr P}
      [] nil then skip
      else skip
      end
   end
in
   proc {Dump X Name}
      {PutProperty print  print(depth: 100 width: 100)}
      {PutProperty errors print(depth: 100 width: 100)}

      ExtPATH = Name #
\ifdef LILO
      '.ozp'
\else
      '.ozc'
\endif
   in
      try
         {BISave X ExtPATH}
      catch dp(save(resources Filename Xs)) then
         {ALL Xs {`Builtin` 'Wait' 1}}
         {BISave X ExtPATH}
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
