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

%%%
%%% This file creates the Open Programming Functor
%%%

fun {$ IMPORT}
   \insert 'SP.env'
   = IMPORT.'SP'
   \insert 'OP.env'
   = IMPORT.'OP'

   \insert ap/Application.oz
in
   ap('Application':Application)
end
