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

\ifdef LILO

functor $

export
   %% System
   'System':             System
   'Exit':               Exit
   'Print':              Print
   'Show':               Show
   'PutProperty':        PutProperty
   'GetProperty':        GetProperty
   'CondGetProperty':    CondGetProperty
   %% Foreign
   'Foreign':            Foreign
   %% Debug
   'Debug':              Debug
   %% Error
   'Error':              Error
   %% Finalize
   'Finalize':           Finalize

body
   NewError
in
   \insert 'sp/System.oz'
   \insert 'sp/Foreign.oz'
   \insert 'sp/Debug.oz'
   \insert 'sp/Error.oz'
   \insert 'sp/Finalize.oz'
   Error = {NewError}
end


\else

fun instantiate {$ IMPORT}

   \insert 'sp/System.oz'

   \insert 'sp/Foreign.oz'

   \insert 'sp/Debug.oz'

   \insert 'sp/Error.oz'

   \insert 'sp/Finalize.oz'

   Error   = {NewError}
in

   \insert 'SP.env'

end

\endif
