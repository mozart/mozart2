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
%%% This file creates the Open Programming Functor
%%%

\ifdef HELPSTART
\s +catchall
\endif

\insert 'OS.oz'
\ifndef HELPSTART
\s +catchall
\endif

\ifdef HELPSTART
declare NewOP =
\endif
fun
\ifdef NEWCOMPILER
   instantiate
\endif
   {$ IMPORT}
   \insert 'SP.env'
   = IMPORT.'SP'

   \insert 'Open.oz'
   \insert 'Component.oz'
   \insert 'NewApplication.oz'

in
   \insert 'OP.env'
end
