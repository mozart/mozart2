%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
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

functor $ prop once

export
   Get CondGet Put

body

   Get     = {`Builtin` 'GetProperty'     2}
   Put     = {`Builtin` 'PutProperty'     2}
   CondGet = {`Builtin` 'CondGetProperty' 3}

end
