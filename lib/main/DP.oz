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

\ifdef LILO

functor $

import
   OP.{OS          = 'OS'
       Open        = 'Open'}
   SP.{System      = 'System'}

export
   'Connection': Connection
   'Remote':     Remote

body
   \insert 'dp/Connection.oz'
   \insert 'dp/Remote.oz'

end

\else

fun instantiate {$ IMPORT}
   \insert 'OP.env'
   = IMPORT.'OP'
   \insert 'SP.env'
   = IMPORT.'SP'
   \insert 'AP.env'
   = IMPORT.'AP'

   \insert 'dp/Connection.oz'
   \insert 'dp/Remote.oz'
in
   \insert 'DP.env'
end

\endif
