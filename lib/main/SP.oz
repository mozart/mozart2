%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
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

%%%
%%% This file creates the System Programming Functor
%%%

fun
\ifdef NEWCOMPILER
   instantiate
\endif
   {$ IMPORT}
   \insert SP/Foreign
   \insert SP/System
   \insert SP/Debug
   \insert SP/Error
\ifndef NOFINALIZATION
   \insert SP/Finalize
   Finalize= {NewFinalize}
\endif
   Foreign = {NewForeign}
   Error   = {NewError}
in
   \insert 'SP.env'
end
