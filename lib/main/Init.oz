%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
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

proc {$}
   Getenv = {`Builtin` 'OS.getEnv' 2}
   SystemRegistry = {{`Builtin` 'SystemRegistry' 1}}
   proc {SET P V} {Dictionary.put SystemRegistry P V} end
   proc {GET P V} {Dictionary.get SystemRegistry P V} end
   \insert Init/Prop
   \insert Init/URL
in
   {SET url  URL}
   {SET load URL.load}
end
